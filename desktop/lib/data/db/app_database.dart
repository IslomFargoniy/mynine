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

  /// Server confirmed the final submit (or the token is dead).
  BoolColumn get closed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

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
  int get schemaVersion => 1;

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

  /// Sessions that still need background delivery.
  Future<List<ExamSessionRow>> openSessions() =>
      (select(examSessions)..where((t) => t.closed.equals(false))).get();

  Future<void> markSession(
    int attemptId, {
    bool? submitPending,
    bool? completed,
    bool? closed,
  }) =>
      (update(examSessions)..where((t) => t.attemptId.equals(attemptId))).write(
        ExamSessionsCompanion(
          submitPending:
              submitPending == null ? const Value.absent() : Value(submitPending),
          completed: completed == null ? const Value.absent() : Value(completed),
          closed: closed == null ? const Value.absent() : Value(closed),
        ),
      );
}
