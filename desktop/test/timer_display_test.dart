import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/features/exam/exam_shell.dart' show TimerDisplay;

void main() {
  testWidgets('header timer freezes while the exam is paused', (tester) async {
    var local = DateTime.utc(2026, 1, 1, 9);
    final clock = ServerClock(localNow: () => local)..update(DateTime.utc(2026, 1, 1, 9));
    final end = DateTime.utc(2026, 1, 1, 9, 30);
    Widget timer(bool paused) => MaterialApp(
          home: Scaffold(body: TimerDisplay(finishedAt: end, clock: clock, paused: paused)),
        );
    await tester.pumpWidget(timer(false));
    expect(find.text('00:30:00'), findsOneWidget);
    await tester.pumpWidget(timer(true));
    local = local.add(const Duration(minutes: 7));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:30:00'), findsOneWidget); // frozen
    await tester.pumpWidget(timer(false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:23:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

}
