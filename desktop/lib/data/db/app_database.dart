import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Answer changes waiting to be sent (`POST /exam/answers`). Never dropped
/// until the server returns a final status for the `client_uuid`.
@DataClassName('QueuedAnswer')
class AnswerQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientUuid => text().unique()();
  IntColumn get attemptId => integer()();
  IntColumn get partId => integer()();
  IntColumn get questionId => integer()();
  TextColumn get answerText => text().nullable()();

  /// JSON array of option ids.
  TextColumn get optionIds => text().withDefault(const Constant('[]'))();

  /// ISO-8601 server time of the change.
  TextColumn get changedAt => text()();
  IntColumn get tries => integer().withDefault(const Constant(0))();

  /// Per-question change counter (API v1.1 `seq`), schema v2.
  IntColumn get seq => integer().nullable()();

  /// The server refused this item with an unexpected error (422) even when
  /// sent alone: kept for audit, never sent again and not counted as pending,
  /// so it cannot block the rest of the queue or the final submit.
  BoolColumn get quarantined => boolean().withDefault(const Constant(false))();
  TextColumn get lastError => text().nullable()();
}

/// Latest local value of every answered question (source of truth for the UI
/// after a restart; survives offline periods).
@DataClassName('LocalAnswer')
class LocalAnswers extends Table {
  IntColumn get attemptId => integer()();
  IntColumn get questionId => integer()();
  IntColumn get partId => integer()();
  TextColumn get answerText => text().nullable()();
  TextColumn get optionIds => text().withDefault(const Constant('[]'))();
  TextColumn get changedAt => text()();

  /// Last `seq` used for this question (schema v2).
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {attemptId, questionId};
}

@DataClassName('QueuedViolation')
class ViolationQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientUuid => text().unique()();
  IntColumn get attemptId => integer()();
  TextColumn get type => text()();
  TextColumn get detail => text().nullable()();
  TextColumn get occurredAt => text()();

  /// Refused by the server (422) even alone: kept, never resent (schema v2).
  BoolColumn get quarantined => boolean().withDefault(const Constant(false))();
}

/// Cached JSON payloads (prefetch, exam state, asset maps).
@DataClassName('CachedPayload')
class CachedPayloads extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Passage highlights, stored as character offsets into the rendered text.
@DataClassName('HighlightRow')
class Highlights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get attemptId => integer()();
  IntColumn get partId => integer()();
  IntColumn get startOffset => integer()();
  IntColumn get endOffset => integer()();

  /// `highlight` or `note`.
  TextColumn get kind => text().withDefault(const Constant('highlight'))();
  TextColumn get noteId => text().nullable()();
}

@DataClassName('NoteRow')
class CandidateNotes extends Table {
  TextColumn get id => text()();
  IntColumn get attemptId => integer()();
  IntColumn get partId => integer()();
  TextColumn get quote => text()();
  TextColumn get note => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per exam login on this PC. Keeps the exam token so queued answers
/// and a pending final submit can still be delivered after the Completed
/// screen or an app restart.
@DataClassName('ExamSessionRow')
class ExamSessions extends Table {
  IntColumn get attemptId => integer()();
  TextColumn get token => text()();
  TextColumn get candidateName => text()();
  TextColumn get candidateCode => text()();
  TextColumn get mockName => text().withDefault(const Constant(''))();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// The candidate finished; `POST /exam/submit` still has to be delivered.
  BoolColumn get submitPending => boolean().withDefault(const Constant(false))();

  /// Exam is over on this PC (Completed screen reached).
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// Server confirmed the final submit (or the attempt is finished).
  BoolColumn get closed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// The server answered 401 (`session_revoked` / `session_expired`) for this
  /// token: background sync skips the session (its queue is kept) until a
  /// new login on this PC replaces the token. Schema v2.
  BoolColumn get authLost => boolean().withDefault(const Constant(false))();

  /// When [closed] was set (cleanup of old exam files). Schema v2.
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {attemptId};
}

@DriftDatabase(
  tables: [
    AnswerQueue,
    LocalAnswers,
    ViolationQueue,
    CachedPayloads,
    Highlights,
    CandidateNotes,
    ExamSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the database file in [directory] on a background isolate.
  factory AppDatabase.open(Directory directory) => AppDatabase(
        NativeDatabase.createInBackground(
          File(p.join(directory.path, 'mynine.sqlite')),
        ),
      );

  /// In-memory database for tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(answerQueue, answerQueue.seq);
            await m.addColumn(answerQueue, answerQueue.quarantined);
            await m.addColumn(answerQueue, answerQueue.lastError);
            await m.addColumn(localAnswers, localAnswers.seq);
            await m.addColumn(violationQueue, violationQueue.quarantined);
            await m.addColumn(examSessions, examSessions.authLost);
            await m.addColumn(examSessions, examSessions.closedAt);
          }
        },
      );

  // ---- Cached payloads -------------------------------------------------------

  Future<void> putCache(String key, String json) =>
      into(cachedPayloads).insertOnConflictUpdate(
        CachedPayloadsCompanion.insert(
          key: key,
          json: json,
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<String?> getCache(String key) async =>
      (await (select(cachedPayloads)..where((t) => t.key.equals(key)))
              .getSingleOrNull())
          ?.json;

  Future<void> deleteCache(String key) =>
      (delete(cachedPayloads)..where((t) => t.key.equals(key))).go();

  // ---- Sessions --------------------------------------------------------------

  Future<void> upsertSession(ExamSessionsCompanion row) =>
      into(examSessions).insertOnConflictUpdate(row);

  Future<ExamSessionRow?> session(int attemptId) =>
      (select(examSessions)..where((t) => t.attemptId.equals(attemptId)))
          .getSingleOrNull();

  /// The unfinished session on this PC, if any (crash/restart resume).
  Future<ExamSessionRow?> activeSession() => (select(examSessions)
        ..where((t) => t.completed.equals(false) & t.closed.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(1))
      .getSingleOrNull();

  /// Sessions that still need background delivery (sessions whose token was
  /// refused are skipped until a new login replaces the token).
  Future<List<ExamSessionRow>> openSessions() => (select(examSessions)
        ..where((t) => t.closed.equals(false) & t.authLost.equals(false)))
      .get();

  Future<List<ExamSessionRow>> allSessions() => (select(examSessions)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<void> markSession(
    int attemptId, {
    bool? submitPending,
    bool? completed,
    bool? closed,
    bool? authLost,
  }) =>
      (update(examSessions)..where((t) => t.attemptId.equals(attemptId))).write(
        ExamSessionsCompanion(
          submitPending:
              submitPending == null ? const Value.absent() : Value(submitPending),
          completed: completed == null ? const Value.absent() : Value(completed),
          closed: closed == null ? const Value.absent() : Value(closed),
          closedAt: closed == true ? Value(DateTime.now().toUtc()) : const Value.absent(),
          authLost: authLost == null ? const Value.absent() : Value(authLost),
        ),
      );

  Future<void> setSessionExpiry(int attemptId, DateTime? expiresAt) =>
      (update(examSessions)..where((t) => t.attemptId.equals(attemptId)))
          .write(ExamSessionsCompanion(expiresAt: Value(expiresAt)));

  /// Removes everything cached for [attemptId] except the answer/violation
  /// queues and the session row (those are kept for audit).
  Future<void> deleteExamCache(int attemptId) =>
      (delete(cachedPayloads)
            ..where((t) =>
                t.key.equals('prefetch:$attemptId') |
                t.key.equals('modules:$attemptId') |
                t.key.equals('flags:$attemptId') |
                t.key.equals('pauses:$attemptId')))
          .go();
}
