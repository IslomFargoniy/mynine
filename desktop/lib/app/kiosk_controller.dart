import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import '../core/api/api_exception.dart';
import '../core/api/mynine_api.dart';
import '../core/config/app_config.dart';
import '../core/storage/settings_store.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/sync_service.dart';
import '../features/exam/exam_controller.dart';
import '../features/updater/update_service.dart';
import '../platform/lockdown/lockdown.dart';
import '../platform/lockdown/lockdown_monitor.dart';

/// App-level orchestration outside a single exam: device registration and
/// config, code-screen heartbeat, kiosk lock state, lockdown monitoring and
/// exiting the app.
class KioskController extends ChangeNotifier {
  KioskController({
    required this.config,
    required this.device,
    required this.exam,
    required this.updates,
    required this.lockdown,
    required this.connection,
    required this.store,
    required this.serverUrl,
  }) {
    monitor = LockdownMonitor(
      lockdown: lockdown,
      report: exam.reportViolation,
      bannedProcesses: () => device.config.bannedProcesses,
    );
    exam.addListener(_onExamChanged);
    exam.onRemoteUnlock = () => unawaited(exitApp());
  }

  final AppConfig config;
  final DeviceRepository device;
  final ExamController exam;
  final UpdateService updates;
  final Lockdown lockdown;
  final ConnectionStatus connection;
  final SettingsStore store;
  final ServerUrl serverUrl;
  late final LockdownMonitor monitor;

  Timer? _deviceHeartbeat;
  Timer? _approvalPoll;
  bool _kioskLocked = false;

  /// True while the PC is in kiosk mode (exit/updates need the password).
  bool get kioskLocked => _kioskLocked;

  Future<void> init() async {
    final savedUrl = await store.read(SettingsKeys.serverUrl);
    if (savedUrl != null && savedUrl.isNotEmpty) serverUrl.value = savedUrl;
    await device.load();
    if (config.kioskEnabled) {
      await lockdown.enable();
      _kioskLocked = true;
    }
    unawaited(_bringOnline());
    _deviceHeartbeat = Timer.periodic(AppConfig.deviceHeartbeatInterval, (_) => _beat());
    // New PCs must be approved by an Admin: poll GET /device/config every 30 s
    // while the server answers device_not_approved (never re-register for it).
    _approvalPoll = Timer.periodic(AppConfig.approvalPollInterval, (_) {
      if (device.isApprovalPending && !exam.examActive) unawaited(_refreshConfig());
    });
    notifyListeners();
  }

  Future<void> _bringOnline() async {
    try {
      // No-op once registered: the token is kept forever (re-registering
      // would drop the admin approval on the server).
      await device.register();
      connection.reportSuccess();
    } catch (e) {
      connection.reportFailure(e);
      debugPrint('Device registration postponed: $e');
      return;
    }
    await _refreshConfig();
    await _beat();
  }

  Future<void> _refreshConfig() async {
    try {
      await device.refreshConfig();
      connection.reportSuccess();
    } on ApiException catch (e) {
      connection.reportFailure(e);
      if (e.code != ApiErrorCode.deviceNotApproved) debugPrint('Config refresh failed: $e');
    }
  }

  Future<void> _beat() async {
    if (exam.examActive) return; // the exam heartbeat covers this PC
    try {
      if (!device.isRegistered) {
        await _bringOnline();
        return;
      }
      final state = updates.phase == UpdatePhase.downloading || updates.phase == UpdatePhase.installing
          ? DeviceState.updating
          : DeviceState.idle;
      final r = await device.heartbeat(state);
      connection.reportSuccess();
      updates.reportApiReachable();
      if (r.unlock) await exitApp();
    } on ApiException catch (e) {
      connection.reportFailure(e);
    }
  }

  void _onExamChanged() {
    final active = exam.examActive;
    if (active && !monitor.running) {
      unawaited(monitor.start());
    } else if (!exam.examActive && monitor.running) {
      monitor.stop();
    }
  }

  Future<void> setServerUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    serverUrl.value = clean;
    await store.write(SettingsKeys.serverUrl, clean);
    // A different server does not know this PC: register there (needs approval).
    await device.register(force: true);
    await _refreshConfig();
    notifyListeners();
  }

  /// Leaves kiosk mode and quits (after the exit password or a remote unlock).
  Future<void> exitApp() async {
    monitor.stop();
    try {
      await lockdown.disable();
      await windowManager.setPreventClose(false);
    } catch (_) {}
    exit(0);
  }

  @override
  void dispose() {
    _deviceHeartbeat?.cancel();
    _approvalPoll?.cancel();
    monitor.stop();
    exam.removeListener(_onExamChanged);
    super.dispose();
  }
}

/// Mutable API base URL (changeable from the admin menu).
class ServerUrl {
  ServerUrl(this.value);
  String value;
}
