import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/app/providers.dart';
import 'package:mynine_desktop/app/theme.dart';
import 'package:mynine_desktop/data/models/part_payload.dart';
import 'package:mynine_desktop/features/exam/exam_controller.dart';
import 'package:mynine_desktop/features/questions/question_widgets.dart';
import 'package:mynine_desktop/features/questions/range.dart';

import 'support/harness.dart';

Future<Harness> _toModule(WidgetTester tester, {bool reading = false}) async {
  late Harness h;
  await tester.runAsync(() async {
    h = await Harness.create();
    await h.exam.login('DEMO1');
    h.exam.acceptRules();
    h.exam.confirmSoundCheck();
    await waitFor(() => h.exam.stage == ExamStage.exam);
    if (reading) {
      await h.exam.confirmFinishModule();
      await waitFor(() => h.exam.currentModule?.isReading ?? false);
      // The next module waits for Start (rules screen), then its timer runs.
      expect(h.exam.stage, ExamStage.rules);
      h.exam.acceptRules();
      await waitFor(() => h.exam.stage == ExamStage.exam);
    }
  });
  return h;
}

Future<void> _pumpSection(WidgetTester tester, Harness h, PartPayload part, SectionPayload s) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ctx = QuestionContext(
    exam: h.exam,
    part: part,
    palette: ExamPalette.of(ContrastSetting.standard),
    keys: {},
  );
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: ListenableBuilder(listenable: h.exam, builder: (_, _) => SectionView(section: s, ctx: ctx)),
      ),
    ),
  ));
}

Future<void> _done(WidgetTester tester, Harness h) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() async {
    await h.exam.flushPending();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await h.dispose();
  });
}

void main() {
  test('buildRange mirrors the web helper', () {
    expect(buildRange('A', 'D'), ['A', 'B', 'C', 'D']);
    expect(buildRange('1', '3'), ['1', '2', '3']);
    expect(buildRange('i', 'iv'), ['I', 'II', 'III', 'IV']);
    expect(buildRange('x, y', 'x, y'), ['X', 'Y']);
    expect(buildRange(null, 'A'), isEmpty);
  });

  testWidgets('matching: each question picks its heading from a select', (tester) async {
    final h = await _toModule(tester, reading: true);
    final part = h.exam.currentPart!;
    final section = part.sections.firstWhere((s) => s.questionType == QuestionType.matching);
    await _pumpSection(tester, h, part, section);
    expect(find.text('LIST OF HEADINGS'), findsOneWidget);
    const heading = 'ii A rapid and safe building process';
    await tester.tap(find.byKey(const Key('select-8008')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(heading).last);
    await tester.pumpAndSettle();
    expect(h.exam.answerFor(8008).text, heading);

    // "–" clears the answer.
    await tester.tap(find.byKey(const Key('select-8008')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('–').last);
    await tester.pumpAndSettle();
    expect(h.exam.answerFor(8008).isAnswered, isFalse);
    await _done(tester, h);
  });

  testWidgets('multiple response: limited to number_count choices', (tester) async {
    final h = await _toModule(tester);
    h.exam.selectPart(102);
    final part = h.exam.currentPart!;
    final section = part.sections.firstWhere((s) => s.questionType == QuestionType.multipleResponse);
    final q = section.questions.single;
    await _pumpSection(tester, h, part, section);
    expect(find.text('15-16'), findsOneWidget); // badge joins numbers with '-'
    for (final o in q.options.take(3)) {
      await tester.tap(find.byKey(Key('opt-${o.id}')));
      await tester.pump();
    }
    expect(h.exam.answerFor(q.id).optionIds, [q.options[0].id, q.options[1].id]);
    await _done(tester, h);
  });

  testWidgets('drag and drop: click-to-place uses each label once', (tester) async {
    final h = await _toModule(tester);
    h.exam.selectPart(102);
    final part = h.exam.currentPart!;
    final section = part.sections.firstWhere((s) => s.questionType == QuestionType.dragAndDrop);
    await _pumpSection(tester, h, part, section);
    await tester.tap(find.text('behind'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('drop-7018')));
    await tester.pump();
    expect(h.exam.answerFor(7018).text, 'behind');
    expect(find.byKey(const Key('chip-behind')), findsNothing);
    await _done(tester, h);
  });

  testWidgets('complete_section gaps write the n-th question', (tester) async {
    final h = await _toModule(tester);
    final part = h.exam.currentPart!;
    final section = part.sections.first;
    await _pumpSection(tester, h, part, section);
    await tester.enterText(find.byKey(const ValueKey('gap-7003')), 'BN1 2AB');
    await tester.pump();
    expect(h.exam.answerFor(7003).text, 'BN1 2AB');
    await tester.pump(const Duration(milliseconds: 700)); // debounce
    await _done(tester, h);
  });
}
