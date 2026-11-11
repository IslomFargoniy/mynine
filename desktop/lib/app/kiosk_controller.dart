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
    // Never log in while an update is being installed (the app exits).
    exam.loginBlocked = () => updates.phase == UpdatePhase.installing;
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

  /// Fetches config and reports presence once the PC holds a device token.
  /// A PC without a token waits on the Setup screen (registration needs the
  /// center password, so it is never automatic).
  Future<void> _bringOnline() async {
    if (!device.isRegistered) return;
    await _refreshConfig();
    await _beat();
  }

  /// Setup screen / admin menu: register this PC with the center [password].
  /// Rethrows [ApiException] (`invalid_password`, `setup_password_missing`, …).
  Future<void> registerDevice({required String password, String? name}) async {
    try {
      await device.register(password: password, name: name);
      connection.reportSuccess();
    } on ApiException catch (e) {
      if (e.isNetwork) connection.reportFailure(e);
      rethrow;
    }
    notifyListeners();
    await _bringOnline();
  }

  /// Waiting screen "Check now" button.
  Future<void> checkApprovalNow() => _refreshConfig();

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
    // The exam heartbeat covers this PC — except on the locked screen, where
    // the exam token no longer works.
    if (exam.examActive && exam.stage != ExamStage.blocked) return;
    try {
      if (!device.isRegistered) return;
      final state = updates.phase == UpdatePhase.downloading || updates.phase == UpdatePhase.installing
          ? DeviceState.updating
          : DeviceState.idle;
      final r = await device.heartbeat(state);
      connection.reportSuccess();
      updates.reportApiReachable();
      if (r.unlock) await exitApp();
      // Idle PC: pick up Admin changes (background picture, banned list) within a minute.
      if (!exam.examActive) unawaited(_refreshConfig());
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
    // A different server does not know this PC: back to the Setup screen
    // (register there with that center's password, then admin approval).
    await device.forgetRegistration();
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
