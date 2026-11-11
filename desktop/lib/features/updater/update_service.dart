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
    this.runMs = 0,
  });

  bool pendingVerify;
  String? targetVersion;
  String? fromVersion;
  String? installerPath;

  /// Informational: when the new version first started.
  DateTime? firstLaunchAt;

  /// The version that failed its self-check and was rolled back; it is not
  /// installed automatically again (a newer one is).
  String? rolledBackFrom;

  /// How long the new version has been running without passing the
  /// self-check (only time while the app runs counts).
  int runMs;

  Map<String, Object?> toJson() => {
        'pending_verify': pendingVerify,
        'target_version': targetVersion,
        'from_version': fromVersion,
        'installer_path': installerPath,
        'first_launch_at': firstLaunchAt?.toIso8601String(),
        'rolled_back_from': rolledBackFrom,
        'run_ms': runMs,
      };

  factory UpdateStateData.fromJson(Map<String, Object?> j) => UpdateStateData(
        pendingVerify: j['pending_verify'] == true,
        targetVersion: j['target_version'] as String?,
        fromVersion: j['from_version'] as String?,
        installerPath: j['installer_path'] as String?,
        firstLaunchAt: DateTime.tryParse(j['first_launch_at'] as String? ?? ''),
        rolledBackFrom: j['rolled_back_from'] as String?,
        runMs: (j['run_ms'] as num?)?.toInt() ?? 0,
      );
}

