import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../../core/config/app_config.dart';
import '../../core/storage/app_paths.dart';
import '../../core/util/semver.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/exam_repository.dart' show verifySha256;

enum UpdatePhase { idle, checking, upToDate, available, downloading, installing, error, unsupported }

/// Runs a downloaded installer and quits the app. Separated for tests.
abstract class InstallerRunner {
  bool get canInstall;
  Future<void> runSilentAndExit(File installer);
}

/// Windows: Inno Setup silent install; the installer's [Run] entry relaunches
/// the app (see installer/mynine.iss).
class ProcessInstallerRunner implements InstallerRunner {
  ProcessInstallerRunner({required this.beforeExit});

  final Future<void> Function() beforeExit;

  static const silentArgs = ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'];

  @override
  bool get canInstall => Platform.isWindows;

  @override
  Future<void> runSilentAndExit(File installer) async {
    await Process.start(installer.path, silentArgs, mode: ProcessStartMode.detached);
    await beforeExit();
    exit(0);
  }
}

/// Persistent update state (`%LOCALAPPDATA%\Mynine\update_state.json`) used
/// by the post-update self-check and rollback.
class UpdateStateData {
  UpdateStateData({
    this.pendingVerify = false,
    this.targetVersion,
    this.fromVersion,
    this.installerPath,
    this.firstLaunchAt,
    this.rolledBackFrom,
  });

  bool pendingVerify;
  String? targetVersion;
  String? fromVersion;
  String? installerPath;
  DateTime? firstLaunchAt;
  String? rolledBackFrom;

  Map<String, Object?> toJson() => {
        'pending_verify': pendingVerify,
        'target_version': targetVersion,
        'from_version': fromVersion,
        'installer_path': installerPath,
        'first_launch_at': firstLaunchAt?.toIso8601String(),
        'rolled_back_from': rolledBackFrom,
      };

  factory UpdateStateData.fromJson(Map<String, Object?> j) => UpdateStateData(
        pendingVerify: j['pending_verify'] == true,
        targetVersion: j['target_version'] as String?,
        fromVersion: j['from_version'] as String?,
        installerPath: j['installer_path'] as String?,
        firstLaunchAt: DateTime.tryParse(j['first_launch_at'] as String? ?? ''),
        rolledBackFrom: j['rolled_back_from'] as String?,
      );
}

/// Self-update from the mynine.uz server.
///
/// * `GET /app/version` on start, every 30 min on the code screen and on the
///   "Check for updates" button.
/// * Automatic downloads wait a random 0–10 min (spreads 20 PCs); manual ones don't.
/// * HTTP Range resume into `updates/`, SHA-256 verify, silent install, relaunch.
/// * The installer of the version being replaced is kept in `previous/`; if the
///   new version does not pass the self-check (API reachable + code screen
///   rendered) within 2 minutes, the previous installer is run again.
class UpdateService extends ChangeNotifier {
  UpdateService({
    required this.api,
    required this.paths,
    required this.currentVersion,
    required this.runner,
    Random? random,
    DateTime Function()? now,
  })  : _random = random ?? Random(),
        _now = now ?? DateTime.now;

  final MynineApi api;
  final AppPaths paths;
  final String currentVersion;
  final InstallerRunner runner;
  final Random _random;
  final DateTime Function() _now;

  UpdatePhase _phase = UpdatePhase.idle;
  ReleaseInfo? _release;
  bool _mandatory = false;
  double _progress = 0;
  String? _error;
  DateTime? _lastCheck;
  Timer? _periodic;
  Timer? _jitterTimer;
  Timer? _selfCheckTimer;
  bool _apiReachable = false;
  bool _codeScreenRendered = false;
  bool _selfCheckPending = false;

  /// Returns true when an automatic install may happen right now
  /// (code screen visible, no exam running).
  bool Function() canAutoInstall = () => false;

