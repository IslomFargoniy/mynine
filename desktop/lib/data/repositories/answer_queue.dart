import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/mynine_api.dart';
import '../../core/config/app_config.dart';
import '../db/app_database.dart';
import '../models/exam_models.dart';
import '../models/part_payload.dart';

/// Result of one [AnswerQueueRepository.syncOnce] call.
class AnswerSyncResult {
  const AnswerSyncResult({
    required this.sent,
    required this.removed,
    required this.remaining,
    this.rejected = const [],
  });

  final int sent;
  final int removed;
  final int remaining;
  final List<AnswerResult> rejected;
}

/// Offline-first answer queue.
///
/// Every change is written to SQLite first ([LocalAnswers] + [AnswerQueue])
/// and later sent in batches with a client UUID per change. The server is
/// idempotent on `client_uuid` and last-write-wins on `changed_at`, so
/// re-sending after a lost response is always safe.
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
    final item = AnswerItem(
      clientUuid: _uuid.v4(),
      partId: partId,
      questionId: questionId,
      text: text,
      optionIds: optionIds,
      changedAt: changedAt.toUtc(),
    );
    final changedIso = item.changedAt.toIso8601String();
    final optionsJson = jsonEncode(optionIds);
    await _db.transaction(() async {
      await _db.into(_db.localAnswers).insertOnConflictUpdate(
            LocalAnswersCompanion.insert(
              attemptId: attemptId,
              questionId: questionId,
              partId: partId,
              answerText: Value(text),
              optionIds: Value(optionsJson),
              changedAt: changedIso,
            ),
          );
      final inFlight = _inFlight.toList();
      await (_db.delete(_db.answerQueue)
            ..where((t) =>
                t.attemptId.equals(attemptId) &
                t.questionId.equals(questionId) &
                t.clientUuid.isNotIn(inFlight)))
          .go();
      await _db.into(_db.answerQueue).insert(
            AnswerQueueCompanion.insert(
              clientUuid: item.clientUuid,
              attemptId: attemptId,
              partId: partId,
              questionId: questionId,
              answerText: Value(text),
              optionIds: Value(optionsJson),
              changedAt: changedIso,
            ),
          );
    });
    return item;
  }

  Future<int> pendingCount({int? attemptId}) async {
    final count = _db.answerQueue.id.count();
    final query = _db.selectOnly(_db.answerQueue)..addColumns([count]);
    if (attemptId != null) {
      query.where(_db.answerQueue.attemptId.equals(attemptId));
    }
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<List<QueuedAnswer>> pending(int attemptId, {int? limit}) {
    final q = _db.select(_db.answerQueue)
      ..where((t) => t.attemptId.equals(attemptId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (limit != null) q.limit(limit);
    return q.get();
  }

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
  /// (`saved|duplicate|stale|rejected`) are removed; others stay queued.
  /// Throws the API error on failure (items stay queued, `tries` is bumped).
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
      final AnswersResponse response;
      try {
        response = await api.sendAnswers(examToken, items);
      } catch (_) {
        await _bumpTries(uuids);
        rethrow;
      }
      final done = <String>[];
      final rejected = <AnswerResult>[];
      for (final r in response.results) {
        if (AnswerResultStatus.finalStatuses.contains(r.status) &&
            uuids.contains(r.clientUuid)) {
          done.add(r.clientUuid);
          if (r.status == AnswerResultStatus.rejected) rejected.add(r);
        }
      }
      if (done.isNotEmpty) {
        await (_db.delete(_db.answerQueue)
              ..where((t) => t.clientUuid.isIn(done)))
            .go();
      }
      final notAcked = uuids.where((u) => !done.contains(u)).toList();
      if (notAcked.isNotEmpty) await _bumpTries(notAcked);
      return AnswerSyncResult(
        sent: items.length,
        removed: done.length,
        remaining: await pendingCount(attemptId: attemptId),
        rejected: rejected,
      );
    } finally {
      _inFlight.removeAll(uuids);
    }
  }

  /// Sends batches until the queue for [attemptId] is empty or a batch makes
  /// no progress. Returns the number of items still queued.
  Future<int> drain(MynineApi api, String examToken, int attemptId) async {
    while (true) {
      final r = await syncOnce(api, examToken, attemptId);
      if (r.remaining == 0 || r.removed == 0) return r.remaining;
    }
  }

  Future<void> _bumpTries(List<String> uuids) =>
      _db.customUpdate(
        'UPDATE answer_queue SET tries = tries + 1 WHERE client_uuid IN '
        '(${List.filled(uuids.length, '?').join(',')})',
        variables: [for (final u in uuids) Variable.withString(u)],
        updates: {_db.answerQueue},
      );

  static AnswerItem toItem(QueuedAnswer row) => AnswerItem(
        clientUuid: row.clientUuid,
        partId: row.partId,
        questionId: row.questionId,
        text: row.answerText,
        optionIds: decodeIds(row.optionIds),
        changedAt: DateTime.parse(row.changedAt),
      );

  static List<int> decodeIds(String json) {
    try {
      final v = jsonDecode(json);
      if (v is List) return v.map((e) => (e as num).toInt()).toList();
    } catch (_) {}
    return const [];
  }
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
