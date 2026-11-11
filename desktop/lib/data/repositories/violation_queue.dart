import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../db/app_database.dart';
import '../models/exam_models.dart';

/// Lockdown violations, queued locally and sent in batches
/// (`POST /exam/violations`).
class ViolationQueueRepository {
  ViolationQueueRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> enqueue({
    required int attemptId,
    required String type,
    Map<String, Object?>? detail,
    required DateTime occurredAt,
  }) =>
      _db.into(_db.violationQueue).insert(
            ViolationQueueCompanion.insert(
              clientUuid: _uuid.v4(),
              attemptId: attemptId,
              type: type,
              detail: Value(detail == null ? null : jsonEncode(detail)),
              occurredAt: occurredAt.toUtc().toIso8601String(),
            ),
          );

  Future<int> pendingCount({int? attemptId}) async {
    final count = _db.violationQueue.id.count();
    final q = _db.selectOnly(_db.violationQueue)..addColumns([count]);
    Expression<bool> where = _db.violationQueue.quarantined.equals(false);
    if (attemptId != null) where = where & _db.violationQueue.attemptId.equals(attemptId);
    q.where(where);
    return (await q.getSingle()).read(count) ?? 0;
  }

  /// Sends up to 200 queued violations. The endpoint is idempotent on
  /// `client_uuid`; a 2xx response acknowledges the whole batch. A 422 is
  /// bisected; a violation refused alone is quarantined (kept, never resent).
  /// Returns the number of items acknowledged or quarantined.
  Future<int> syncOnce(MynineApi api, String examToken, int attemptId) async {
    final rows = await (_db.select(_db.violationQueue)
          ..where((t) => t.attemptId.equals(attemptId) & t.quarantined.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(200))
        .get();
    if (rows.isEmpty) return 0;
    return _send(api, examToken, rows);
  }

  Future<int> _send(MynineApi api, String examToken, List<QueuedViolation> rows) async {
    try {
      await api.sendViolations(examToken, rows.map(_toItem).toList());
    } on ApiException catch (e) {
      if (e.statusCode != 422 && e.statusCode != 413) rethrow;
      if (rows.length == 1) {
        debugPrint('Violation ${rows.single.clientUuid} quarantined: $e');
        await (_db.update(_db.violationQueue)..where((t) => t.id.equals(rows.single.id)))
            .write(const ViolationQueueCompanion(quarantined: Value(true)));
        return 1;
      }
      final mid = rows.length ~/ 2;
      return await _send(api, examToken, rows.sublist(0, mid)) +
          await _send(api, examToken, rows.sublist(mid));
    }
    await (_db.delete(_db.violationQueue)
          ..where((t) => t.id.isIn(rows.map((r) => r.id))))
        .go();
    return rows.length;
  }

  static ViolationItem _toItem(QueuedViolation r) {
    Map<String, Object?>? detail;
    try {
      final d = r.detail == null ? null : jsonDecode(r.detail!);
      if (d is Map) detail = d.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return ViolationItem(
      clientUuid: r.clientUuid,
      type: r.type,
      detail: detail,
      occurredAt: DateTime.tryParse(r.occurredAt) ?? DateTime.now().toUtc(),
    );
  }
}