  UpdatePhase get phase => _phase;
  ReleaseInfo? get release => _release;
  bool get mandatory => _mandatory;
  double get progress => _progress;
  String? get error => _error;
  DateTime? get lastCheck => _lastCheck;
  bool get busy =>
      _phase == UpdatePhase.checking ||
      _phase == UpdatePhase.downloading ||
      _phase == UpdatePhase.installing;

  void _set(UpdatePhase phase, {String? error}) {
    _phase = phase;
    _error = error;
    notifyListeners();
  }

  // ---- Checking --------------------------------------------------------------

  /// Evaluates a version response. Pure; exposed for tests.
  static ({bool available, bool mandatory}) evaluate(AppVersionInfo info, String current) {
    final latest = info.latest;
    final available = latest != null && isNewerVersion(latest.version, current);
    final mandatory = isBelowMin(current, info.minVersion) ||
        (available && latest.mandatory);
    return (available: available, mandatory: mandatory);
  }

  Future<bool> check({bool manual = false}) async {
    if (busy) return _phase == UpdatePhase.available;
    _set(UpdatePhase.checking);
    try {
      final info = await api.appVersion(current: currentVersion);
      _lastCheck = _now();
      reportApiReachable();
      final r = evaluate(info, currentVersion);
      if (!r.available) {
        _release = null;
        _mandatory = false;
        _set(UpdatePhase.upToDate);
        return false;
      }
      _release = info.latest;
      _mandatory = r.mandatory;
      _set(UpdatePhase.available);
      if (!manual) _scheduleAutoDownload();
      return true;
    } on ApiException catch (e) {
      _set(UpdatePhase.error, error: e.userMessage);
      return false;
    }
  }

  /// Starts periodic checks (code screen). Safe to call repeatedly.
  void startPeriodic() {
    _periodic ??= Timer.periodic(AppConfig.updateCheckInterval, (_) => check());
  }

  void stopPeriodic() {
    _periodic?.cancel();
    _periodic = null;
    _jitterTimer?.cancel();
    _jitterTimer = null;
  }

  Duration randomJitter() => Duration(
        milliseconds: _random.nextInt(AppConfig.updateJitterMax.inMilliseconds + 1),
      );

  void _scheduleAutoDownload() {
    if (_jitterTimer != null) return;
    final delay = randomJitter();
    debugPrint('Update ${_release?.version} found; auto-download in $delay');
    _jitterTimer = Timer(delay, () async {
      _jitterTimer = null;
      final file = await download();
      if (file != null && canAutoInstall()) await install(file);
    });
  }

  // ---- Download ----------------------------------------------------------------

  File installerFile(String version) =>
      File(p.join(paths.updates.path, 'mynine-setup-$version.exe'));

  /// Downloads (with resume) and verifies the available release.
  Future<File?> download() async {
    final release = _release;
    if (release == null) return null;
    final file = installerFile(release.version);
    try {
      if (await file.exists() && await verifySha256(file, release.sha256)) {
        return file;
      }
      _progress = 0;
      _set(UpdatePhase.downloading);
      await api.download(release.url, file, onProgress: (r, t) {
        final total = t > 0 ? t : release.size;
        _progress = total > 0 ? (r / total).clamp(0.0, 1.0) : 0;
        notifyListeners();
      });
      if (!await verifySha256(file, release.sha256)) {
        await file.delete();
        _set(UpdatePhase.error, error: 'The downloaded update is corrupted. Please try again.');
        return null;
      }
      _set(UpdatePhase.available);
      return file;
    } on ApiException catch (e) {
      _set(UpdatePhase.error, error: e.userMessage);
      return null;
    } on FileSystemException catch (e) {
      _set(UpdatePhase.error, error: 'Cannot write the update: ${e.message}');
      return null;
    }
  }

  // ---- Install -------------------------------------------------------------------

  /// Keeps the installer of the running version in `previous/` (downloading
  /// it from the server if needed) so a failed update can be rolled back.
  Future<void> ensurePreviousInstaller() async {
    final target = File(p.join(paths.previous.path, 'mynine-setup-$currentVersion.exe'));
    if (await target.exists()) return;
    final release = _release;
    if (release == null) return;
    final url = release.url.replaceFirst(
      '/releases/${release.version}/',
      '/releases/$currentVersion/',
    );
    if (url == release.url) return;
    try {
      await api.download(url, target);
    } on ApiException catch (e) {
      debugPrint('No previous installer for rollback: $e');
    }
  }

