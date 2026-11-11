import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/data/db/app_database.dart';
import 'package:mynine_desktop/data/repositories/answer_queue.dart';

/// Desktop 1.0.2 created schema v1; 1.0.3 must upgrade it in place without
/// losing queued answers.
void main() {
  test('schema v1 database is upgraded to v2 and keeps its queue', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE answer_queue (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          client_uuid TEXT NOT NULL UNIQUE, attempt_id INTEGER NOT NULL, part_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL, answer_text TEXT NULL, option_ids TEXT NOT NULL DEFAULT '[]',
          changed_at TEXT NOT NULL, tries INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE local_answers (attempt_id INTEGER NOT NULL, question_id INTEGER NOT NULL,
          part_id INTEGER NOT NULL, answer_text TEXT NULL, option_ids TEXT NOT NULL DEFAULT '[]',
          changed_at TEXT NOT NULL, PRIMARY KEY (attempt_id, question_id));
        CREATE TABLE violation_queue (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          client_uuid TEXT NOT NULL UNIQUE, attempt_id INTEGER NOT NULL, type TEXT NOT NULL,
          detail TEXT NULL, occurred_at TEXT NOT NULL);
        CREATE TABLE cached_payloads (key TEXT NOT NULL PRIMARY KEY, json TEXT NOT NULL,
          updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')));
        CREATE TABLE highlights (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, attempt_id INTEGER NOT NULL,
          part_id INTEGER NOT NULL, start_offset INTEGER NOT NULL, end_offset INTEGER NOT NULL,
          kind TEXT NOT NULL DEFAULT 'highlight', note_id TEXT NULL);
        CREATE TABLE candidate_notes (id TEXT NOT NULL PRIMARY KEY, attempt_id INTEGER NOT NULL,
          part_id INTEGER NOT NULL, quote TEXT NOT NULL, note TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')));
        CREATE TABLE exam_sessions (attempt_id INTEGER NOT NULL PRIMARY KEY, token TEXT NOT NULL,
          candidate_name TEXT NOT NULL, candidate_code TEXT NOT NULL, mock_name TEXT NOT NULL DEFAULT '',
          expires_at TEXT NULL, submit_pending INTEGER NOT NULL DEFAULT 0,
          completed INTEGER NOT NULL DEFAULT 0, closed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')));
        INSERT INTO answer_queue (client_uuid, attempt_id, part_id, question_id, answer_text, changed_at)
          VALUES ('old-1', 55, 101, 7001, 'kept', '2026-11-12T09:00:00.000Z');
        INSERT INTO local_answers (attempt_id, question_id, part_id, answer_text, changed_at)
          VALUES (55, 7001, 101, 'kept', '2026-11-12T09:00:00.000Z');
        INSERT INTO exam_sessions (attempt_id, token, candidate_name, candidate_code)
          VALUES (55, 'tok', 'Ali', 'MS1');
        PRAGMA user_version = 1;
      ''');
    }));
    final queue = AnswerQueueRepository(db);
    final pending = await queue.pending(55);
    expect(pending.single.answerText, 'kept');
    expect(pending.single.seq, isNull);
    expect(pending.single.quarantined, isFalse);
    final s = (await db.session(55))!;
    expect(s.authLost, isFalse);
    expect(s.closedAt, isNull);
    await db.markSession(55, authLost: true);
    expect((await db.openSessions()), isEmpty);
    // The per-question counter starts after the migrated row.
    final next = await queue.enqueue(
        attemptId: 55, partId: 101, questionId: 7001, text: 'new', changedAt: DateTime.utc(2026, 11, 12, 9, 1));
    expect(next.seq, 1);
    await db.upsertSession(ExamSessionsCompanion.insert(
        attemptId: const Value(56), token: 't', candidateName: 'B', candidateCode: 'C'));
    expect(db.schemaVersion, 2);
    await db.close();
  });
}
