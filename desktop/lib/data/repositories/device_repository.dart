import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../../core/crypto/pbkdf2.dart';
import '../../core/storage/settings_store.dart';
import '../../platform/lockdown/lockdown.dart';
import '../models/app_models.dart';
import 'exam_repository.dart' show verifySha256;

/// Result of a center-password check.
enum ExitPasswordCheck {
  ok,
  wrong,

  /// 403 `device_blocked` and no offline hash on this PC.
  blocked,

  /// 403 `device_not_approved` and no offline hash on this PC.
  notApproved,

  /// 429: too many attempts.
  tooManyAttempts;

  /// Text for the password dialog (null for [ok]).
  String? get message => switch (this) {
        ok => null,
        wrong => 'Incorrect password.',
        blocked => 'This PC is blocked on the server — unblock it in Exam PCs.',
        notApproved => 'This PC is waiting for approval in Exam PCs.',
        tooManyAttempts => 'Too many attempts, wait a minute.',
      };
}

/// Device identity, registration, config cache and exit-password checks.
class DeviceRepository extends ChangeNotifier {
  DeviceRepository({
    required this.api,
    required this.store,
    required this.credentials,
    required this.lockdown,
    required this.appVersion,
    this.backgroundDir,
  });

  /// Where the code-screen background picture and the center logo are kept
  /// (null: feature off).
  final Directory? backgroundDir;
  File? _background;
  File? _logo;

  /// The Admin's background picture for the code screen, once on disk.
  File? get backgroundFile => _background;

  /// The center logo for the code screen, once on disk (null: name only).
  File? get logoFile => _logo;

  /// Brand name used where the app used to say "Mynine".
  static const defaultCenterName = 'Mynine';

  final MynineApi api;
  final SettingsStore store;
  final DeviceCredentials credentials;
  final Lockdown lockdown;
  final String appVersion;

  String? _machineId;
  String? _pcName;
  int? _pcNumber;
  DeviceConfig _config = const DeviceConfig();
  bool _registered = false;
  bool _blocked = false;
  String? _notApprovedMessage;
  String? _lastCenterCode;
  bool _suspendedByLogin = false;

  DeviceConfig get config => _config;

  /// The PC's learning center (null until a multi-center server told us).
  CenterInfo? get center => _config.center;

  /// The center's name, or "Mynine" (older server / no name).
  String get centerName {
    final name = _config.center?.name.trim() ?? '';
    return name.isEmpty ? defaultCenterName : name;
  }

  /// True when the center is suspended (config, or a login answered
  /// `center_suspended`): the code screen does not start exams.
  bool get centerSuspended => _suspendedByLogin || (_config.center?.suspended ?? false);

  /// Last center code used to register (prefills the Setup / admin forms).
  String? get lastCenterCode => _lastCenterCode;

  /// Records a `center_suspended` answer from `/exam/login`, or (false)
  /// clears it after a successful login.
  void noteCenterSuspended(bool suspended) {
    if (_suspendedByLogin == suspended) return;
    _suspendedByLogin = suspended;
    notifyListeners();
  }
  String get pcName => _pcName ?? Platform.localHostname;
  String? get machineId => _machineId;

  /// Short machine id for screens ("…3F2A"), or '-' when unknown.
  String get machineIdShort {
    final id = (_machineId ?? '').replaceAll(RegExp('[{}]'), '');
    if (id.isEmpty) return '-';
    return id.length <= 8 ? id.toUpperCase() : '…${id.substring(id.length - 8).toUpperCase()}';
  }

  /// Exam-room number given by the Admin on approval ("PC 7"); null until approved.
  int? get pcNumber => _pcNumber;

  /// True once this PC holds a device token (registered with the center password).
  bool get isRegistered => _registered;
  bool get isBlocked => _blocked;

  /// Set while the PC is registered but not (yet / any more) approved by an
  /// Admin. Holds the message shown on the waiting screen.
  String? get notApprovedMessage => _notApprovedMessage;
  bool get isApprovalPending => _registered && _notApprovedMessage != null;

  static String waitingMessage(String name) => 'This PC is waiting for administrator approval: $name';

