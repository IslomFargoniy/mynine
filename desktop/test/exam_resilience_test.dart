// Audit fixes: failing audio downloads, offline time-over submits, lost
// submit answers, refused module starts, re-login screen, exit password.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/app/providers.dart';
import 'package:mynine_desktop/app/theme.dart';
import 'package:mynine_desktop/core/api/api_exception.dart';
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/storage/settings_store.dart';
import 'package:mynine_desktop/data/models/exam_models.dart';
import 'package:mynine_desktop/data/repositories/answer_queue.dart';
import 'package:mynine_desktop/data/repositories/device_repository.dart';
import 'package:mynine_desktop/data/repositories/exam_repository.dart';
import 'package:mynine_desktop/features/exam/blocked_screen.dart';
import 'package:mynine_desktop/features/exam/exam_controller.dart';
import 'package:mynine_desktop/features/sound_check/sound_check_screen.dart';
import 'package:mynine_desktop/platform/lockdown/lockdown.dart';

import 'support/harness.dart';

const _attempt = FakeMynineApi.attemptId;

ApiException _notFound() => ApiException(code: ApiErrorCode.notFound, statusCode: 404);

/// Shortens every retry / grace of [exam] for tests.
void _fast(ExamController exam, {Duration grace = const Duration(milliseconds: 300)}) {
  exam
    ..assetRetryDelay = const Duration(milliseconds: 10)
    ..retryDelay = const Duration(milliseconds: 20)
    ..submitGrace = grace;
}

/// The server revokes the token; the next sync pass (a violation to send)
/// meets the 401 and the exam locks.
Future<void> _loseSession(Harness h) async {
  h.api.revokeToken();
  await h.exam.reportViolation(ViolationType.focusLost);
  await waitFor(() => h.exam.stage == ExamStage.blocked);
}

Future<Harness> _inListening({DateTime Function()? now}) async {
  final h = await Harness.create(now: now);
  _fast(h.exam);
  await h.exam.login('DEMO1');
  h.exam.acceptRules();
  h.exam.confirmSoundCheck();
  await waitFor(() => h.exam.stage == ExamStage.exam);
  return h;
}

