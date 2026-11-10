import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../../core/crypto/pbkdf2.dart';
import '../../core/storage/settings_store.dart';
import '../../platform/lockdown/lockdown.dart';
import '../models/app_models.dart';

/// Device identity, registration, config cache and exit-password checks.
class DeviceRepository extends ChangeNotifier {
  DeviceRepository({
    required this.api,
    required this.store,
    required this.credentials,
    required this.lockdown,
    required this.appVersion,
  });

  final MynineApi api;
  final SettingsStore store;
  final DeviceCredentials credentials;
  final Lockdown lockdown;
  final String appVersion;

  String? _machineId;
  String? _pcName;
  DeviceConfig _config = const DeviceConfig();
  bool _registered = false;
  bool _blocked = false;
  String? _notApprovedMessage;

  DeviceConfig get config => _config;
  String get pcName => _pcName ?? Platform.localHostname;
  String? get machineId => _machineId;
  bool get isRegistered => _registered;
  bool get isBlocked => _blocked;

  /// Set while the server answers 403 `device_not_approved` (new PC that an
  /// Admin has not approved yet). Holds the server message (names the PC).
  String? get notApprovedMessage => _notApprovedMessage;
  bool get isApprovalPending => _notApprovedMessage != null;

  Future<void> load() async {
    credentials.deviceToken = await store.read(SettingsKeys.deviceToken);
    _registered = credentials.deviceToken != null;
    _pcName = await store.read(SettingsKeys.pcName);
    final cfg = await store.read(SettingsKeys.deviceConfig);
    if (cfg != null) {
      try {
        _config = DeviceConfig.fromJson((jsonDecode(cfg) as Map).cast<String, Object?>());
      } catch (_) {}
    }
    _machineId = await lockdown.machineId();
    if (_machineId == null || _machineId!.isEmpty) {
      _machineId = await store.read(SettingsKeys.machineIdFallback);
      if (_machineId == null) {
        _machineId = const Uuid().v4();
        await store.write(SettingsKeys.machineIdFallback, _machineId);
      }
    }
    notifyListeners();
  }

  /// Registers this PC. Called once on first run; afterwards only when the
  /// server rejects the device token with 401 or when staff explicitly asks
  /// for it (re-registering rotates the token AND drops the admin approval).
  Future<void> register({bool force = false}) async {
    if (_registered && !force) return;
    try {
      final r = await api.registerDevice(
        machineId: _machineId!,
        name: pcName,
        osVersion: osVersionString(),
        appVersion: appVersion,
      );
      credentials.deviceToken = r.deviceToken;
      await store.write(SettingsKeys.deviceToken, r.deviceToken);
      await store.write(SettingsKeys.deviceId, '${r.deviceId}');
      _pcName = r.name;
      await store.write(SettingsKeys.pcName, r.name);
      _registered = true;
      _blocked = false;
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.deviceBlocked) _blocked = true;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshConfig() async {
    try {
      _config = await api.deviceConfig();
      await store.write(SettingsKeys.deviceConfig, jsonEncode(_config.toJson()));
      _blocked = false;
      _notApprovedMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      await _handleAuthError(e);
      rethrow;
    }
  }

  Future<DeviceHeartbeat> heartbeat(DeviceState state) async {
    try {
      final r = await api.deviceHeartbeat(appVersion: appVersion, state: state);
      if (_blocked) {
        _blocked = false;
        notifyListeners();
      }
      return r;
    } on ApiException catch (e) {
      await _handleAuthError(e);
      rethrow;
    }
  }

  /// Records the approval state from any device/exam response error.
  void noteApproval(ApiException e) {
    if (e.code == ApiErrorCode.deviceNotApproved) {
      final name = pcName;
      _notApprovedMessage = e.message?.isNotEmpty == true
          ? e.message
          : 'This PC is waiting for administrator approval: $name';
      notifyListeners();
    }
  }

  void markApproved() {
    if (_notApprovedMessage != null) {
      _notApprovedMessage = null;
      notifyListeners();
    }
  }

  Future<void> _handleAuthError(ApiException e) async {
    noteApproval(e);
    if (e.code == ApiErrorCode.deviceBlocked) {
      _blocked = true;
      notifyListeners();
    } else if (e.code == ApiErrorCode.unauthenticated) {
      // Token rotated or deleted on the server: register again.
      await register(force: true);
    }
  }

  /// Saves the PC name. When [reRegister] is true the device registers again
  /// so the server learns the new name — this drops the admin approval.
  Future<void> setPcName(String name, {bool reRegister = false}) async {
    _pcName = name.trim();
    await store.write(SettingsKeys.pcName, _pcName);
    notifyListeners();
    if (reRegister) await register(force: true);
  }

  /// Verifies the center exit password: online first, then offline against
  /// the cached PBKDF2 hash when the server is unreachable.
  Future<bool> verifyExitPassword(String password) async {
    if (password.isEmpty) return false;
    if (_registered) {
      try {
        return await api.deviceUnlock(password);
      } on ApiException catch (e) {
        if (e.code == ApiErrorCode.invalidPassword) return false;
        if (e.code == ApiErrorCode.tooManyRequests || e.statusCode == 429) return false;
        // Network / server problems: fall back to the offline hash below.
      }
    }
    final hash = _config.exitPasswordOffline;
    if (hash == null) return false;
    return compute(_verifyOffline, [password, hash]);
  }

  static bool _verifyOffline(List<String> args) => verifyPbkdf2Password(args[0], args[1]);

  static String osVersionString() {
    final v = Platform.operatingSystemVersion;
    return '${Platform.operatingSystem} $v'.trim();
  }
}