/// Self-update from the mynine.uz server's static folder `<site>/desktop/`
/// (nginx serves the server's `public/desktop/`).
///
/// * `GET <site>/desktop/version.json?t=<epoch>` on start, every 30 min on the
///   code screen and on the "Check for updates" button. A missing, invalid or
///   incomplete manifest (empty sha256, size 0, no file) means "no update" —
///   never an error that could block the exam.
/// * The installer is `<site>/desktop/<file>`; size and SHA-256 are verified.
/// * Automatic downloads wait a random 0–10 min (spreads 20 PCs); manual ones don't.
/// * HTTP Range resume into `updates/`, SHA-256 verify, silent install, relaunch.
/// * The installer of the version being replaced is kept in `previous/`; if the
///   new version does not pass the self-check (any successful API response +
///   the UI rendered) within 2 minutes of running time, the previous
///   installer is run again, and that version is not installed automatically
///   again until a newer one is published.
/// * Never installs, rolls back or exits while an exam session is active or
///   a login is in progress ([canAutoInstall], [isExamSessionActive] and
///   [hasUnfinishedSession] are checked right before the installer starts).
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
  UpdateManifest? _release;
  bool _mandatory = false;
  double _progress = 0;
  String? _error;
  DateTime? _lastCheck;
  Timer? _periodic;
  Timer? _jitterTimer;
  Timer? _selfCheckTimer;
  Timer? _rollbackRetry;
  final Stopwatch _runClock = Stopwatch();
  int _runBaseMs = 0;
  UpdateStateData? _selfCheckState;
  bool _apiReachable = false;
  bool _codeScreenRendered = false;
  bool _selfCheckPending = false;
  bool _skippedRolledBack = false;

  /// Returns true when an automatic install may happen right now
  /// (code screen visible, no exam running).
  bool Function() canAutoInstall = () => false;

  /// True while a candidate's exam session is open in the app (any stage
  /// after login, or a login in progress).
  bool Function() isExamSessionActive = () => false;

  /// True when the database holds an unfinished exam session (it is resumed
  /// right after the start, before the UI reports it).
  Future<bool> Function() hasUnfinishedSession = () async => false;

  /// The available release is the version that was rolled back on this PC:
  /// it is offered for a manual install only.
  bool get skippedRolledBack => _skippedRolledBack;

  /// Whether the app may be replaced / exited right now.
  Future<bool> safeToInterrupt() async {
    if (isExamSessionActive()) return false;
    try {
      return !await hasUnfinishedSession();
    } catch (_) {
      return false;
    }
  }

  UpdatePhase get phase => _phase;
  UpdateManifest? get release => _release;
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

  /// Evaluates a manifest against the running version. Pure; exposed for tests.
  ///
  /// An update is available only for a complete manifest (file, sha256, size)
  /// whose version is higher than [current]. It is mandatory when the
  /// manifest says so or [current] is below `min_version`.
  static ({bool available, bool mandatory}) evaluate(UpdateManifest? manifest, String current) {
    if (manifest == null || !manifest.isComplete) {
      return (available: false, mandatory: false);
    }
    final available = isNewerVersion(manifest.version, current);
    final mandatory =
        available && (manifest.mandatory || isBelowMin(current, manifest.minVersion));
    return (available: available, mandatory: mandatory);
  }

  Future<bool> check({bool manual = false}) async {
    if (busy) return _phase == UpdatePhase.available;
    _set(UpdatePhase.checking);
    UpdateManifest? manifest;
    try {
      manifest = await api.updateManifest();
      _lastCheck = _now();
      reportApiReachable();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // version.json not published yet: nothing to install.
        _lastCheck = _now();
        reportApiReachable();
        manifest = null;
      } else {
        _set(UpdatePhase.error, error: e.userMessage);
        return false;
      }
    } on FormatException catch (e) {
      debugPrint('Invalid version.json: $e');
      manifest = null;
    }
    final r = evaluate(manifest, currentVersion);
    if (!r.available) {
      _release = null;
      _mandatory = false;
      _set(UpdatePhase.upToDate);
      return false;
    }
    _release = manifest;
    _mandatory = r.mandatory;
    final rolledBack = (await readState())?.rolledBackFrom;
    _skippedRolledBack = rolledBack != null && rolledBack == manifest!.version;
    _set(UpdatePhase.available);
    if (!manual && !_skippedRolledBack) _scheduleAutoDownload();
    return true;
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
      if (file != null && canAutoInstall()) await install(file, auto: true);
    });
  }

  // ---- Download ----------------------------------------------------------------

  File installerFile(String version) =>
      File(p.join(paths.updates.path, 'mynine-setup-$version.exe'));

  Future<bool> _verify(File file, UpdateManifest release) async =>
      release.isComplete &&
      await file.exists() &&
      await file.length() == release.size &&
      await verifySha256(file, release.sha256);

  /// Downloads (with resume) and verifies (size + SHA-256) the available release.
  Future<File?> download() async {
    final release = _release;
    if (release == null || !release.isComplete) return null;
    final file = installerFile(release.version);
    try {
      if (await _verify(file, release)) return file;
      if (await file.exists()) await file.delete();
      _progress = 0;
      _set(UpdatePhase.downloading);
      await api.download(api.updateFileUrl(release.file), file, anonymous: true, onProgress: (r, t) {
        final total = t > 0 ? t : release.size;
        _progress = total > 0 ? (r / total).clamp(0.0, 1.0) : 0;
        notifyListeners();
      });
      if (!await _verify(file, release)) {
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

  /// Keeps the installer of the running version in `previous/` so a failed
  /// update can be rolled back. If it is not there yet it is downloaded from
  /// `<site>/desktop/mynine-setup-<currentVersion>.exe` — old installers must
  /// therefore stay in the server's `public/desktop/` folder. There is no
  /// checksum for it; a missing file just means no rollback is possible.
  Future<void> ensurePreviousInstaller() async {
    final name = 'mynine-setup-$currentVersion.exe';
    final target = File(p.join(paths.previous.path, name));
    if (await target.exists() && await target.length() > 0) return;
    try {
      await api.download(api.updateFileUrl(name), target, anonymous: true);
      if (await target.length() == 0) await target.delete();
    } on ApiException catch (e) {
      debugPrint('No previous installer for rollback: $e');
    } on FileSystemException catch (e) {
      debugPrint('Cannot store the previous installer: $e');
    }
  }

  /// Installs [installer] and exits. With [auto] (background update) the
  /// install is abandoned when [canAutoInstall] no longer holds right before
  /// the installer starts; any install is abandoned while an exam session is
  /// active. Returns false when nothing was started.
  Future<bool> install(File installer, {bool auto = false}) async {
    final release = _release;
    if (release == null) return false;
    if (!runner.canInstall) {
      _set(UpdatePhase.unsupported,
          error: 'Installing updates is only supported on Windows.');
      return false;
    }
    if ((auto && !canAutoInstall()) || !await safeToInterrupt()) return false;
    _set(UpdatePhase.installing);
    await ensurePreviousInstaller();
    final previousState = await readState();
    await writeState(UpdateStateData(
      pendingVerify: true,
      targetVersion: release.version,
      fromVersion: currentVersion,
      installerPath: installer.path,
      rolledBackFrom: previousState?.rolledBackFrom,
    ));
    // Re-check right before the app goes away (a login may have started
    // while the previous installer was downloaded).
    if ((auto && !canAutoInstall()) || !await safeToInterrupt()) {
      await writeState(previousState);
      _set(UpdatePhase.available);
      return false;
    }
    await runner.runSilentAndExit(installer);
    return true;
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

  /// Call once on startup. The self-check window counts only while the app
  /// runs (the time is persisted every few seconds), so a PC switched off
  /// right after an update is not rolled back the next morning.
  Future<void> startupSelfCheck() async {
    final s = await readState();
    if (s == null || !s.pendingVerify) return;
    if (s.targetVersion != currentVersion) {
      // The install did not happen (or we are the rolled-back version).
      debugPrint('Update to ${s.targetVersion} not active (running $currentVersion).');
      await writeState(s.rolledBackFrom == null ? null : UpdateStateData(rolledBackFrom: s.rolledBackFrom));
      return;
    }
    final window = AppConfig.updateSelfCheckWindow.inMilliseconds;
    if (s.runMs >= window) {
      // A previous run of this version never passed the self-check.
      await _rollbackWhenSafe(s);
      return;
    }
    s.firstLaunchAt ??= _now();
    await writeState(s);
    _selfCheckState = s;
    _selfCheckPending = true;
    _runBaseMs = s.runMs;
    _runClock
      ..reset()
      ..start();
    _selfCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_selfCheckTick()));
    _maybeVerified();
  }

  /// Running time of this version without a passed self-check.
  int get selfCheckRunMs => _runBaseMs + _runClock.elapsedMilliseconds;

  Future<void> _selfCheckTick() async {
    final s = _selfCheckState;
    if (!_selfCheckPending || s == null) {
      _selfCheckTimer?.cancel();
      return;
    }
    s.runMs = selfCheckRunMs;
    await writeState(s);
    if (s.runMs >= AppConfig.updateSelfCheckWindow.inMilliseconds) {
      _selfCheckTimer?.cancel();
      await _rollbackWhenSafe(s);
    }
  }

  void reportApiReachable() {
    _apiReachable = true;
    _maybeVerified();
  }

  void reportCodeScreenRendered() {
    _codeScreenRendered = true;
    _maybeVerified();
  }

  /// Any screen of the app was rendered (the self-check does not require
  /// the code screen: an exam may be resumed first).
  void reportUiRendered() => reportCodeScreenRendered();

  Future<void> _maybeVerified() async {
    if (!_selfCheckPending || !_apiReachable || !_codeScreenRendered) return;
    _selfCheckPending = false;
    _selfCheckTimer?.cancel();
    _rollbackRetry?.cancel();
    _runClock.stop();
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

  /// Rolls back as soon as no exam session is active (checked again every
  /// 30 s). A self-check that passes meanwhile cancels the rollback.
  Future<void> _rollbackWhenSafe(UpdateStateData s) async {
    _selfCheckPending = true;
    _rollbackRetry?.cancel();
    if (await safeToInterrupt()) {
      await rollback(s);
      return;
    }
    debugPrint('Self-check failed; rollback waits for the exam session to end.');
    _rollbackRetry = Timer(const Duration(seconds: 30), () {
      if (_selfCheckPending) unawaited(_rollbackWhenSafe(s));
    });
  }

  Future<void> rollback(UpdateStateData s) async {
    if (!await safeToInterrupt()) {
      await _rollbackWhenSafe(s);
      return;
    }
    _selfCheckPending = false;
    _selfCheckTimer?.cancel();
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
    _rollbackRetry?.cancel();
    super.dispose();
  }
}
