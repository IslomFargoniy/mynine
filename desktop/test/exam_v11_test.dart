// API v1.1 client behaviour: deferred answers while paused, seq / monotonic
// changed_at, quarantine of a bad item, revoked sessions, honest "submitted",
// final submit after a crash, pause tracking for the Listening audio.
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/api/api_exception.dart';
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/data/db/app_database.dart';
import 'package:mynine_desktop/data/models/exam_models.dart';
import 'package:mynine_desktop/data/repositories/answer_queue.dart';
import 'package:mynine_desktop/data/repositories/sync_service.dart';
import 'package:mynine_desktop/data/repositories/violation_queue.dart';
import 'package:mynine_desktop/features/exam/exam_controller.dart';
import 'package:mynine_desktop/features/exam/listening_audio.dart';

import 'support/harness.dart';

const _attempt = FakeMynineApi.attemptId;

Future<Harness> _inListening() async {
  final h = await Harness.create();
  await h.exam.login('DEMO1');
  h.exam.acceptRules();
  h.exam.confirmSoundCheck();
  await waitFor(() => h.exam.stage == ExamStage.exam);
  return h;
}

void main() {
  group('answer queue (v1.1)', () {
    late AppDatabase db;
    late AnswerQueueRepository queue;
    late FakeMynineApi api;
    late String token;
    final t0 = DateTime.utc(2026, 11, 12, 9);

    setUp(() async {
      db = AppDatabase.memory();
      queue = AnswerQueueRepository(db);
      api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero);
      token = (await api.login('DEMO1')).token;
      await api.startModule(token, 1);
    });
    tearDown(() => db.close());

    test('deferred (paused) items stay queued and are sent after the resume', () async {
      await queue.enqueue(attemptId: _attempt, partId: 101, questionId: 7001, text: 'carbon', changedAt: t0);
      api.paused = true;
      final r = await queue.syncOnce(api, token, _attempt);
      expect(r.deferred, 1);
      expect(r.removed, 0);
      expect(await queue.pendingCount(attemptId: _attempt), 1);
      expect(api.savedAnswers.containsKey(7001), isFalse);
      // drain stops (no progress) instead of looping while paused.
      expect(await queue.drain(api, token, _attempt), 1);

      api.paused = false;
      expect(await queue.drain(api, token, _attempt), 0);
      expect(api.savedAnswers[7001]!.text, 'carbon');
    });

    test('seq grows per question and survives a restart; changed_at never goes back', () async {
      final a = await queue.enqueue(attemptId: _attempt, partId: 101, questionId: 7001, text: 'a', changedAt: t0);
      // The local clock jumped back one hour (NTP / manual change).
      final b = await queue.enqueue(
          attemptId: _attempt, partId: 101, questionId: 7001, text: 'b', changedAt: t0.subtract(const Duration(hours: 1)));
      expect(a.seq, 1);
      expect(b.seq, 2);
      expect(b.changedAt.isAfter(a.changedAt), isTrue);
      expect(b.changedAt, a.changedAt.add(const Duration(milliseconds: 1)));

      // Another question has its own counter.
      final other = await queue.enqueue(attemptId: _attempt, partId: 101, questionId: 7002, text: 'x', changedAt: t0);
      expect(other.seq, 1);

      // "Restart": a new repository on the same database continues the counter.
      final again = await AnswerQueueRepository(db)
          .enqueue(attemptId: _attempt, partId: 101, questionId: 7001, text: 'c', changedAt: t0);
      expect(again.seq, 3);
      final pending = await queue.pending(_attempt);
      expect(AnswerQueueRepository.toItem(pending.firstWhere((q) => q.questionId == 7001)).seq, 3);

      await queue.drain(api, token, _attempt);
      expect(api.savedAnswers[7001]!.text, 'c');
      expect(api.savedAnswers[7001]!.seq, 3);
    });

    test('seq is sent on the wire (omitted when null)', () {
      final item = AnswerItem(clientUuid: 'u', partId: 1, questionId: 2, changedAt: t0, seq: 4);
      expect(item.toJson()['seq'], 4);
      expect(AnswerItem(clientUuid: 'u', partId: 1, questionId: 2, changedAt: t0).toJson().containsKey('seq'), isFalse);
    });

    test('a 422 batch is bisected: the bad item is quarantined, the rest is delivered', () async {
      for (var i = 0; i < 7; i++) {
        await queue.enqueue(
            attemptId: _attempt, partId: 101, questionId: 7001 + i, text: i == 4 ? 'X' * 50 : 'ok$i', changedAt: t0);
      }
      api.rejectBatchTextLongerThan = 20;
      final r = await queue.syncOnce(api, token, _attempt);
      expect(r.quarantined, 1);
      expect(r.removed, 6);
      expect(r.remaining, 0);
      expect(await queue.pendingCount(), 0);
      final q = await queue.quarantinedItems(_attempt);
      expect(q.single.questionId, 7005);
      expect(q.single.lastError, contains('422'));
      expect(api.savedAnswers.keys, containsAll([7001, 7002, 7003, 7004, 7006, 7007]));
      // A newer change of the same question is queued normally again.
      await queue.enqueue(attemptId: _attempt, partId: 101, questionId: 7005, text: 'fixed', changedAt: t0);
      expect(await queue.drain(api, token, _attempt), 0);
      expect(api.savedAnswers[7005]!.text, 'fixed');
      expect((await queue.quarantinedItems(_attempt)).length, 1); // kept for audit
    });

    test('answers are clipped to 20000 characters', () async {
      final item = await queue.enqueue(
          attemptId: _attempt, partId: 101, questionId: 7001, text: 'y' * 25000, changedAt: t0);
      expect(item.text!.length, kMaxAnswerChars);
      expect((await queue.localAnswers(_attempt))[7001]!.text!.length, kMaxAnswerChars);
    });
  });

  group('sync service (v1.1)', () {
    test('a refused violation never blocks the final submit', () async {
      final h = await Harness.create();
      await h.exam.login('DEMO1');
      final s = (await h.db.activeSession())!;
      final violations = ViolationQueueRepository(h.db);
      await violations.enqueue(attemptId: _attempt, type: 'weird_type', occurredAt: DateTime.now());
      await violations.enqueue(attemptId: _attempt, type: ViolationType.focusLost, occurredAt: DateTime.now());
      h.api.rejectViolationType = 'weird_type';
      await h.db.markSession(_attempt, completed: true, submitPending: true);
      await h.sync.syncSession((await h.db.session(_attempt))!.copyWith(submitPending: true, completed: true));
      expect(h.api.examSubmitted, isTrue);
      expect(h.api.receivedViolations.map((v) => v.type), [ViolationType.focusLost]);
      expect(await violations.pendingCount(), 0); // the bad one is quarantined
      expect(s.attemptId, _attempt);
      await h.dispose();
    });

    test('violations failing for another reason do not block the submit either', () async {
      final h = await Harness.create();
      await h.exam.login('DEMO1');
      final violations = ViolationQueueRepository(h.db);
      await violations.enqueue(attemptId: _attempt, type: ViolationType.focusLost, occurredAt: DateTime.now());
      final api = _ViolationsDownApi(h.api);
      final sync = SyncService(
        api: api,
        db: h.db,
        answers: AnswerQueueRepository(h.db),
        violations: violations,
        connection: ConnectionStatus(),
      );
      final row = (await h.db.session(_attempt))!.copyWith(submitPending: true, completed: true);
      await sync.syncSession(row);
      expect(h.api.examSubmitted, isTrue);
      expect(await violations.pendingCount(), 1); // retried later, still queued
      sync.dispose();
      await h.dispose();
    });
  });

  group('exam controller (v1.1)', () {
    test('pause: deferred answers lock the inputs at once and are delivered after the resume', () async {
      final h = await _inListening();
      final exam = h.exam;
      h.api.paused = true; // server paused; the heartbeat has not told us yet
      exam.setAnswer(partId: 101, questionId: 7001, text: 'Smith');
      await waitFor(() => exam.paused);
      expect(exam.inputsLocked, isTrue);
      expect(await AnswerQueueRepository(h.db).pendingCount(), 1);
      expect(h.api.savedAnswers.containsKey(7001), isFalse);

      h.api.paused = false;
      exam.applyHeartbeat(const ExamHeartbeatResponse(paused: false));
      expect(exam.paused, isFalse);
      await waitFor(() => h.api.savedAnswers.containsKey(7001));
      expect(h.api.savedAnswers[7001]!.text, 'Smith');
      await h.dispose();
    });

    test('pauses are tracked for the Listening audio position (extra time ignored)', () async {
      var now = DateTime.utc(2026, 11, 12, 9);
      final h = await Harness.create(now: () => now);
      final exam = h.exam;
      await exam.login('DEMO1');
      exam.acceptRules();
      exam.confirmSoundCheck();
      await waitFor(() => exam.stage == ExamStage.exam);
      final m = exam.currentModule!;
      expect(m.startedAt, now);

      now = now.add(const Duration(minutes: 5));
      exam.applyHeartbeat(const ExamHeartbeatResponse(paused: true));
      now = now.add(const Duration(minutes: 3));
      expect(exam.pausedSince(m.startedAt!), const Duration(minutes: 3));
      // While paused the position stands still.
      expect(listeningPosition(m, h.clock, pausedSince: exam.pausedSince), const Duration(minutes: 5));

      // Resume + 10 minutes extra time: finished_at moves, the audio does not.
      final moved = m.finishedAt!.add(const Duration(minutes: 13));
      exam.applyHeartbeat(ExamHeartbeatResponse(
        paused: false,
        modules: [ModuleTimer(typeId: 1, status: ModuleStatus.inProgress, finishedAt: moved)],
      ));
      now = now.add(const Duration(minutes: 1));
      final module = exam.currentModule!;
      expect(listeningPosition(module, h.clock, pausedSince: exam.pausedSince), const Duration(minutes: 6));
      // The old finished_at-based formula (duration − remaining) would say
      // −4 min (clamped to 0): 10 minutes behind the recording.
      expect(listeningPosition(module.copyWith(startedAt: null), h.clock), Duration.zero);
      await h.dispose();
    });

    test('revoked token mid-exam locks the UI, keeps the answers, and a re-login restores them', () async {
      final h = await _inListening();
      final exam = h.exam;
      h.api.offline = true;
      exam.setAnswer(partId: 101, questionId: 7003, text: 'Bristol');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      h.api.offline = false;
      h.api.revokeToken('session_revoked');
      exam.applyHeartbeat(const ExamHeartbeatResponse()); // no-op
      // The next sync pass meets the 401.
      h.sync.kick();
      await waitFor(() => exam.stage == ExamStage.blocked);
      expect(exam.blockReason, BlockReason.sessionLost);
      expect(exam.blockMessage, contains('call the invigilator'));
      expect(exam.examActive, isTrue);
      final s = (await h.db.session(_attempt))!;
      expect(s.authLost, isTrue);
      expect(s.closed, isFalse);
      expect(await AnswerQueueRepository(h.db).pendingCount(), 1);
      expect(h.api.savedAnswers.containsKey(7003), isFalse);

      // Still on another PC → 409 with a clear message, still locked.
      h.api.activeElsewhere = true;
      await exam.login('DEMO1');
      expect(exam.stage, ExamStage.blocked);
      expect(exam.error, contains('active on another PC'));

      // Admin released the session: the same code continues the attempt here.
      h.api.activeElsewhere = false;
      await exam.login('DEMO1');
      expect(exam.stage, ExamStage.exam);
      expect(exam.answerFor(7003).text, 'Bristol');
      await waitFor(() => h.api.savedAnswers.containsKey(7003));
      expect((await h.db.session(_attempt))!.authLost, isFalse);
      await h.dispose();
    });

    test('a lost session signs in again in the background and the exam goes on', () async {
      final h = await _inListening();
      final exam = h.exam..recoverLostSessions = true;
      h.api.offline = true;
      exam.setAnswer(partId: 101, questionId: 7003, text: 'Bristol');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      h.api.offline = false;
      h.api.revokeToken('session_expired');
      h.sync.kick();
      await waitFor(() => h.api.calls.where((c) => c == 'login').length >= 2);
      await waitFor(() => exam.stage == ExamStage.exam);
      expect(exam.answerFor(7003).text, 'Bristol');
      await waitFor(() => h.api.savedAnswers.containsKey(7003));
      await h.dispose();
    });

    test('a lost session that cannot be restored goes back to the code screen and keeps the answers', () async {
      final h = await _inListening();
      final exam = h.exam..recoverLostSessions = true;
      h.api.offline = true;
      exam.setAnswer(partId: 101, questionId: 7003, text: 'Bristol');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      h.api.offline = false;
      h.api.activeElsewhere = true;
      h.api.revokeToken('session_revoked');
      h.sync.kick();
      await waitFor(() => exam.stage == ExamStage.idle);
      expect(exam.error, isNull);
      expect(await AnswerQueueRepository(h.db).pendingCount(), 1);

      // The invigilator released it: the candidate signs in on this PC again and the answer goes out.
      h.api.activeElsewhere = false;
      await exam.login('DEMO1');
      exam.acceptRules();
      exam.confirmSoundCheck();
      await waitFor(() => h.api.savedAnswers.containsKey(7003));
      await h.dispose();
    });

    test('expired token on a module submit locks the exam (no Completed screen)', () async {
      final h = await _inListening();
      h.api.revokeToken('session_expired');
      await h.exam.confirmFinishModule();
      expect(h.exam.stage, ExamStage.blocked);
      expect(h.exam.submitConfirmed, isFalse);
      await h.dispose();
    });

    test('"Completed" says submitted only when /exam/submit succeeded', () async {
      final h = await _inListening();
      final exam = h.exam;
      await exam.confirmFinishModule();
      await waitFor(() => exam.currentModule?.isReading ?? false);
      // The next module waits for Start (rules screen), then its timer runs.
      expect(exam.stage, ExamStage.rules);
      exam.acceptRules();
      await waitFor(() => exam.stage == ExamStage.exam);
      await exam.confirmFinishModule();
      await waitFor(() => exam.currentModule?.isWriting ?? false);
      // The next module waits for Start (rules screen), then its timer runs.
      expect(exam.stage, ExamStage.rules);
      exam.acceptRules();
      await waitFor(() => exam.stage == ExamStage.exam);
      exam.setAnswer(partId: 301, questionId: 9001, text: 'Essay');
      await exam.flushPending();
      await waitFor(() => h.api.savedAnswers.containsKey(9001));
      // Module submit works, then the connection drops before the final submit.
      final api = h.api;
      api.failSubmitExam = true;
      exam.submitGrace = Duration.zero; // offline grace over at once
      await exam.confirmFinishModule();
      await waitFor(() => exam.stage == ExamStage.completed);
      expect(exam.submitConfirmed, isFalse);
      final s = (await h.db.session(_attempt))!;
      expect(s.submitPending, isTrue);
      expect(s.closed, isFalse);

      // Back online: the background sync submits and the screen flips.
      api.failSubmitExam = false;
      h.sync.kick();
      await waitFor(() => exam.submitConfirmed);
      expect(api.examSubmitted, isTrue);
      expect((await h.db.session(_attempt))!.closed, isTrue);
      await h.dispose();
    });

    test('restart in Listening: the audio resumes where it stopped and the module ends that much later', () async {
      var now = DateTime.utc(2026, 11, 12, 9);
      final h = await Harness.create(now: () => now);
      await h.exam.login('DEMO1');
      h.exam.acceptRules();
      h.exam.confirmSoundCheck();
      await waitFor(() => h.exam.stage == ExamStage.exam);
      final start = h.exam.currentModule!;
      final end = start.finishedAt!;

      // 20 s heard, then the app dies; it is open again a minute later.
      now = now.add(const Duration(seconds: 20));
      h.exam.saveAudioPosition(start.typeId, const Duration(seconds: 20));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      h.exam.dispose();
      now = now.add(const Duration(seconds: 60));
      final again = h.restartController();
      expect(await again.resumeIfNeeded(), isTrue);
      await waitFor(() => again.stage == ExamStage.exam);

      final m = again.currentModule!;
      expect(m.audioLagSeconds, 60);
      expect(listeningPosition(m, h.clock, pausedSince: again.pausedSince), const Duration(seconds: 20));
      expect(m.finishedAt, end.add(const Duration(seconds: 60)));
      expect(h.api.audioLag[start.typeId], 60);

      // The server's end moved too: a heartbeat does not undo it.
      final hb = await h.api.examHeartbeat((await h.db.session(_attempt))!.token, queuedAnswers: 0, queuedViolations: 0);
      again.applyHeartbeat(hb);
      expect(again.currentModule!.finishedAt, end.add(const Duration(seconds: 60)));

      // A restart without a saved position on this PC (e.g. another PC) keeps the clock's position.
      expect(listeningPosition(start, h.clock), const Duration(seconds: 80));
      again.dispose();
      await h.dispose(disposeExam: false);
    });

    test('first play: a slow start-up never skips the intro; after a PC switch the clock decides', () async {
      var now = DateTime.utc(2026, 11, 12, 9);
      final h = await Harness.create(now: () => now);
      await h.exam.login('DEMO1');
      h.exam.acceptRules();
      h.exam.confirmSoundCheck();
      await waitFor(() => h.exam.stage == ExamStage.exam);
      final start = h.exam.currentModule!;

      // Opening the file / audio device took 7 s: the recording still starts at 0:00, the module ends 7 s later.
      now = now.add(const Duration(seconds: 7));
      final m = (await h.exam.audioFirstPlay(start.typeId, const Duration(seconds: 7)))!;
      expect(listeningPosition(m, h.clock), Duration.zero);
      expect(m.finishedAt, start.finishedAt!.add(const Duration(seconds: 7)));
      await waitFor(() => h.api.audioLag[start.typeId] == 7);
      // Only once per module on this PC.
      expect(await h.exam.audioFirstPlay(start.typeId, const Duration(seconds: 30)), isNull);

      // Another PC (no saved position, module not started there): no rewind.
      final other = h.restartController();
      expect(await other.audioFirstPlay(start.typeId + 100, const Duration(seconds: 5)), isNull);
      other.dispose();
      await h.dispose();
    });

    test('crash between the last module submit and the final submit: final submit on restart', () async {
      final h = await _inListening();
      final token = (await h.db.session(_attempt))!.token;
      for (final t in [1, 2, 3]) {
        if (t > 1) await h.api.startModule(token, t);
        await h.api.submitModule(token, t);
      }
      // The app "crashed" here: a new controller resumes.
      h.exam.dispose();
      final again = h.restartController();
      expect(await again.resumeIfNeeded(), isTrue);
      await waitFor(() => again.stage == ExamStage.completed);
      expect(h.api.examSubmitted, isTrue);
      expect(again.submitConfirmed, isTrue);

      // After the Completed screen, a restart does not show it again.
      again.returnToCodeScreen();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final third = h.restartController();
      expect(await third.resumeIfNeeded(), isFalse);
      expect(third.stage, ExamStage.idle);
      again.dispose();
      third.dispose();
      await h.dispose(disposeExam: false);
    });

    test('flags survive a restart; Start cannot be double-tapped', () async {
      final h = await Harness.create();
      await h.exam.login('DEMO1');
      h.exam.acceptRules();
      h.exam.acceptRules(); // second tap ignored (already on sound check)
      h.exam.confirmSoundCheck();
      h.exam.confirmSoundCheck();
      await waitFor(() => h.exam.stage == ExamStage.exam);
      expect(h.api.calls.where((c) => c == 'startModule').length, 1);
      h.exam.toggleFlag(7002);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      h.exam.dispose();
      final again = h.restartController();
      expect(await again.resumeIfNeeded(), isTrue);
      expect(again.flagged, contains(7002));
      again.dispose();
      await h.dispose(disposeExam: false);
    });

    test('login waits while an update is installed; resume and login never overlap', () async {
      final h = await Harness.create();
      h.exam.loginBlocked = () => true;
      await h.exam.login('DEMO1');
      expect(h.exam.stage, ExamStage.idle);
      expect(h.exam.error, contains('update'));
      expect(h.api.calls, isNot(contains('login')));
      h.exam.loginBlocked = () => false;

      final resume = h.exam.resumeIfNeeded();
      expect(h.exam.busy, isTrue);
      await h.exam.login('DEMO1'); // ignored while busy
      await resume;
      expect(h.api.calls, isNot(contains('login')));
      await h.dispose();
    });

    test('426 during the exam stops with a message instead of looping', () async {
      final h = await _inListening();
      h.api.outdatedExamCalls = true;
      await h.exam.confirmFinishModule();
      expect(h.exam.stage, ExamStage.blocked);
      expect(h.exam.blockReason, BlockReason.clientOutdated);
      expect(h.api.calls.where((c) => c == 'submitModule').length, 1);
      await h.dispose();
    });

    test('text answers are clipped to 20000 characters in the controller', () async {
      final h = await _inListening();
      h.exam.setAnswer(partId: 101, questionId: 7001, text: 'z' * 30000);
      expect(h.exam.answerFor(7001).text!.length, kMaxAnswerChars);
      await waitFor(() => h.api.savedAnswers.containsKey(7001));
      expect(h.api.savedAnswers[7001]!.text!.length, kMaxAnswerChars);
      await h.dispose();
    });
  });

  test('401 codes of API v1.1 count as a lost session', () {
    for (final code in ['session_revoked', 'session_expired', null]) {
      final e = ApiException(code: ApiErrorCode.fromWire(code, 401), statusCode: 401);
      expect(e.isAuthLost, isTrue, reason: '$code');
    }
    expect(ApiException(code: ApiErrorCode.fromWire('session_active_elsewhere', 409)).userMessage,
        contains('another PC'));
  });
}

/// The violations endpoint is down (500); everything else works.
class _ViolationsDownApi extends FakeMynineApi {
  _ViolationsDownApi(this.inner) : super(clock: inner.clock, latency: Duration.zero);
  final FakeMynineApi inner;

  @override
  Future<AnswersResponse> sendAnswers(String examToken, List<AnswerItem> answers) =>
      inner.sendAnswers(examToken, answers);

  @override
  Future<ExamSubmitResponse> submitExam(String examToken) => inner.submitExam(examToken);

  @override
  Future<ViolationsResponse> sendViolations(String examToken, List<ViolationItem> violations) async =>
      throw ApiException(code: ApiErrorCode.serverError, statusCode: 500);
}
