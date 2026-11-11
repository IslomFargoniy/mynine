import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../../core/config/app_config.dart';
import '../db/app_database.dart';
import '../models/exam_models.dart';
import '../models/part_payload.dart';

/// Max characters of a text / essay answer (also enforced in the inputs).
const int kMaxAnswerChars = 20000;

/// Result of one [AnswerQueueRepository.syncOnce] call.
class AnswerSyncResult {
  const AnswerSyncResult({
    required this.sent,
    required this.removed,
    required this.remaining,
    this.rejected = const [],
    this.deferred = 0,
    this.quarantined = 0,
  });

  final int sent;
  final int removed;
  final int remaining;
  final List<AnswerResult> rejected;

  /// Items the server deferred (`deferred` / `paused`): still queued.
  final int deferred;

  /// Items set aside after the server refused them alone with a 422.
  final int quarantined;
}

/// Offline-first answer queue.
///
/// Every change is written to SQLite first ([LocalAnswers] + [AnswerQueue])
/// and later sent in batches with a client UUID per change. The server is
/// idempotent on `client_uuid` and last-write-wins on `seq` / `changed_at`,
/// so re-sending after a lost response is always safe.
///
/// * `changed_at` is monotonic per question (`max(previous + 1 ms, now)`), so
///   a local clock jump can never make a newer change look older.
/// * `seq` is a per-question counter persisted in [LocalAnswers] (survives
///   restarts).
/// * `deferred` results (attempt paused) stay queued; every other final
///   status removes the item. Unknown statuses stay queued.
/// * A 422 for a whole batch is bisected so one bad item cannot block the
///   others; an item refused alone is quarantined (kept, never resent).
class AnswerQueueRepository {
  AnswerQueueRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  /// UUIDs of the batch currently being sent (must not be coalesced away).
  final Set<String> _inFlight = {};

  /// Records a change locally and queues it for delivery.
  ///
  /// Unsent older changes of the same question that are not in flight are
  /// replaced (they would be `stale` on the server anyway).
  Future<AnswerItem> enqueue({
    required int attemptId,
    required int partId,
    required int questionId,
    String? text,
    List<int> optionIds = const [],
    required DateTime changedAt,
  }) async {
    final clipped =
        text != null && text.length > kMaxAnswerChars ? text.substring(0, kMaxAnswerChars) : text;
    final optionsJson = jsonEncode(optionIds);
    late AnswerItem item;
    await _db.transaction(() async {
      final prev = await (_db.select(_db.localAnswers)
            ..where((t) => t.attemptId.equals(attemptId) & t.questionId.equals(questionId)))
          .getSingleOrNull();
      // Millisecond precision (API v1.1 format), monotonic per question.
      var at = DateTime.fromMillisecondsSinceEpoch(changedAt.millisecondsSinceEpoch, isUtc: true);
      final prevAt = prev == null ? null : DateTime.tryParse(prev.changedAt)?.toUtc();
      if (prevAt != null) {
        final floor = prevAt.add(const Duration(milliseconds: 1));
        if (at.isBefore(floor)) at = floor;
      }
      final seq = (prev?.seq ?? 0) + 1;
      item = AnswerItem(
        clientUuid: _uuid.v4(),
        partId: partId,
        questionId: questionId,
        text: clipped,
        optionIds: optionIds,
        changedAt: at,
        seq: seq,
      );
      final changedIso = at.toIso8601String();
      await _db.into(_db.localAnswers).insertOnConflictUpdate(
            LocalAnswersCompanion.insert(
              attemptId: attemptId,
              questionId: questionId,
              partId: partId,
              answerText: Value(clipped),
              optionIds: Value(optionsJson),
              changedAt: changedIso,
              seq: Value(seq),
            ),
          );
      final inFlight = _inFlight.toList();
      await (_db.delete(_db.answerQueue)
            ..where((t) =>
                t.attemptId.equals(attemptId) &
                t.questionId.equals(questionId) &
                t.quarantined.equals(false) &
                t.clientUuid.isNotIn(inFlight)))
          .go();
      await _db.into(_db.answerQueue).insert(
            AnswerQueueCompanion.insert(
              clientUuid: item.clientUuid,
              attemptId: attemptId,
              partId: partId,
              questionId: questionId,
              answerText: Value(clipped),
              optionIds: Value(optionsJson),
              changedAt: changedIso,
              seq: Value(seq),
            ),
          );
    });
    return item;
  }