void main() {
  group('audio download', () {
    test('a failing audio file shows the reason after a few rounds and recovers', () async {
      final h = await Harness.create();
      _fast(h.exam);
      h.api.audioDownloadError = _notFound();
      await h.exam.login('DEMO1');
      expect(h.exam.stage, ExamStage.rules);
      expect(h.exam.audioReady, isFalse);
      h.exam.acceptRules();
      h.exam.confirmSoundCheck();
      await waitFor(() => (h.exam.transitionMessage ?? '').contains('could not be downloaded'));
      expect(h.exam.stage, ExamStage.transition);
      expect(h.exam.transitionMessage, contains('HTTP 404'));
      expect(h.exam.transitionMessage, contains('call the invigilator'));
      expect(h.exam.assetFailures, greaterThanOrEqualTo(ExamController.assetFailuresShown));

      h.api.audioDownloadError = null;
      await waitFor(() => h.exam.stage == ExamStage.exam);
      expect(h.exam.audioReady, isTrue);
      expect(h.exam.assetError, isNull);
      await h.dispose();
    });

    test('a retry skips audio files that already arrived', () async {
      final h = await Harness.create();
      final api = _TwoAudioApi(h.api);
      final repo = ExamRepository(api: api, db: h.db, paths: h.examRepo.paths);
      final token = (await h.api.login('DEMO1')).token;
      final cached = await repo.fetchExam(token, _attempt);
      expect(cached.payload.audio.length, 2);

      Object? error;
      try {
        await repo.downloadAssets(token, _attempt, cached);
      } catch (e) {
        error = e;
      }
      expect(error, isA<AssetDownloadException>());
      final partial = (error! as AssetDownloadException).partial;
      expect(partial.audioFiles.keys, ['test-9']); // the good one is kept
      expect((error as AssetDownloadException).reason, contains('404'));
      expect(api.fetched['fake://audio/test/9'], 1);

      api.failing = false;
      final done = await repo.downloadAssets(token, _attempt, partial);
      expect(ExamRepository.audioComplete(done), isTrue);
      expect(api.fetched['fake://audio/test/9'], 1); // not fetched again
      expect(api.fetched['fake://audio/extra'], 2);
      await h.dispose();
    });

    test('the audio wait stops when the exam ends meanwhile (resume path)', () async {
      final h = await Harness.create();
      _fast(h.exam);
      h.api.audioDownloadError = _notFound();
      await h.exam.login('DEMO1');
      final token = (await h.db.session(_attempt))!.token;
      await h.api.startModule(token, 1); // Listening runs on the server
      h.exam.dispose();

      final again = h.restartController();
      _fast(again);
      final resumed = again.resumeIfNeeded(); // waits for the audio
      await waitFor(() => again.stage == ExamStage.transition);
      expect(again.transitionMessage, contains('audio'));
      // An admin force-submits while the audio is still missing.
      again.applyHeartbeat(const ExamHeartbeatResponse(finished: true));
      await waitFor(() => again.stage == ExamStage.completed);
      expect(await resumed, isTrue);
      h.api.audioDownloadError = null;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(again.stage, ExamStage.completed); // never back into the exam
      again.dispose();
      await h.dispose(disposeExam: false);
    });

    test('a new session starts its own download while an old job still sleeps', () async {
      final h = await Harness.create();
      final exam = h.exam;
      exam.assetRetryDelay = const Duration(minutes: 5);
      h.api.audioDownloadError = _notFound();
      await exam.login('DEMO1');
      await waitFor(() => exam.assetFailures >= 1);

      // The session is lost and restored with a new token.
      await _loseSession(h);
      h.api.audioDownloadError = null;
      await exam.login('DEMO1');
      expect(exam.stage, ExamStage.rules);
      await waitFor(() => exam.audioReady, timeout: const Duration(seconds: 5));
      await h.dispose();
    });

    testWidgets('sound check says "Offline Ready" only once the audio is here', (tester) async {
      late Harness h;
      await tester.runAsync(() async {
        h = await Harness.create();
        _fast(h.exam);
        h.api.audioDownloadError = _notFound();
        await h.exam.login('DEMO1');
        h.exam.acceptRules();
      });
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [examControllerProvider.overrideWithValue(h.exam)],
        child: MaterialApp(theme: buildTheme(), home: const SoundCheckScreen()),
      ));
      expect(find.text('Preparing audio…'), findsOneWidget);
      expect(find.text('Offline Ready'), findsNothing);

      await tester.runAsync(() async {
        h.api.audioDownloadError = null;
        await waitFor(() => h.exam.audioReady);
      });
      await tester.pump();
      expect(find.text('Offline Ready'), findsOneWidget);
      expect(find.text('Preparing audio…'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
  });

  group('submitting', () {
    test('time over while offline: the module is submitted locally after the grace', () async {
      var now = DateTime.now().toUtc();
      final h = await _inListening(now: () => now);
      final exam = h.exam;
      h.api.offline = true;
      exam.setAnswer(partId: 101, questionId: 7001, text: 'Smith');
      await exam.flushPending();
      now = now.add(const Duration(minutes: 11)); // Listening time is over
      await waitFor(() => exam.currentModule?.isReading ?? false);
      expect(exam.stage, ExamStage.rules);
      expect(exam.modules.first.isSubmitted, isTrue);
      expect(h.api.calls, contains('submitModule'));
      // The answer stays queued for the server (it accepts late answers).
      expect(await AnswerQueueRepository(h.db).pendingCount(attemptId: _attempt), 1);
      await h.dispose();
    });

    test('a refused module submit shows the server reason, not "waiting for the connection"', () async {
      final h = await _inListening();
      h.api.submitModuleError = ApiException(code: ApiErrorCode.deviceBlocked, statusCode: 403);
      final done = h.exam.confirmFinishModule();
      await waitFor(() => h.exam.stage == ExamStage.transition);
      expect(h.exam.transitionMessage, contains('This computer is blocked'));
      expect(h.exam.transitionMessage, isNot(contains('waiting for the connection')));
      h.api.submitModuleError = null;
      await done;
      expect(h.exam.currentModule!.isReading, isTrue);
      await h.dispose();
    });

    test('final submit whose answer was lost: the retry sees the closed session as submitted', () async {
      final h = await Harness.create();
      await h.exam.login('DEMO1');
      final token = (await h.db.session(_attempt))!.token;
      for (final t in [1, 2, 3]) {
        await h.api.startModule(token, t);
        await h.api.submitModule(token, t);
      }
      h.exam.dispose();
      h.api.loseSubmitExamResponses = 1;
      final again = h.restartController();
      _fast(again, grace: const Duration(seconds: 5));
      expect(await again.resumeIfNeeded(), isTrue);
      await waitFor(() => again.stage == ExamStage.completed);
      expect(again.submitConfirmed, isTrue);
      final s = (await h.db.session(_attempt))!;
      expect(s.closed, isTrue);
      expect(s.submitPending, isFalse);
      again.dispose();
      await h.dispose(disposeExam: false);
    });

    test('sync: a refused token after a pending submit closes the session and flips Completed', () async {
      final h = await Harness.create();
      await h.exam.login('DEMO1');
      final token = (await h.db.session(_attempt))!.token;
      for (final t in [1, 2, 3]) {
        await h.api.startModule(token, t);
        await h.api.submitModule(token, t);
      }
      h.exam.dispose();
      h.api.failSubmitExam = true;
      final again = h.restartController();
      _fast(again, grace: Duration.zero);
      expect(await again.resumeIfNeeded(), isTrue);
      await waitFor(() => again.stage == ExamStage.completed);
      expect(again.submitConfirmed, isFalse);
      expect((await h.db.session(_attempt))!.submitPending, isTrue);

      // The submit did reach the server; it revoked the token.
      h.api.failSubmitExam = false;
      h.api.revokeToken();
      h.sync.kick();
      await waitFor(() => again.submitConfirmed);
      final s = (await h.db.session(_attempt))!;
      expect(s.closed, isTrue);
      expect(s.submitPending, isFalse);
      expect(s.authLost, isFalse);
      again.dispose();
      await h.dispose(disposeExam: false);
    });
  });

  group('module start', () {
    test('404 on start goes back to the Start screen with the reason (no endless retry)', () async {
      final h = await Harness.create();
      _fast(h.exam);
      await h.exam.login('DEMO1');
      h.api.startModuleError = _notFound();
      h.exam.acceptRules();
      h.exam.confirmSoundCheck();
      await waitFor(() => h.exam.stage == ExamStage.rules);
      expect(h.exam.error, contains('Not found'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(h.api.calls.where((c) => c == 'startModule').length, 1);

      h.api.startModuleError = null;
      h.exam.acceptRules();
      expect(h.exam.error, isNull);
      h.exam.confirmSoundCheck();
      await waitFor(() => h.exam.stage == ExamStage.exam);
      await h.dispose();
    });

    test('attempt_finished on start ends the exam instead of opening the next module', () async {
      final h = await Harness.create();
      _fast(h.exam);
      await h.exam.login('DEMO1');
      h.api.startModuleError = ApiException(code: ApiErrorCode.attemptFinished, statusCode: 409);
      h.exam.acceptRules();
      h.exam.confirmSoundCheck();
      await waitFor(() => h.exam.stage == ExamStage.completed);
      expect(h.exam.submitConfirmed, isTrue);
      expect(h.api.calls.where((c) => c == 'startModule').length, 1);
      await h.dispose();
    });
  });

  group('session', () {
    test('the exam heartbeat runs already on the rules screen', () async {
      final h = await Harness.create();
      await h.exam.login('DEMO1');
      expect(h.exam.stage, ExamStage.rules);
      await waitFor(() => h.api.calls.contains('examHeartbeat'));
      // Remote force submit is seen before any module started.
      h.api.forceFinished = true;
      h.exam.applyHeartbeat(const ExamHeartbeatResponse(finished: true));
      await waitFor(() => h.exam.stage == ExamStage.completed);
      await h.dispose();
    });

    test('a failed prefetch on the locked screen keeps the reason (code field stays)', () async {
      final h = await _inListening();
      await _loseSession(h);
      h.api.prefetchError = ApiException(code: ApiErrorCode.serverError, statusCode: 500);
      await h.exam.login('DEMO1');
      expect(h.exam.stage, ExamStage.blocked);
      expect(h.exam.blockReason, BlockReason.sessionLost);
      expect(h.exam.error, isNotNull);

      h.api.prefetchError = null;
      await h.exam.login('DEMO1');
      expect(h.exam.stage, ExamStage.exam);
      expect(h.exam.blockReason, isNull);
      await h.dispose();
    });

    test('an unexpected login error shows its cause', () async {
      final h = await Harness.create();
      h.api.prefetchError = const FileSystemException('disk full');
      await h.exam.login('DEMO1');
      expect(h.exam.stage, ExamStage.idle);
      expect(h.exam.error, startsWith('Something went wrong'));
      expect(h.exam.error, contains('disk full'));
      await h.dispose();
    });

    testWidgets('a lost session shows no text while it is restored in the background', (tester) async {
      late Harness h;
      await tester.runAsync(() async {
        h = await _inListening();
        await _loseSession(h);
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          examControllerProvider.overrideWithValue(h.exam),
          deviceRepositoryProvider.overrideWithValue(h.device),
          connectionProvider.overrideWithValue(h.connection),
          syncServiceProvider.overrideWithValue(h.sync),
        ],
        child: MaterialApp(theme: buildTheme(), home: const BlockedScreen()),
      ));
      expect(find.byKey(const Key('blocked-recovering')), findsOneWidget);
      expect(find.byKey(const Key('blocked-message')), findsNothing);
      expect(find.textContaining('invigilator'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
  });

  group('exit password', () {
    Future<DeviceRepository> device(FakeMynineApi api) async {
      final d = DeviceRepository(
        api: api,
        store: MemorySettingsStore(),
        credentials: DeviceCredentials(),
        lockdown: NoopLockdown(),
        appVersion: '1.0.0',
      );
      await d.load();
      return d;
    }

    test('the offline hash comes with the registration; a blocked PC still opens with it', () async {
      final h = await Harness.create(register: false);
      final d = await device(h.api);
      await d.register(password: FakeMynineApi.exitPassword);
      expect(d.config.exitPasswordOffline, h.api.offlineHash);

      h.api.deviceUnlockError = ApiException(code: ApiErrorCode.deviceBlocked, statusCode: 403);
      expect(await d.checkExitPassword(FakeMynineApi.exitPassword), ExitPasswordCheck.ok);
      expect(await d.checkExitPassword('wrong'), ExitPasswordCheck.wrong);
      await h.dispose();
    });

    test('without an offline hash the dialog says why instead of "Incorrect password"', () async {
      final h = await Harness.create(register: false);
      h.api.registerReturnsOfflineHash = false;
      final d = await device(h.api);
      await d.register(password: FakeMynineApi.exitPassword);
      expect(d.config.exitPasswordOffline, isNull);

      h.api.deviceUnlockError = ApiException(code: ApiErrorCode.deviceBlocked, statusCode: 403);
      final blocked = await d.checkExitPassword(FakeMynineApi.exitPassword);
      expect(blocked, ExitPasswordCheck.blocked);
      expect(blocked.message, contains('blocked on the server'));

      h.api.deviceUnlockError = ApiException(code: ApiErrorCode.deviceNotApproved, statusCode: 403);
      expect(await d.checkExitPassword(FakeMynineApi.exitPassword), ExitPasswordCheck.notApproved);

      h.api.deviceUnlockError = ApiException(code: ApiErrorCode.tooManyRequests, statusCode: 429);
      final many = await d.checkExitPassword(FakeMynineApi.exitPassword);
      expect(many, ExitPasswordCheck.tooManyAttempts);
      expect(many.message, contains('wait a minute'));

      h.api.deviceUnlockError = null;
      expect(await d.verifyExitPassword(FakeMynineApi.exitPassword), isTrue);
      await h.dispose();
    });
  });
}

/// Two audio files: the extra one (no checksum) fails while [failing].
class _TwoAudioApi extends FakeMynineApi {
  _TwoAudioApi(this.inner) : super(clock: inner.clock, latency: Duration.zero);
  final FakeMynineApi inner;
  bool failing = true;
  final Map<String, int> fetched = {};

  @override
  Future<PrefetchPayload> prefetch(String examToken) async {
    final p = await inner.prefetch(examToken);
    return p.copyWith(audio: [
      ...p.audio,
      const AudioAsset(key: 'extra', url: 'fake://audio/extra', size: 1),
    ]);
  }

  @override
  Future<File> download(
    String url,
    File target, {
    String? examToken,
    ProgressCallback? onProgress,
    bool anonymous = false,
  }) async {
    fetched[url] = (fetched[url] ?? 0) + 1;
    if (url == 'fake://audio/extra' && failing) throw _notFound();
    return inner.download(url, target, examToken: examToken, onProgress: onProgress, anonymous: anonymous);
  }
}
