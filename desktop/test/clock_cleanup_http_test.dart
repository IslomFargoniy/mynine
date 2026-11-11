import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/app/bootstrap.dart' show restoreClockOffset;
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/api/http_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/storage/app_paths.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:mynine_desktop/data/db/app_database.dart';
import 'package:mynine_desktop/data/models/exam_models.dart';
import 'package:mynine_desktop/data/repositories/exam_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ServerClock (v1.1)', () {
    test('keeps the offset of the lowest round trip, not the latest sample', () {
      var local = DateTime.utc(2026, 1, 1, 0, 0, 10);
      final clock = ServerClock(localNow: () => local);
      // Precise sample: rtt 100 ms, server 5.000 s ahead.
      clock.update(DateTime.utc(2026, 1, 1, 0, 0, 15, 0, 1),
          requestStartedAt: local.subtract(const Duration(milliseconds: 100)));
      final precise = clock.offset;
      expect((precise - const Duration(seconds: 5)).abs(), lessThan(const Duration(milliseconds: 60)));

      // Slow sample (rtt 4 s) that says +6 s: within both uncertainties, ignored.
      local = local.add(const Duration(seconds: 30));
      clock.update(DateTime.utc(2026, 1, 1, 0, 0, 46, 0, 1),
          requestStartedAt: local.subtract(const Duration(seconds: 4)));
      expect(clock.offset, precise);

      // An equally precise fresh sample replaces the old one.
      local = local.add(const Duration(seconds: 30));
      clock.update(DateTime.utc(2026, 1, 1, 0, 1, 15, 50),
          requestStartedAt: local.subtract(const Duration(milliseconds: 80)));
      expect(clock.offset, isNot(precise));
    });

    test('a local clock jump is detected and the new offset taken at once', () {
      var local = DateTime.utc(2026, 1, 1, 12);
      final clock = ServerClock(localNow: () => local);
      clock.update(DateTime.utc(2026, 1, 1, 12, 0, 0, 1), requestStartedAt: local);
      expect(clock.offset.inMilliseconds, 1);
      final serverBefore = clock.now();
      // Windows set the PC clock back by one hour (slow, imprecise sample).
      local = local.subtract(const Duration(hours: 1)).add(const Duration(seconds: 10));
      clock.update(DateTime.utc(2026, 1, 1, 12, 0, 10, 1),
          requestStartedAt: local.subtract(const Duration(seconds: 3)));
      expect((clock.offset - const Duration(hours: 1)).abs(), lessThan(const Duration(seconds: 2)));
      expect(clock.now().isAfter(serverBefore), isTrue);
    });

    test('the last good offset is persisted and restored after a restart', () async {
      final db = AppDatabase.memory();
      final local = DateTime.utc(2026, 1, 1, 12);
      final c1 = ServerClock(localNow: () => local);
      await restoreClockOffset(db, c1);
      c1.update(DateTime.utc(2026, 1, 1, 12, 1, 30, 5), requestStartedAt: local);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final c2 = ServerClock(localNow: () => local);
      await restoreClockOffset(db, c2);
      expect(c2.isSynced, isTrue);
      expect(c2.offset, c1.offset);
      // Any real sample wins over the restored value.
      c2.update(DateTime.utc(2026, 1, 1, 12, 0, 1, 5), requestStartedAt: local);
      expect(c2.offset.inSeconds, 1);
      await db.close();
    });
  });

  group('exam files cleanup / shared audio cache', () {
    late Directory tmp;
    late AppDatabase db;
    late FakeMynineApi api;
    late ExamRepository repo;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mynine_cleanup');
      db = AppDatabase.memory();
      api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero);
      repo = ExamRepository(api: api, db: db, paths: AppPaths(tmp));
    });
    tearDown(() async {
      await db.close();
      await tmp.delete(recursive: true);
    });

    Future<void> session(int id, {bool closed = false, bool completed = false, DateTime? created}) =>
        db.upsertSession(ExamSessionsCompanion.insert(
          attemptId: Value(id),
          token: 't$id',
          candidateName: 'C$id',
          candidateCode: 'CODE$id',
          completed: Value(completed),
          closed: Value(closed),
          createdAt: Value(created ?? DateTime.now()),
        ));

    test('audio is cached by sha256 and shared by candidates of the same test', () async {
      final token = (await api.login('DEMO1')).token;
      final a = await repo.prefetch(token, 1);
      final b = await repo.prefetch(token, 2);
      expect(a.audioFiles['test-9'], b.audioFiles['test-9']);
      expect(p.isWithin(AppPaths(tmp).audioCache.path, a.audioFiles['test-9']!), isTrue);
      expect(api.calls.where((c) => c == 'download').length, 1); // second one reused it
    });

    test('old finished sessions lose their files; the active one and fresh ones keep them', () async {
      final token = (await api.login('DEMO1')).token;
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 5));
      await session(1, closed: true, completed: true, created: old); // old, closed → purged
      await session(2, completed: true, created: now); // fresh → kept
      await session(3, created: old); // unfinished → never touched
      for (final id in [1, 2, 3]) {
        await repo.prefetch(token, id);
        await Directory(p.join(AppPaths(tmp).examDir(id).path, 'images')).create(recursive: true);
      }
      // An orphan audio file in the shared cache.
      final orphan = File(p.join(AppPaths(tmp).audioCache.path, '${'0' * 64}.mp3'))..writeAsStringSync('x');

      final purged = await repo.cleanup(now: now);
      expect(purged, 1);
      expect(AppPaths(tmp).examDir(1).existsSync(), isFalse);
      expect(await repo.loadCached(1), isNull);
      expect(await repo.loadCached(2), isNotNull);
      expect(await repo.loadCached(3), isNotNull);
      expect(AppPaths(tmp).examDir(3).existsSync(), isTrue);
      expect(orphan.existsSync(), isFalse);
      // Shared audio still referenced by sessions 2 and 3.
      expect(File((await repo.loadCached(3))!.audioFiles['test-9']!).existsSync(), isTrue);
      expect(await db.session(1), isNotNull); // the session row stays (audit)
    });

    test('keeps at most N finished sessions', () async {
      final now = DateTime.now();
      for (var i = 1; i <= 5; i++) {
        await session(i, closed: true, created: now.subtract(Duration(minutes: i)));
        await db.putCache(ExamRepository.cacheKey(i), jsonEncode({'payload': {}}));
      }
      expect(await repo.cleanup(now: now, keep: 2), 3);
      expect(await db.getCache(ExamRepository.cacheKey(1)), isNotNull);
      expect(await db.getCache(ExamRepository.cacheKey(2)), isNotNull);
      expect(await db.getCache(ExamRepository.cacheKey(5)), isNull);
    });
  });

  group('credentials only to the API origin', () {
    late HttpServer apiServer;
    late HttpServer cdn;
    late Directory tmp;
    final seen = <String, Map<String, String?>>{};

    Future<HttpServer> serve(String name) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        seen['$name ${req.uri.path}'] = {
          'device': req.headers.value('x-device-token'),
          'auth': req.headers.value('authorization'),
        };
        if (req.uri.path.endsWith('/exam/heartbeat')) {
          req.response.headers.contentType = ContentType.json;
          req.response.write(jsonEncode({'server_time': DateTime.now().toUtc().toIso8601String()}));
        } else {
          req.response.add(utf8.encode('img'));
        }
        await req.response.close();
      });
      return server;
    }

    setUp(() async {
      seen.clear();
      tmp = await Directory.systemTemp.createTemp('mynine_origin');
      apiServer = await serve('api');
      cdn = await serve('cdn');
    });
    tearDown(() async {
      await apiServer.close(force: true);
      await cdn.close(force: true);
      await tmp.delete(recursive: true);
    });

    test('device / exam tokens never go to another host; API success is reported', () async {
      var successes = 0;
      final api = HttpMynineApi(
        baseUrl: () => 'http://127.0.0.1:${apiServer.port}/api/v1',
        clientHeader: 'desktop/1.0.3',
        credentials: DeviceCredentials()..deviceToken = 'device-secret',
        clock: ServerClock(),
      )..onApiSuccess = () => successes++;

      await api.examHeartbeat('exam-secret', queuedAnswers: 0, queuedViolations: 0);
      expect(seen['api /api/v1/exam/heartbeat'], {'device': 'device-secret', 'auth': 'Bearer exam-secret'});
      expect(successes, 1);

      // Even when a caller passes the exam token, another origin gets nothing.
      await api.download('http://127.0.0.1:${cdn.port}/pic.png', File(p.join(tmp.path, 'a.png')),
          examToken: 'exam-secret');
      expect(seen['cdn /pic.png'], {'device': null, 'auth': null});
      expect(successes, 1);

      expect(HttpMynineApi.isApiOrigin(Uri.parse('https://mynine.uz/storage/x.png'), 'https://mynine.uz/api/v1'),
          isTrue);
      expect(HttpMynineApi.isApiOrigin(Uri.parse('https://cdn.example.com/x.png'), 'https://mynine.uz/api/v1'),
          isFalse);
      expect(HttpMynineApi.isApiOrigin(Uri.parse('http://mynine.uz/x'), 'https://mynine.uz/api/v1'), isFalse);
    });

    test('prefetch downloads images anonymously', () async {
      final recorder = _RecordingApi();
      final repo = ExamRepository(api: recorder, db: AppDatabase.memory(), paths: AppPaths(tmp));
      final token = (await recorder.login('DEMO1')).token;
      await repo.prefetch(token, 1);
      expect(recorder.imageDownloads, isNotEmpty);
      expect(recorder.imageDownloads.every((d) => d.anonymous && d.examToken == null), isTrue);
    });
  });

  test('sha256 helper sanity', () {
    expect(sha256.convert(utf8.encode('a')).toString().length, 64);
  });
}

class _RecordingApi extends FakeMynineApi {
  _RecordingApi() : super(clock: ServerClock(), latency: Duration.zero);
  final List<({bool anonymous, String? examToken})> imageDownloads = [];

  @override
  Future<PrefetchPayload> prefetch(String examToken) async =>
      (await super.prefetch(examToken)).copyWith(images: ['https://cdn.example.com/a.png']);

  @override
  Future<File> download(String url, File target,
      {String? examToken, ProgressCallback? onProgress, bool anonymous = false}) {
    if (url.startsWith('https://cdn.example.com')) {
      imageDownloads.add((anonymous: anonymous, examToken: examToken));
      target.parent.createSync(recursive: true);
      target.writeAsStringSync('img');
      return Future.value(target);
    }
    return super.download(url, target, examToken: examToken, onProgress: onProgress, anonymous: anonymous);
  }
}
