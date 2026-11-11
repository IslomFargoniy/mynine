import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/features/rules/rules_screen.dart';
import 'package:mynine_desktop/platform/lockdown/banned_apps_gate.dart';
import 'package:mynine_desktop/platform/lockdown/lockdown.dart';
import 'package:mynine_desktop/platform/lockdown/lockdown_monitor.dart';

/// Lockdown with a fake process table. Names in [unkillable] survive
/// termination (e.g. another user's / elevated process).
class FakeLockdown extends NoopLockdown {
  FakeLockdown(Iterable<String> running) : running = {...running};

  final Set<String> running;
  final Set<String> unkillable = {};
  final List<List<String>> terminateCalls = [];
  final _controller = StreamController<LockdownEvent>.broadcast();

  void emit(LockdownEvent e) => _controller.add(e);

  @override
  Stream<LockdownEvent> get events => _controller.stream;

  @override
  Future<List<String>> scanProcesses(List<String> banned) async =>
      [for (final n in banned) if (running.contains(n)) n];

  @override
  Future<List<ProcessKillResult>> terminateProcesses(List<String> names) async {
    terminateCalls.add(names);
    return [
      for (final n in names)
        if (running.contains(n))
          ProcessKillResult(n, terminated: !unkillable.contains(n) && running.remove(n)),
    ];
  }
}

