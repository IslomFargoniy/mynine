import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/config/app_config.dart';
import 'package:mynine_desktop/core/storage/app_paths.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/data/models/app_models.dart';
import 'package:mynine_desktop/data/repositories/exam_repository.dart';
import 'package:mynine_desktop/features/updater/update_service.dart';
import 'package:path/path.dart' as p;

class RecordingRunner implements InstallerRunner {
  final List<String> ran = [];
  @override
  bool get canInstall => true;
  @override
  Future<void> runSilentAndExit(File installer) async => ran.add(p.basename(installer.path));
}

/// Fake whose release checksum / size can be corrupted.
class TamperApi extends FakeMynineApi {
  TamperApi() : super(clock: ServerClock(), latency: Duration.zero, offerUpdate: true);
  bool badSha = false;
  bool badSize = false;

  @override
  Future<UpdateManifest> updateManifest() async {
    final m = await super.updateManifest();
    if (badSha) return m.copyWith(sha256: '0' * 64);
    if (badSize) return m.copyWith(size: m.size + 1);
    return m;
  }
}

/// Fake whose `version.json` body cannot be parsed.
class BrokenManifestApi extends FakeMynineApi {
  BrokenManifestApi() : super(clock: ServerClock(), latency: Duration.zero, offerUpdate: true);

  @override
  Future<UpdateManifest> updateManifest() async {
    calls.add('updateManifest');
    throw const FormatException('Unexpected character');
  }
}

UpdateManifest manifest(String v, {bool mandatory = false, String? minVersion}) => UpdateManifest(
      version: v,
      file: 'mynine-setup-$v.exe',
      sha256: 'ab' * 32,
      size: 10,
      mandatory: mandatory,
      minVersion: minVersion,
    );

