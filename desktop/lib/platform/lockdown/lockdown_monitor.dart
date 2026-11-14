import 'dart:async';

import '../../core/config/app_config.dart';
import '../../data/models/exam_models.dart';
import 'lockdown.dart';

typedef ViolationSink = Future<void> Function(String type, [Map<String, Object?>? detail]);

/// Watches the PC during an exam and reports violations:
/// focus loss (with the process that took the focus), second monitor,
/// banned processes (which it also closes), VM; clears the clipboard.
class LockdownMonitor {
  LockdownMonitor({
    required this.lockdown,
    required this.report,
    required this.bannedProcesses,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Lockdown lockdown;
  final ViolationSink report;
  final List<String> Function() bannedProcesses;
  final DateTime Function() _now;

  /// The same banned app is reported again only after this long (it keeps
  /// being closed on every scan).
  static const bannedReportInterval = Duration(minutes: 1);

  Timer? _timer;
  StreamSubscription<LockdownEvent>? _sub;
  final Map<String, DateTime> _reportedProcesses = {};
  bool _multiMonitorReported = false;
  DateTime? _lastFocusLost;
  bool get running => _timer != null;

  Future<void> start() async {
    if (_timer != null) return;
    _reportedProcesses.clear();
    _multiMonitorReported = false;
    _sub = lockdown.events.listen(_onEvent);
    _timer = Timer.periodic(AppConfig.lockdownScanInterval, (_) => scan());
    await lockdown.clearClipboard();
    if (await lockdown.isVirtualMachine()) {
      await report(ViolationType.vmDetected);
    }
    await scan(startOfExam: true);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
  }

  void _onEvent(LockdownEvent e) {
    switch (e.type) {
      case LockdownEventType.focusLost:
        final now = _now();
        // Collapse bursts (a single Alt+Tab attempt can fire several events).
        if (_lastFocusLost == null || now.difference(_lastFocusLost!) > const Duration(seconds: 3)) {
          _lastFocusLost = now;
          final detail = Map<String, Object?>.of(e.detail)..remove('type');
          unawaited(report(ViolationType.focusLost, detail.isEmpty ? null : detail));
        }
      case LockdownEventType.displayChanged:
        unawaited(scan());
      case LockdownEventType.captureBlocked:
        unawaited(report(ViolationType.screenCaptureAttempt));
      case LockdownEventType.focusGained:
      case LockdownEventType.unknown:
        break;
    }
  }

  /// One scan pass (exposed for tests). [startOfExam]: programs left open on the PC before the candidate sat
  /// down are closed quietly (not the candidate's doing); only one that cannot be closed is reported.
  Future<void> scan({bool startOfExam = false}) async {
    final monitors = await lockdown.monitorCount();
    if (monitors > 1 && !_multiMonitorReported) {
      _multiMonitorReported = true;
      await report(ViolationType.secondMonitor, {'count': monitors});
    } else if (monitors <= 1) {
      _multiMonitorReported = false;
    }
    await closeBannedProcesses(reportClosed: !startOfExam);
    // The clipboard is cleared once when the exam starts (nothing comes in from outside); it is not cleared on
    // every scan any more, so Ctrl+C / Ctrl+V between the passage, questions and answers work.
  }

  /// Finds running banned apps, closes them and reports each one
  /// (`banned_process` with `{process, terminated}`). Returns the results.
  Future<List<ProcessKillResult>> closeBannedProcesses({bool reportClosed = true}) async {
    final banned = effectiveBannedProcesses(bannedProcesses());
    if (banned.isEmpty) return const [];
    final found = await lockdown.scanProcesses(banned);
    if (found.isEmpty) return const [];
    final killed = {for (final r in await lockdown.terminateProcesses(found)) r.process: r.terminated};
    final results = [for (final name in found) ProcessKillResult(name, terminated: killed[name] ?? false)];
    final now = _now();
    for (final r in results) {
      if (!reportClosed && r.terminated) continue;
      final last = _reportedProcesses[r.process];
      if (last == null || now.difference(last) >= bannedReportInterval) {
        _reportedProcesses[r.process] = now;
        await report(ViolationType.bannedProcess, {'process': r.process, 'terminated': r.terminated});
      }
    }
    return results;
  }
}