void main() {
  group('banned list', () {
    test('protected system processes are never part of the enforced list', () {
      final list = effectiveBannedProcesses(['Chrome.exe', 'explorer.exe', 'svchost.exe', ' cmd.exe ', 'csrss.exe']);
      expect(list, ['chrome.exe', 'cmd.exe']);
    });

    test('an empty server list falls back to the default list', () {
      final list = effectiveBannedProcesses(const []);
      expect(list, containsAll(['taskmgr.exe', 'chrome.exe', 'telegram.exe', 'anydesk.exe', 'powershell.exe']));
      expect(list.toSet().intersection(kProtectedProcesses), isEmpty);
    });
  });

  group('rules screen gate', () {
    test('Start is blocked until the banned apps are closed', () async {
      final lockdown = FakeLockdown(['chrome.exe', 'telegram.exe', 'explorer.exe']);
      final gate = BannedAppsGate(lockdown: lockdown, bannedProcesses: () => ['chrome.exe', 'telegram.exe', 'explorer.exe']);

      expect(gate.canStart, isFalse, reason: 'not checked yet');
      await gate.refresh();
      expect(gate.running, ['chrome.exe', 'telegram.exe']);
      expect(gate.canStart, isFalse);

      await gate.closeAll();
      expect(lockdown.terminateCalls.single, ['chrome.exe', 'telegram.exe']);
      expect(gate.running, isEmpty);
      expect(gate.canStart, isTrue);
      expect(lockdown.running, contains('explorer.exe'));
      gate.dispose();
    });

    test('an app that cannot be closed blocks Start only until one close attempt failed', () async {
      final lockdown = FakeLockdown(['anydesk.exe', 'chrome.exe'])..unkillable.add('anydesk.exe');
      final gate = BannedAppsGate(lockdown: lockdown, bannedProcesses: () => ['anydesk.exe', 'chrome.exe']);
      await gate.refresh();
      expect(gate.canStart, isFalse); // nothing tried yet
      expect(gate.overridden, isFalse);
      await gate.closeAll();
      expect(gate.running, ['anydesk.exe']);
      expect(gate.notClosed, ['anydesk.exe']);
      // An unkillable (elevated / other user) program must not block forever:
      // Start is allowed, the screen records a violation for the invigilator.
      expect(gate.canStart, isTrue);
      expect(gate.overridden, isTrue);
      expect(gate.unkillableRunning, ['anydesk.exe']);

      // A new banned app that was never tried blocks Start again.
      lockdown.running.add('chrome.exe');
      await gate.refresh();
      expect(gate.canStart, isFalse);

      // Closed by hand later → the next check unblocks Start normally.
      lockdown.running
        ..remove('anydesk.exe')
        ..remove('chrome.exe');
      await gate.refresh();
      expect(gate.canStart, isTrue);
      expect(gate.overridden, isFalse);
      expect(gate.notClosed, isEmpty);
      gate.dispose();
    });

    test('rules screen (autoClose): banned apps close silently, no panel unless one survives', () async {
      final lockdown = FakeLockdown(['telegram.exe', 'anydesk.exe'])..unkillable.add('anydesk.exe');
      final gate = BannedAppsGate(
        lockdown: lockdown,
        bannedProcesses: () => ['telegram.exe', 'anydesk.exe'],
        autoClose: true,
      );
      await gate.refresh();
      // closeAll ran by itself.
      for (var i = 0; i < 20 && gate.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(lockdown.terminateCalls, isNotEmpty);
      expect(lockdown.running, isNot(contains('telegram.exe')));
      expect(gate.running, ['anydesk.exe']);
      expect(gate.needsAttention, isTrue, reason: 'the program that could not be closed is shown');

      lockdown.unkillable.clear();
      lockdown.running.remove('anydesk.exe');
      await gate.refresh();
      expect(gate.needsAttention, isFalse);
      expect(gate.canStart, isTrue);
      gate.dispose();
    });

    test('nothing running → Start allowed after the first check', () async {
      final gate = BannedAppsGate(lockdown: FakeLockdown(const []), bannedProcesses: () => const []);
      await gate.refresh();
      expect(gate.canStart, isTrue);
      gate.dispose();
    });

    testWidgets('panel lists the programs and closes them', (tester) async {
      final lockdown = FakeLockdown(['chrome.exe', 'taskmgr.exe']);
      final gate = BannedAppsGate(lockdown: lockdown, bannedProcesses: () => ['chrome.exe', 'taskmgr.exe']);
      await tester.runAsync(gate.refresh);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ListenableBuilder(listenable: gate, builder: (_, _) => BannedAppsPanel(gate: gate))),
      ));
      expect(find.text('•  Google Chrome'), findsOneWidget);
      expect(find.text('•  Task Manager'), findsOneWidget);

      await tester.tap(find.byKey(const Key('banned-close-all')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
      expect(find.byKey(const Key('banned-apps')), findsNothing);
      expect(gate.canStart, isTrue);
      gate.dispose();
    });
  });

  group('exam monitor', () {
    test('closes banned apps on start and on every scan, reporting each with terminated', () async {
      var now = DateTime(2026, 11, 12, 9);
      final lockdown = FakeLockdown(['chrome.exe', 'anydesk.exe', 'explorer.exe'])..unkillable.add('anydesk.exe');
      final reports = <List<Object?>>[];
      final monitor = LockdownMonitor(
        lockdown: lockdown,
        report: (type, [detail]) async => reports.add([type, detail]),
        bannedProcesses: () => ['chrome.exe', 'anydesk.exe', 'explorer.exe'],
        now: () => now,
      );

      await monitor.start();
      expect(reports, [
        ['banned_process', {'process': 'chrome.exe', 'terminated': true}],
        ['banned_process', {'process': 'anydesk.exe', 'terminated': false}],
      ]);
      expect(lockdown.running, containsAll(['explorer.exe', 'anydesk.exe']));
      expect(lockdown.running, isNot(contains('chrome.exe')));

      // Re-opened: closed again; reported again only after a minute.
      lockdown.running.add('chrome.exe');
      await monitor.scan();
      expect(lockdown.running, isNot(contains('chrome.exe')));
      expect(reports.length, 2);

      now = now.add(const Duration(minutes: 2));
      lockdown.running.add('chrome.exe');
      await monitor.scan();
      expect(reports.length, 4); // chrome (closed) + anydesk (still running)
      expect(reports[2], ['banned_process', {'process': 'chrome.exe', 'terminated': true}]);
      monitor.stop();
    });

    test('focus loss is reported with the process that took the focus', () async {
      final lockdown = FakeLockdown(const []);
      final reports = <List<Object?>>[];
      final monitor = LockdownMonitor(
        lockdown: lockdown,
        report: (type, [detail]) async => reports.add([type, detail]),
        bannedProcesses: () => const [],
      );
      await monitor.start();
      lockdown.emit(const LockdownEvent(LockdownEventType.focusLost, {'type': 'focus_lost', 'process': 'chrome.exe'}));
      await Future<void>.delayed(Duration.zero);
      expect(reports, [['focus_lost', {'process': 'chrome.exe'}]]);
      monitor.stop();
    });
  });
}
