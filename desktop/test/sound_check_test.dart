import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/app/providers.dart';
import 'package:mynine_desktop/app/theme.dart';
import 'package:mynine_desktop/features/exam/exam_controller.dart';
import 'package:mynine_desktop/features/sound_check/sound_check_screen.dart';

import 'support/harness.dart';

void main() {
  testWidgets('the Start Test button is painted above the white card (own Material)', (tester) async {
    late Harness h;
    await tester.runAsync(() async {
      h = await Harness.create();
      await h.exam.login('DEMO1');
      await waitFor(() => h.exam.audioReady);
      h.exam.acceptRules();
    });
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [examControllerProvider.overrideWithValue(h.exam)],
      child: MaterialApp(theme: buildTheme(), home: const SoundCheckScreen()),
    ));

    final button = find.byKey(const Key('sound-ok'));
    expect(button, findsOneWidget);
    // The nearest Material above the Ink must sit inside the card, not be the Scaffold's.
    final material = tester.widget<Material>(find.ancestor(of: button, matching: find.byType(Material)).first);
    expect(material.type, MaterialType.transparency);

    await tester.tap(button);
    expect(h.exam.stage, isNot(ExamStage.soundCheck));

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(h.dispose);
  });
}
