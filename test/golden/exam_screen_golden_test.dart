// Golden tests that lock the exam-room layout (header, split panes, number
// bar, question widgets) at the two centre screen sizes.
//
// Goldens are rendered on macOS (Impeller/Skia text shaping differs per OS),
// so they are tagged `golden` and skipped on other platforms. Regenerate with:
//   flutter test --update-goldens --tags golden
@Tags(['golden'])
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/app/providers.dart';
import 'package:mynine_desktop/app/theme.dart';
import 'package:mynine_desktop/data/db/app_database.dart';
import 'package:mynine_desktop/features/exam/exam_controller.dart';
import 'package:mynine_desktop/features/exam/exam_shell.dart';
import 'package:mynine_desktop/features/passage/html_document.dart';

import '../support/harness.dart';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  const inter = [
    'assets/fonts/inter/Inter-Regular.ttf',
    'assets/fonts/inter/Inter-Italic.ttf',
    'assets/fonts/inter/Inter-Medium.ttf',
    'assets/fonts/inter/Inter-SemiBold.ttf',
    'assets/fonts/inter/Inter-Bold.ttf',
    'assets/fonts/inter/Inter-BoldItalic.ttf',
    'assets/fonts/inter/Inter-ExtraBold.ttf',
  ];
  await family('Inter', inter);
  // font-mono stack is not bundled; map it to Inter so goldens are stable.
  await family('Consolas', inter);
  await family('packages/lucide_icons_flutter/Lucide', ['packages/lucide_icons_flutter/assets/lucide.ttf']);
}

final _fixedNow = DateTime.utc(2026, 11, 12, 4, 0, 0);

Future<Harness> _readingExam(WidgetTester tester) async {
  late Harness h;
  await tester.runAsync(() async {
    h = await Harness.create(now: () => _fixedNow);
    final exam = h.exam;
    await exam.login('DEMO1');
    exam.acceptRules();
    exam.confirmSoundCheck();
    await waitFor(() => exam.stage == ExamStage.exam);
    await exam.confirmFinishModule();
    await waitFor(() => exam.currentModule?.isReading ?? false);
    final tfOptions = exam.currentPart!.sections.first.questions.first.options;
    exam.setAnswer(partId: 201, questionId: 8001, optionIds: [tfOptions[1].id]);
    exam.setAnswer(partId: 201, questionId: 8005, text: 'wrought');
    exam.setAnswer(partId: 201, questionId: 8009, text: 'i  Early criticism and later acceptance');
    exam.toggleFlag(8003);
    exam.setActiveQuestion(8002);
    // A highlight in the passage ("World's Fair").
    final text = parseHtmlCached(exam.currentPart!.html).plainText;
    final at = text.indexOf("World's Fair");
    await h.db.into(h.db.highlights).insert(HighlightsCompanion.insert(
          attemptId: exam.attemptId!,
          partId: 201,
          startOffset: at,
          endOffset: at + "World's Fair".length,
          kind: const Value('highlight'),
        ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  return h;
}

Future<void> _pumpShell(WidgetTester tester, Harness h, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      examControllerProvider.overrideWithValue(h.exam),
      serverClockProvider.overrideWithValue(h.clock),
      connectionProvider.overrideWithValue(h.sync.connection),
      syncServiceProvider.overrideWithValue(h.sync),
      databaseProvider.overrideWithValue(h.db),
    ],
    child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(), home: const ExamShell()),
  ));
  // Let drift deliver the highlights, then settle.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester, Harness h) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(h.dispose);
}

void main() {
  final skip = !Platform.isMacOS;

  setUpAll(_loadFonts);

  testWidgets('reading exam screen 1920x1080', (tester) async {
    final h = await _readingExam(tester);
    await _pumpShell(tester, h, const Size(1920, 1080));
    expect(find.text('TIME REMAINING:'), findsOneWidget);
    expect(find.byKey(const Key('split-divider')), findsOneWidget);
    await expectLater(find.byType(ExamShell), matchesGoldenFile('goldens/reading_1920x1080.png'));
    await _dispose(tester, h);
  }, skip: skip);

  testWidgets('reading exam screen 1366x768', (tester) async {
    final h = await _readingExam(tester);
    await _pumpShell(tester, h, const Size(1366, 768));
    await expectLater(find.byType(ExamShell), matchesGoldenFile('goldens/reading_1366x768.png'));
    await _dispose(tester, h);
  }, skip: skip);

  testWidgets('listening exam screen 1366x768', (tester) async {
    late Harness h;
    await tester.runAsync(() async {
      h = await Harness.create(now: () => _fixedNow);
      await h.exam.login('DEMO1');
      h.exam.acceptRules();
      h.exam.confirmSoundCheck();
      await waitFor(() => h.exam.stage == ExamStage.exam);
      h.exam.setAnswer(partId: 101, questionId: 7001, text: 'Smith');
    });
    await _pumpShell(tester, h, const Size(1366, 768));
    await expectLater(find.byType(ExamShell), matchesGoldenFile('goldens/listening_1366x768.png'));
    await _dispose(tester, h);
  }, skip: skip);

  testWidgets('finish confirmation modal', (tester) async {
    tester.view.physicalSize = const Size(800, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Scaffold(
        backgroundColor: Color(0x99000000),
        body: FinishConfirmationModal(testTypeName: 'Reading', answeredCount: 9, totalCount: 15),
      ),
    ));
    await expectLater(find.byType(FinishConfirmationModal), matchesGoldenFile('goldens/finish_modal.png'));
  }, skip: skip);
}