  Future<void> load() async {
    credentials.deviceToken = await store.read(SettingsKeys.deviceToken);
    _registered = credentials.deviceToken != null;
    _pcName = await store.read(SettingsKeys.pcName);
    _pcNumber = int.tryParse(await store.read(SettingsKeys.pcNumber) ?? '');
    if (_registered && await store.read(SettingsKeys.deviceApproved) == '0') {
      _notApprovedMessage = waitingMessage(pcName);
    }
    final cfg = await store.read(SettingsKeys.deviceConfig);
    if (cfg != null) {
      try {
        _config = DeviceConfig.fromJson((jsonDecode(cfg) as Map).cast<String, Object?>());
      } catch (_) {}
    }
    _lastCenterCode = await store.read(SettingsKeys.centerCode);
    final cachedBg = _backgroundTarget();
    if (cachedBg != null && cachedBg.existsSync()) _background = cachedBg;
    final cachedLogo = _logoTarget();
    if (cachedLogo != null && cachedLogo.existsSync()) _logo = cachedLogo;
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

  /// Registers this PC with the center [password] (Setup screen, or
  /// "Re-register" in the admin menu). Never called automatically: a new
  /// registration rotates the token and drops the admin approval.
  ///
  /// Throws [ApiException] `invalid_password` / `setup_password_missing` /
  /// `device_blocked` / `invalid_center_code` / `center_suspended` / network
  /// errors; the stored token is kept on failure. [centerCode] (empty: the
  /// Mynine center) is remembered after a successful registration.
  Future<void> register({String? centerCode, required String password, String? name}) async {
    final code = centerCode?.trim().toUpperCase() ?? '';
    try {
      final r = await api.registerDevice(
        machineId: _machineId!,
        centerCode: code.isEmpty ? null : code,
        password: password,
        name: (name?.trim().isNotEmpty ?? false) ? name!.trim() : null,
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
      _lastCenterCode = code.isEmpty ? null : code;
      await store.write(SettingsKeys.centerCode, _lastCenterCode);
      // Another center's branding must not stay on screen: take the new one
      // (or none from an older server) until /device/config confirms it.
      if (r.center != _config.center) {
        _config = _config.copyWith(center: r.center);
        _suspendedByLogin = false;
        await store.write(SettingsKeys.deviceConfig, jsonEncode(_config.toJson()));
        unawaited(syncLogo());
      }
      // The offline hash comes with the registration (newer servers): the
      // exit password then works even while the PC is not approved / blocked.
      final hash = r.exitPasswordOffline;
      if (hash != null && hash.isNotEmpty && hash != _config.exitPasswordOffline) {
        _config = _config.copyWith(exitPasswordOffline: hash);
        await store.write(SettingsKeys.deviceConfig, jsonEncode(_config.toJson()));
      }
      await _setApproval(approved: r.approved, number: r.number);
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.deviceBlocked) _blocked = true;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Forgets the device token (the server no longer knows it): the app shows
  /// the Setup screen again and staff registers the PC with the center password.
  Future<void> forgetRegistration() async {
    credentials.deviceToken = null;
    _registered = false;
    _notApprovedMessage = null;
    await store.write(SettingsKeys.deviceToken, null);
    notifyListeners();
  }

  Future<void> refreshConfig() async {
    try {
      _config = await api.deviceConfig();
      await store.write(SettingsKeys.deviceConfig, jsonEncode(_config.toJson()));
      unawaited(syncBackground());
      unawaited(syncLogo());
      _blocked = false;
      if (!(_config.center?.suspended ?? false)) _suspendedByLogin = false;
      _applyIdentity(name: _config.name, number: _config.number, approved: _config.approved ?? true);
      notifyListeners();
    } on ApiException catch (e) {
      await _handleAuthError(e);
      rethrow;
    }
  }

  Future<DeviceHeartbeat> heartbeat(DeviceState state) async {
    try {
      final r = await api.deviceHeartbeat(appVersion: appVersion, state: state);
      _blocked = false;
      _applyIdentity(name: r.name, number: r.number, approved: r.approved);
      notifyListeners();
      return r;
    } on ApiException catch (e) {
      await _handleAuthError(e);
      rethrow;
    }
  }

  /// Name / number / approval as reported by the server (heartbeat, config).
  /// A null field (older server) leaves the current value.
  void _applyIdentity({String? name, int? number, bool? approved}) {
    if (name != null && name.isNotEmpty && name != _pcName) {
      _pcName = name;
      unawaited(store.write(SettingsKeys.pcName, name));
    }
    if (approved != null) unawaited(_setApproval(approved: approved, number: number));
  }

  Future<void> _setApproval({required bool approved, int? number}) async {
    if (approved) {
      _notApprovedMessage = null;
      if (number != null && number != _pcNumber) {
        _pcNumber = number;
        await store.write(SettingsKeys.pcNumber, '$number');
      }
    } else {
      _notApprovedMessage ??= waitingMessage(pcName);
    }
    await store.write(SettingsKeys.deviceApproved, approved ? '1' : '0');
  }

  /// Records the approval state from any device/exam response error.
  void noteApproval(ApiException e) {
    if (e.code == ApiErrorCode.deviceNotApproved) {
      _notApprovedMessage = e.message?.isNotEmpty == true ? e.message : waitingMessage(pcName);
      unawaited(store.write(SettingsKeys.deviceApproved, '0'));
      notifyListeners();
    }
  }

  void markApproved() {
    if (_notApprovedMessage != null) {
      _notApprovedMessage = null;
      unawaited(store.write(SettingsKeys.deviceApproved, '1'));
      notifyListeners();
    }
  }

  Future<void> _handleAuthError(ApiException e) async {
    noteApproval(e);
    if (e.code == ApiErrorCode.deviceBlocked) {
      _blocked = true;
      notifyListeners();
    } else if (e.code == ApiErrorCode.unauthenticated) {
      // Token rotated or the PC was deleted on the server: back to Setup
      // (registering needs the center password, never automatic).
      await forgetRegistration();
    }
  }

  /// Verifies the center password: online first, then offline against
  /// the cached PBKDF2 hash when the server is unreachable.
  Future<bool> verifyExitPassword(String password) async =>
      await checkExitPassword(password) == ExitPasswordCheck.ok;

  /// Like [verifyExitPassword], with the reason of a refusal. A PC the
  /// server blocked / has not approved is checked against the offline hash;
  /// without one the result says why instead of "incorrect password".
  Future<ExitPasswordCheck> checkExitPassword(String password) async {
    if (password.isEmpty) return ExitPasswordCheck.wrong;
    ExitPasswordCheck? refusedBy;
    if (_registered) {
      try {
        return await api.deviceUnlock(password) ? ExitPasswordCheck.ok : ExitPasswordCheck.wrong;
      } on ApiException catch (e) {
        if (e.code == ApiErrorCode.invalidPassword) return ExitPasswordCheck.wrong;
        if (e.code == ApiErrorCode.tooManyRequests || e.statusCode == 429) {
          return ExitPasswordCheck.tooManyAttempts;
        }
        if (e.code == ApiErrorCode.deviceBlocked) {
          _blocked = true;
          refusedBy = ExitPasswordCheck.blocked;
        } else if (e.code == ApiErrorCode.deviceNotApproved) {
          refusedBy = ExitPasswordCheck.notApproved;
        }
        // Network / server problems (and a refused PC): offline hash below.
      }
    }
    final hash = _config.exitPasswordOffline;
    if (hash == null || hash.isEmpty) return refusedBy ?? ExitPasswordCheck.wrong;
    return await compute(_verifyOffline, [password, hash]) ? ExitPasswordCheck.ok : ExitPasswordCheck.wrong;
  }

  static bool _verifyOffline(List<String> args) => verifyPbkdf2Password(args[0], args[1]);

  File? _backgroundTarget() {
    final dir = backgroundDir;
    final sha = _config.backgroundSha256;
    if (dir == null || _config.backgroundUrl == null || sha == null || sha.length < 12) return null;
    return File(p.join(dir.path, 'background-${sha.substring(0, 12)}.img'));
  }

  Future<void>? _backgroundJob;

  /// Downloads the background picture named in the config (hash-checked),
  /// or drops it when the Admin removed it. Old pictures are deleted.
  /// A call during a running sync waits for that one.
  Future<void> syncBackground() =>
      _backgroundJob ??= _syncBackground().whenComplete(() => _backgroundJob = null);

  Future<void> _syncBackground() async {
    final dir = backgroundDir;
    if (dir == null) return;
    try {
      final target = _backgroundTarget();
      if (target != null && !(target.existsSync() && await verifySha256(target, _config.backgroundSha256))) {
        await dir.create(recursive: true);
        await api.download(_config.backgroundUrl!, target);
        if (!await verifySha256(target, _config.backgroundSha256)) {
          await target.delete();
          return;
        }
      }
      if (_background?.path != target?.path) {
        _background = target;
        notifyListeners();
      }
      await for (final f in dir.list()) {
        final name = p.basename(f.path);
        if (f is File && name.startsWith('background-') && f.path != target?.path) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Background picture not updated: $e');
    }
  }

  File? _logoTarget() {
    final dir = backgroundDir;
    final url = _config.center?.logoUrl;
    if (dir == null || url == null || url.isEmpty || !api.isApiUrl(url)) return null;
    final key = crypto.sha256.convert(utf8.encode(url)).toString().substring(0, 16);
    return File(p.join(dir.path, 'logo-$key.img'));
  }

  Future<void>? _logoJob;

  /// Downloads the center logo named in the config (only from the API
  /// server; keyed by its URL), or drops it when the center has none.
  /// Old logos are deleted.
  Future<void> syncLogo() => _logoJob ??= _syncLogo().whenComplete(() => _logoJob = null);

  Future<void> _syncLogo() async {
    final dir = backgroundDir;
    if (dir == null) return;
    try {
      final target = _logoTarget();
      if (target != null && !(target.existsSync() && target.lengthSync() > 0)) {
        await dir.create(recursive: true);
        await api.download(_config.center!.logoUrl!, target);
      }
      if (_logo?.path != target?.path) {
        _logo = target;
        notifyListeners();
      }
      if (!dir.existsSync()) return;
      await for (final f in dir.list()) {
        final name = p.basename(f.path);
        if (f is File && name.startsWith('logo-') && f.path != target?.path) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Center logo not updated: $e');
    }
  }

  static String osVersionString() {
    final v = Platform.operatingSystemVersion;
    return '${Platform.operatingSystem} $v'.trim();
  }
}
