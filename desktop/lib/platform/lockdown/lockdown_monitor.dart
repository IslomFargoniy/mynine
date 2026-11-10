import 'dart:async';

import '../../core/config/app_config.dart';
import '../../data/models/exam_models.dart';
import 'lockdown.dart';

typedef ViolationSink = Future<void> Function(String type, [Map<String, Object?>? detail]);

/// Watches the PC during an exam and reports violations:
/// focus loss, second monitor, banned processes, VM; clears the clipboard.
class LockdownMonitor {
  LockdownMonitor({
    required this.lockdown,
    required this.report,
    required this.bannedProcesses,
  });

  final Lockdown lockdown;
  final ViolationSink report;
  final List<String> Function() bannedProcesses;

  Timer? _timer;
  StreamSubscription<LockdownEvent>? _sub;
  final Set<String> _reportedProcesses = {};
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
    await scan();
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
        final now = DateTime.now();
        // Collapse bursts (a single Alt+Tab attempt can fire several events).
        if (_lastFocusLost == null || now.difference(_lastFocusLost!) > const Duration(seconds: 3)) {
          _lastFocusLost = now;
          unawaited(report(ViolationType.focusLost, e.detail.isEmpty ? null : e.detail));
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

  /// One scan pass (exposed for tests).
  Future<void> scan() async {
    final monitors = await lockdown.monitorCount();
    if (monitors > 1 && !_multiMonitorReported) {
      _multiMonitorReported = true;
      await report(ViolationType.secondMonitor, {'count': monitors});
    } else if (monitors <= 1) {
      _multiMonitorReported = false;
    }
    final banned = bannedProcesses();
    if (banned.isNotEmpty) {
      final found = await lockdown.scanProcesses(banned);
      for (final name in found) {
        if (_reportedProcesses.add(name)) {
          await report(ViolationType.bannedProcess, {'process': name});
        }
      }
    }
    await lockdown.clearClipboard();
  }
}