  /// Items still to be delivered (quarantined items are not counted).
  Future<int> pendingCount({int? attemptId}) async {
    final count = _db.answerQueue.id.count();
    final query = _db.selectOnly(_db.answerQueue)..addColumns([count]);
    Expression<bool> where = _db.answerQueue.quarantined.equals(false);
    if (attemptId != null) where = where & _db.answerQueue.attemptId.equals(attemptId);
    query.where(where);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<List<QueuedAnswer>> pending(int attemptId, {int? limit}) {
    final q = _db.select(_db.answerQueue)
      ..where((t) => t.attemptId.equals(attemptId) & t.quarantined.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (limit != null) q.limit(limit);
    return q.get();
  }

  Future<List<QueuedAnswer>> quarantinedItems(int attemptId) =>
      (_db.select(_db.answerQueue)
            ..where((t) => t.attemptId.equals(attemptId) & t.quarantined.equals(true)))
          .get();

  /// Local answers of an attempt keyed by question id.
  Future<Map<int, SavedAnswer>> localAnswers(int attemptId) async {
    final rows = await (_db.select(_db.localAnswers)
          ..where((t) => t.attemptId.equals(attemptId)))
        .get();
    return {
      for (final r in rows)
        r.questionId: SavedAnswer(
          text: r.answerText,
          optionIds: decodeIds(r.optionIds),
        ),
    };
  }

  /// Sends one batch (max 200) for [attemptId]. Items with a final status
  /// (`saved|duplicate|stale|rejected`) are removed; `deferred` and unknown
  /// statuses stay queued. Throws the API error on failure (items stay
  /// queued, `tries` is bumped) — except a 422, which is bisected.
  Future<AnswerSyncResult> syncOnce(
    MynineApi api,
    String examToken,
    int attemptId,
  ) async {
    final batch =
        await pending(attemptId, limit: AppConfig.answerBatchSize);
    if (batch.isEmpty) {
      return const AnswerSyncResult(sent: 0, removed: 0, remaining: 0);
    }
    final items = batch.map(toItem).toList();
    final uuids = items.map((i) => i.clientUuid).toList();
    _inFlight.addAll(uuids);
    try {
      final outcome = _BatchOutcome();
      try {
        await _send(api, examToken, items, outcome);
      } catch (_) {
        // Whatever was acknowledged before the failure is still final.
        await _apply(outcome, uuids);
        await _bumpTries(uuids.where((u) => !outcome.done.contains(u)).toList());
        rethrow;
      }
      await _apply(outcome, uuids);
      final notAcked = uuids
          .where((u) => !outcome.done.contains(u) && !outcome.quarantined.containsKey(u))
          .toList();
      if (notAcked.isNotEmpty) await _bumpTries(notAcked);
      return AnswerSyncResult(
        sent: items.length,
        removed: outcome.done.length,
        remaining: await pendingCount(attemptId: attemptId),
        rejected: outcome.rejected,
        deferred: outcome.deferred,
        quarantined: outcome.quarantined.length,
      );
    } finally {
      _inFlight.removeAll(uuids);
    }
  }

  /// Sends [items]; on a 422 (or 413) splits the batch in halves until the
  /// offending item is alone, which is then quarantined.
  Future<void> _send(
    MynineApi api,
    String examToken,
    List<AnswerItem> items,
    _BatchOutcome outcome,
  ) async {
    final AnswersResponse response;
    try {
      response = await api.sendAnswers(examToken, items);
    } on ApiException catch (e) {
      final splittable = e.statusCode == 422 || e.statusCode == 413;
      if (!splittable) rethrow;
      if (items.length == 1) {
        outcome.quarantined[items.single.clientUuid] =
            '${e.statusCode} ${e.code.wire}: ${e.message ?? ''}'.trim();
        return;
      }
      final mid = items.length ~/ 2;
      await _send(api, examToken, items.sublist(0, mid), outcome);
      await _send(api, examToken, items.sublist(mid), outcome);
      return;
    }
    final sent = {for (final i in items) i.clientUuid};
    for (final r in response.results) {
      if (!sent.contains(r.clientUuid)) continue;
      if (AnswerResultStatus.finalStatuses.contains(r.status)) {
        outcome.done.add(r.clientUuid);
        if (r.status == AnswerResultStatus.rejected) outcome.rejected.add(r);
      } else if (r.status == AnswerResultStatus.deferred) {
        outcome.deferred++;
      }
    }
  }

  Future<void> _apply(_BatchOutcome outcome, List<String> uuids) async {
    if (outcome.done.isNotEmpty) {
      await (_db.delete(_db.answerQueue)
            ..where((t) => t.clientUuid.isIn(outcome.done)))
          .go();
    }
    for (final e in outcome.quarantined.entries) {
      debugPrint('Answer ${e.key} quarantined: ${e.value}');
      await (_db.update(_db.answerQueue)..where((t) => t.clientUuid.equals(e.key))).write(
        AnswerQueueCompanion(quarantined: const Value(true), lastError: Value(e.value)),
      );
    }
  }

  /// Sends batches until the queue for [attemptId] is empty or a batch makes
  /// no progress. Returns the number of items still queued.
  Future<int> drain(MynineApi api, String examToken, int attemptId) async =>
      (await drainDetailed(api, examToken, attemptId)).remaining;

  /// Like [drain] but also reports whether the server deferred items.
  Future<AnswerSyncResult> drainDetailed(MynineApi api, String examToken, int attemptId) async {
    var removed = 0;
    var deferred = 0;
    var quarantined = 0;
    final rejected = <AnswerResult>[];
    while (true) {
      final r = await syncOnce(api, examToken, attemptId);
      removed += r.removed;
      deferred += r.deferred;
      quarantined += r.quarantined;
      rejected.addAll(r.rejected);
      if (r.remaining == 0 || (r.removed == 0 && r.quarantined == 0)) {
        return AnswerSyncResult(
          sent: 0,
          removed: removed,
          remaining: r.remaining,
          rejected: rejected,
          deferred: deferred,
          quarantined: quarantined,
        );
      }
    }
  }

  Future<void> _bumpTries(List<String> uuids) async {
    if (uuids.isEmpty) return;
    await _db.customUpdate(
      'UPDATE answer_queue SET tries = tries + 1 WHERE client_uuid IN '
      '(${List.filled(uuids.length, '?').join(',')})',
      variables: [for (final u in uuids) Variable.withString(u)],
      updates: {_db.answerQueue},
    );
  }

  static AnswerItem toItem(QueuedAnswer row) => AnswerItem(
        clientUuid: row.clientUuid,
        partId: row.partId,
        questionId: row.questionId,
        text: row.answerText,
        optionIds: decodeIds(row.optionIds),
        changedAt: DateTime.parse(row.changedAt),
        seq: row.seq,
      );

  static List<int> decodeIds(String json) {
    try {
      final v = jsonDecode(json);
      if (v is List) return v.map((e) => (e as num).toInt()).toList();
    } catch (_) {}
    return const [];
  }
}

class _BatchOutcome {
  final List<String> done = [];
  final List<AnswerResult> rejected = [];
  final Map<String, String> quarantined = {};
  int deferred = 0;
}

/// Exponential backoff for retries: 1 s, 2 s, 4 s … capped at [max].
class Backoff {
  Backoff({this.base = const Duration(seconds: 1), this.max = const Duration(seconds: 30)});

  final Duration base;
  final Duration max;
  int _failures = 0;

  int get failures => _failures;

  Duration get nextDelay {
    if (_failures == 0) return Duration.zero;
    final shift = _failures - 1 > 16 ? 16 : _failures - 1;
    final ms = base.inMilliseconds * (1 << shift);
    return ms > max.inMilliseconds ? max : Duration(milliseconds: ms);
  }

  void fail() => _failures++;
  void reset() => _failures = 0;
}
