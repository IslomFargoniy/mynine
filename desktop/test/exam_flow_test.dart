import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/data/models/exam_models.dart';
import 'package:mynine_desktop/data/repositories/answer_queue.dart';
import 'package:mynine_desktop/features/exam/exam_controller.dart';

import 'support/harness.dart';

void main() {
  test('invalid code shows an error and stays on the code screen', () async {
    final h = await Harness.create();
    await h.exam.login('WRONG');
    expect(h.exam.stage, ExamStage.idle);
    expect(h.exam.error, contains('not valid'));
    await h.dispose();
  });

  test('unapproved PC shows the approval message and never re-registers', () async {
    final h = await Harness.create(approved: false);
    expect(h.device.isApprovalPending, isTrue);
    await h.exam.login('DEMO1');
    expect(h.exam.stage, ExamStage.idle);
    expect(h.device.isApprovalPending, isTrue);
    expect(h.exam.error, contains('waiting for administrator approval'));
    expect(h.api.calls.where((c) => c == 'registerDevice').length, 1);
    await h.exam.login('DEMO1');
    expect(h.api.calls.where((c) => c == 'registerDevice').length, 1);
    await h.dispose();
  });

  test('an unregistered PC cannot log in and never registers on its own', () async {
    final h = await Harness.create(register: false);
    expect(h.device.isRegistered, isFalse);
    await h.exam.login('DEMO1');
    expect(h.exam.stage, ExamStage.idle);
    expect(h.exam.error, contains('not set up'));
    expect(h.api.calls, isNot(contains('registerDevice')));
    expect(h.api.calls, isNot(contains('login')));
    await h.dispose();
  });

  test('full flow: Listening → Reading → Writing → Completed with answers delivered', () async {
    final h = await Harness.create();
    final exam = h.exam;
    await exam.login('demo1234');
    expect(exam.stage, ExamStage.rules);
    expect(exam.modules.map((m) => m.type), ['listening', 'reading', 'writing']);
    expect(exam.cached!.audioFiles['test-9'], isNotNull);
    expect(File(exam.cached!.audioFiles['test-9']!).existsSync(), isTrue);

    exam.acceptRules();
    expect(exam.stage, ExamStage.soundCheck);
    exam.confirmSoundCheck();
    await waitFor(() => exam.stage == ExamStage.exam);
    expect(exam.currentModule!.isListening, isTrue);
    expect(exam.currentModule!.finishedAt, isNotNull);
    expect(h.clock.remaining(exam.currentModule!.finishedAt).inSeconds, greaterThan(500));

    // Text answer (debounced) + option answer.
    exam.setAnswer(partId: 101, questionId: 7001, text: 'Smith', debounce: true);
    exam.setAnswer(partId: 101, questionId: 7007, optionIds: [exam.currentPart!.sections[1].questions[0].options[1].id]);
    expect(exam.answerFor(7001).text, 'Smith');
    await exam.confirmFinishModule();
    await waitFor(() => exam.currentModule?.isReading ?? false);
    expect(h.api.savedAnswers[7001]!.text, 'Smith');
    expect(h.api.savedAnswers[7007]!.optionIds, isNotEmpty);
    expect(exam.stage, ExamStage.exam);

    // Reading: no sound check, inputs open; flags.
    exam.toggleFlag(8001);
    expect(exam.flagged, contains(8001));
    exam.stepPart(1);
    expect(exam.currentPartId, 202);
    await exam.confirmFinishModule();
    await waitFor(() => exam.currentModule?.isWriting ?? false);

    exam.setAnswer(partId: 301, questionId: 9001, text: 'An essay about museums.', debounce: true);
    await exam.confirmFinishModule();
    await waitFor(() => exam.stage == ExamStage.completed);
    expect(h.api.examSubmitted, isTrue);
    expect(h.api.savedAnswers[9001]!.text, 'An essay about museums.');
    final s = await h.db.session(FakeMynineApi.attemptId);
    expect(s!.completed, isTrue);
    expect(s.closed, isTrue);

    exam.returnToCodeScreen();
    expect(exam.stage, ExamStage.idle);
    await h.dispose();
  });

  test('heartbeat applies extra time, pause and force submit', () async {
    final h = await Harness.create();
    final exam = h.exam;
    await exam.login('DEMO1');
    exam.acceptRules();
    exam.confirmSoundCheck();
    await waitFor(() => exam.stage == ExamStage.exam);
    final newEnd = exam.currentModule!.finishedAt!.add(const Duration(minutes: 5));
    exam.applyHeartbeat(ExamHeartbeatResponse(
      paused: true,
      modules: [ModuleTimer(typeId: 1, status: ModuleStatus.inProgress, finishedAt: newEnd)],
    ));
    expect(exam.currentModule!.finishedAt, newEnd);
    expect(exam.paused, isTrue);
    expect(exam.inputsLocked, isTrue);
    exam.setAnswer(partId: 101, questionId: 7001, text: 'ignored');
    expect(exam.answerFor(7001).isAnswered, isFalse);

    h.api.forceFinished = true;
    exam.applyHeartbeat(const ExamHeartbeatResponse(finished: true));
    await waitFor(() => exam.stage == ExamStage.completed);
    await h.dispose();
  });

  test('offline answers stay queued and are delivered when back online', () async {
    final h = await Harness.create();
    final exam = h.exam;
    await exam.login('DEMO1');
    exam.acceptRules();
    exam.confirmSoundCheck();
    await waitFor(() => exam.stage == ExamStage.exam);
    h.api.offline = true;
    exam.setAnswer(partId: 101, questionId: 7002, text: 'Brighton');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final queue = AnswerQueueRepository(h.db);
    expect(await queue.pendingCount(), 1);
    expect(h.api.savedAnswers.containsKey(7002), isFalse);
    h.api.offline = false;
    final s = (await h.db.activeSession())!;
    await h.sync.syncSession(s);
    expect(h.api.savedAnswers[7002]!.text, 'Brighton');
    expect(await queue.pendingCount(), 0);
    await h.dispose();
  });
}