void main() {
  late Directory tmp;
  late AppPaths paths;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mynine_upd');
    paths = AppPaths(tmp);
  });
  tearDown(() => tmp.delete(recursive: true));

  test('evaluate: available / mandatory', () {
    var r = UpdateService.evaluate(manifest('1.2.0'), '1.1.0');
    expect((r.available, r.mandatory), (true, false));
    r = UpdateService.evaluate(manifest('1.2.0', minVersion: '1.2.0'), '1.1.0');
    expect((r.available, r.mandatory), (true, true));
    r = UpdateService.evaluate(manifest('1.2.0', minVersion: '1.1.0'), '1.1.0');
    expect((r.available, r.mandatory), (true, false));
    r = UpdateService.evaluate(manifest('1.2.0', mandatory: true), '1.1.0');
    expect(r.mandatory, isTrue);
    r = UpdateService.evaluate(manifest('1.1.0'), '1.1.0');
    expect(r.available, isFalse);
    r = UpdateService.evaluate(manifest('1.0.9', mandatory: true), '1.1.0');
    expect((r.available, r.mandatory), (false, false));
    r = UpdateService.evaluate(null, '1.1.0');
    expect(r.available, isFalse);
  });

  test('incomplete manifests are never offered', () {
    final full = manifest('1.2.0');
    expect(full.isComplete, isTrue);
    for (final m in [
      full.copyWith(sha256: ''),
      full.copyWith(size: 0),
      full.copyWith(file: ''),
      full.copyWith(file: '../evil.exe'),
      full.copyWith(file: 'setup.zip'),
      full.copyWith(version: '1.2'),
    ]) {
      expect(m.isComplete, isFalse, reason: m.toString());
      expect(UpdateService.evaluate(m, '1.0.0').available, isFalse);
    }
  });

  test('parses the version.json format', () {
    final m = UpdateManifest.fromJson(jsonDecode(
      '{"version":"1.0.0","file":"mynine-setup-1.0.0.exe","sha256":"","size":0,"mandatory":false,'
      '"min_version":null,"notes":"First release","published_at":"2026-11-10T00:00:00+05:00"}',
    ) as Map<String, Object?>);
    expect(m.version, '1.0.0');
    expect(m.file, 'mynine-setup-1.0.0.exe');
    expect(m.minVersion, isNull);
    expect(m.notes, 'First release');
    expect(m.publishedAt, DateTime.utc(2026, 11, 9, 19));
    expect(m.isComplete, isFalse);
    final filled = UpdateManifest.fromJson(
        {'version': '1.1.0', 'file': 'mynine-setup-1.1.0.exe', 'sha256': 'AB' * 32, 'size': 5, 'mandatory': 'yes', 'min_version': '1.0.0'});
    expect(filled.isComplete, isTrue);
    expect(filled.mandatory, isFalse);
    expect(filled.minVersion, '1.0.0');
    expect(const UpdateManifest().isComplete, isFalse);
  });

  test('site url is derived from the API base url', () {
    expect(siteUrlFromApiBase('https://mynine.uz/api/v1'), 'https://mynine.uz');
    expect(siteUrlFromApiBase('https://mynine.uz/api/v1/'), 'https://mynine.uz');
    expect(siteUrlFromApiBase('http://127.0.0.1:8000/api'), 'http://127.0.0.1:8000');
    expect(siteUrlFromApiBase('https://mynine.uz'), 'https://mynine.uz');
  });

  test('missing, broken or unfilled version.json means "up to date", not an error', () async {
    final missing = FakeMynineApi(clock: ServerClock(), latency: Duration.zero, offerUpdate: true)
      ..manifestMissing = true;
    var svc = UpdateService(api: missing, paths: paths, currentVersion: '1.0.0', runner: RecordingRunner());
    expect(await svc.check(manual: true), isFalse);
    expect(svc.phase, UpdatePhase.upToDate);
    expect(svc.error, isNull);

    svc = UpdateService(api: BrokenManifestApi(), paths: paths, currentVersion: '1.0.0', runner: RecordingRunner());
    expect(await svc.check(manual: true), isFalse);
    expect(svc.phase, UpdatePhase.upToDate);

    final unfilled = FakeMynineApi(clock: ServerClock(), latency: Duration.zero)
      ..manifestOverride = const UpdateManifest(version: '9.0.0', file: 'mynine-setup-9.0.0.exe', mandatory: true);
    svc = UpdateService(api: unfilled, paths: paths, currentVersion: '1.0.0', runner: RecordingRunner());
    expect(await svc.check(manual: true), isFalse);
    expect(svc.phase, UpdatePhase.upToDate);
    expect(svc.mandatory, isFalse);
    expect(await svc.download(), isNull);
    expect(unfilled.calls, isNot(contains('download')));
  });

  test('network errors show an error but nothing else', () async {
    final api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero, offerUpdate: true)..offline = true;
    final svc = UpdateService(api: api, paths: paths, currentVersion: '1.0.0', runner: RecordingRunner());
    expect(await svc.check(manual: true), isFalse);
    expect(svc.phase, UpdatePhase.error);
    expect(svc.release, isNull);
  });

  test('verifySha256', () async {
    final f = File(p.join(tmp.path, 'a.bin'))..writeAsBytesSync(utf8.encode('hello'));
    final good = sha256.convert(utf8.encode('hello')).toString();
    expect(await verifySha256(f, good), isTrue);
    expect(await verifySha256(f, good.toUpperCase()), isTrue);
    expect(await verifySha256(f, '0' * 64), isFalse);
    expect(await verifySha256(f, null), isTrue);
  });

  test('download verifies SHA-256 and install records rollback state', () async {
    final runner = RecordingRunner();
    final api = TamperApi();
    final svc = UpdateService(api: api, paths: paths, currentVersion: '1.0.0', runner: runner);
    expect(await svc.check(manual: true), isTrue);
    expect(svc.release!.version, '1.0.1');
    final file = await svc.download();
    expect(api.downloadedFiles, ['mynine-setup-1.0.1.exe']);
    expect(file, isNotNull);
    expect(p.basename(file!.path), 'mynine-setup-1.0.1.exe');
    await svc.install(file);
    expect(runner.ran, ['mynine-setup-1.0.1.exe']);
    final state = await svc.readState();
    expect(state!.pendingVerify, isTrue);
    expect(state.targetVersion, '1.0.1');
    expect(state.fromVersion, '1.0.0');
    // The installer of the running version was fetched for rollback
    // from <site>/desktop/mynine-setup-<current>.exe.
    expect(api.downloadedFiles.last, 'mynine-setup-1.0.0.exe');
    expect(File(p.join(paths.previous.path, 'mynine-setup-1.0.0.exe')).existsSync(), isTrue);
  });

  test('corrupted download is rejected', () async {
    final api = TamperApi()..badSha = true;
    final svc = UpdateService(api: api, paths: paths, currentVersion: '1.0.0', runner: RecordingRunner());
    await svc.check(manual: true);
    expect(await svc.download(), isNull);
    expect(svc.phase, UpdatePhase.error);
    expect(File(p.join(paths.updates.path, 'mynine-setup-1.0.1.exe')).existsSync(), isFalse);
  });

  test('download with the wrong size is rejected', () async {
    final api = TamperApi()..badSize = true;
    final svc = UpdateService(api: api, paths: paths, currentVersion: '1.0.0', runner: RecordingRunner());
    await svc.check(manual: true);
    expect(await svc.download(), isNull);
    expect(svc.phase, UpdatePhase.error);
  });

  test('resumes a partial download (.part file)', () async {
    final api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero, offerUpdate: true);
    final svc = UpdateService(api: api, paths: paths, currentVersion: '1.0.0', runner: RecordingRunner());
    await svc.check(manual: true);
    // Simulate a previously completed file with wrong content: re-downloaded.
    final target = svc.installerFile('1.0.1');
    await target.parent.create(recursive: true);
    await target.writeAsString('broken');
    final f = await svc.download();
    expect(await verifySha256(f!, svc.release!.sha256), isTrue);
  });

  test('self-check passes when API reachable and code screen rendered', () async {
    final runner = RecordingRunner();
    await paths.updates.create(recursive: true);
    final installer = File(p.join(paths.updates.path, 'mynine-setup-1.0.1.exe'))..writeAsStringSync('new');
    final svc = UpdateService(api: TamperApi(), paths: paths, currentVersion: '1.0.1', runner: runner);
    await svc.writeState(UpdateStateData(
        pendingVerify: true, targetVersion: '1.0.1', fromVersion: '1.0.0', installerPath: installer.path));
    await svc.startupSelfCheck();
    svc.reportApiReachable();
    svc.reportCodeScreenRendered();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await svc.readState(), isNull);
    expect(runner.ran, isEmpty);
    expect(File(p.join(paths.previous.path, 'mynine-setup-1.0.1.exe')).existsSync(), isTrue);
    svc.dispose();
  });

  test('rolls back when a previous launch never passed the self-check', () async {
    final runner = RecordingRunner();
    await paths.previous.create(recursive: true);
    File(p.join(paths.previous.path, 'mynine-setup-1.0.0.exe')).writeAsStringSync('old');
    final now = DateTime(2026, 11, 12, 10);
    final svc = UpdateService(
        api: TamperApi(), paths: paths, currentVersion: '1.0.1', runner: runner, now: () => now);
    await svc.writeState(UpdateStateData(
      pendingVerify: true,
      targetVersion: '1.0.1',
      fromVersion: '1.0.0',
      firstLaunchAt: now.subtract(AppConfig.updateSelfCheckWindow + const Duration(seconds: 1)),
    ));
    await svc.startupSelfCheck();
    expect(runner.ran, ['mynine-setup-1.0.0.exe']);
    expect((await svc.readState())!.rolledBackFrom, '1.0.1');
  });

  test('random jitter stays within 0–10 minutes', () {
    final svc = UpdateService(
        api: TamperApi(), paths: paths, currentVersion: '1.0.0', runner: RecordingRunner(), random: Random(1));
    for (var i = 0; i < 200; i++) {
      final j = svc.randomJitter();
      expect(j >= Duration.zero && j <= AppConfig.updateJitterMax, isTrue);
    }
  });

  test('DeviceState names match the API', () {
    expect(DeviceState.values.map((e) => e.name), ['idle', 'updating', 'exam']);
  });
}