  Future<void> install(File installer) async {
    final release = _release;
    if (release == null) return;
    if (!runner.canInstall) {
      _set(UpdatePhase.unsupported,
          error: 'Installing updates is only supported on Windows.');
      return;
    }
    _set(UpdatePhase.installing);
    await ensurePreviousInstaller();
    await writeState(UpdateStateData(
      pendingVerify: true,
      targetVersion: release.version,
      fromVersion: currentVersion,
      installerPath: installer.path,
    ));
    await runner.runSilentAndExit(installer);
  }

  // ---- Post-update self-check and rollback -------------------------------------

  Future<UpdateStateData?> readState() async {
    try {
      final f = paths.updateStateFile;
      if (!await f.exists()) return null;
      return UpdateStateData.fromJson(
          (jsonDecode(await f.readAsString()) as Map).cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<void> writeState(UpdateStateData? s) async {
    final f = paths.updateStateFile;
    if (s == null) {
      if (await f.exists()) await f.delete();
      return;
    }
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode(s.toJson()));
  }

  /// Call once on startup.
  Future<void> startupSelfCheck() async {
    final s = await readState();
    if (s == null || !s.pendingVerify) return;
    if (s.targetVersion != currentVersion) {
      // The install did not happen (or we are the rolled-back version).
      debugPrint('Update to ${s.targetVersion} not active (running $currentVersion).');
      await writeState(null);
      return;
    }
    final now = _now();
    if (s.firstLaunchAt != null &&
        now.difference(s.firstLaunchAt!) > AppConfig.updateSelfCheckWindow) {
      // A previous launch of this version never passed the self-check.
      await rollback(s);
      return;
    }
    s.firstLaunchAt ??= now;
    await writeState(s);
    _selfCheckPending = true;
    final remaining = AppConfig.updateSelfCheckWindow - now.difference(s.firstLaunchAt!);
    _selfCheckTimer = Timer(remaining.isNegative ? Duration.zero : remaining, () async {
      if (_selfCheckPending) await rollback(s);
    });
    _maybeVerified();
  }

  void reportApiReachable() {
    _apiReachable = true;
    _maybeVerified();
  }

  void reportCodeScreenRendered() {
    _codeScreenRendered = true;
    _maybeVerified();
  }

  Future<void> _maybeVerified() async {
    if (!_selfCheckPending || !_apiReachable || !_codeScreenRendered) return;
    _selfCheckPending = false;
    _selfCheckTimer?.cancel();
    final s = await readState();
    // Keep the verified installer as the rollback target for the next update.
    if (s?.installerPath != null) {
      final installer = File(s!.installerPath!);
      if (await installer.exists()) {
        await paths.previous.create(recursive: true);
        await for (final old in paths.previous.list()) {
          if (old is File) await old.delete();
        }
        await installer.copy(p.join(paths.previous.path, 'mynine-setup-$currentVersion.exe'));
        await installer.delete();
      }
    }
    await writeState(null);
    debugPrint('Update self-check passed for $currentVersion');
  }

  Future<void> rollback(UpdateStateData s) async {
    _selfCheckPending = false;
    final from = s.fromVersion;
    final prev = from == null
        ? null
        : File(p.join(paths.previous.path, 'mynine-setup-$from.exe'));
    await writeState(UpdateStateData(rolledBackFrom: currentVersion));
    if (prev == null || !await prev.exists() || !runner.canInstall) {
      debugPrint('Self-check failed but no previous installer is available.');
      return;
    }
    debugPrint('Self-check failed: rolling back to $from');
    await runner.runSilentAndExit(prev);
  }

  @override
  void dispose() {
    stopPeriodic();
    _selfCheckTimer?.cancel();
    super.dispose();
  }
}
