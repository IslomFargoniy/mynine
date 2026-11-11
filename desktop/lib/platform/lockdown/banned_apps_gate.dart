import 'dart:async';

import 'package:flutter/foundation.dart';

import 'lockdown.dart';

/// Rules screen gate: lists the banned apps still running on this PC and
/// keeps "Start" disabled until they are closed (by the candidate/staff or
/// with [closeAll]). Re-checks every [interval] while [start]ed.
class BannedAppsGate extends ChangeNotifier {
  BannedAppsGate({
    required this.lockdown,
    required this.bannedProcesses,
    this.interval = const Duration(seconds: 3),
  });

  final Lockdown lockdown;
  final List<String> Function() bannedProcesses;
  final Duration interval;

  Timer? _timer;
  List<String> _running = const [];
  List<String> _notClosed = const [];
  bool _checked = false;
  bool _busy = false;
  bool _disposed = false;

  /// Banned apps found by the last check (lower-case exe names).
  List<String> get running => _running;

  /// Apps the last [closeAll] could not terminate (other user / elevated).
  List<String> get notClosed => _notClosed;

  bool get checked => _checked;
  bool get busy => _busy;

  /// True once a check found no banned app running.
  bool get canStart => _checked && _running.isEmpty;

  void start() {
    unawaited(refresh());
    _timer ??= Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    final banned = effectiveBannedProcesses(bannedProcesses());
    final found = banned.isEmpty ? const <String>[] : await lockdown.scanProcesses(banned);
    if (_disposed) return;
    final sorted = [...found]..sort();
    final changed = !listEquals(sorted, _running) || !_checked;
    _running = sorted;
    _checked = true;
    if (_running.isEmpty) _notClosed = const [];
    if (changed) notifyListeners();
  }

  /// Terminates every running banned app, then checks again.
  Future<void> closeAll() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      if (_running.isNotEmpty) {
        final results = await lockdown.terminateProcesses(_running);
        _notClosed = [for (final r in results) if (!r.terminated) r.process];
      }
      await refresh();
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
