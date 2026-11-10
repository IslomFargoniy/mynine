import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

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
    if (attemptId != null) q.where(_db.violationQueue.attemptId.equals(attemptId));
    return (await q.getSingle()).read(count) ?? 0;
  }

  /// Sends up to 200 queued violations. The endpoint is idempotent on
  /// `client_uuid`; a 2xx response acknowledges the whole batch.
  Future<int> syncOnce(MynineApi api, String examToken, int attemptId) async {
    final rows = await (_db.select(_db.violationQueue)
          ..where((t) => t.attemptId.equals(attemptId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(200))
        .get();
    if (rows.isEmpty) return 0;
    final items = rows
        .map((r) => ViolationItem(
              clientUuid: r.clientUuid,
              type: r.type,
              detail: r.detail == null
                  ? null
                  : (jsonDecode(r.detail!) as Map).cast<String, Object?>(),
              occurredAt: DateTime.parse(r.occurredAt),
            ))
        .toList();
    await api.sendViolations(examToken, items);
    await (_db.delete(_db.violationQueue)
          ..where((t) => t.id.isIn(rows.map((r) => r.id))))
        .go();
    return items.length;
  }
}
