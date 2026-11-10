import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/api/api_exception.dart';
import 'package:mynine_desktop/core/api/http_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:path/path.dart' as p;

/// HttpMynineApi against a local server that mimics nginx serving
/// `public/desktop/` (static version.json + installer with Range support).
void main() {
  late HttpServer server;
  late Directory tmp;
  late HttpMynineApi api;
  final requests = <HttpRequest>[];
  final installer = List<int>.generate(1000, (i) => i & 0xff);
  String? manifestBody;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mynine_http_upd');
    requests.clear();
    manifestBody = jsonEncode({
      'version': '1.2.0',
      'file': 'mynine-setup-1.2.0.exe',
      'sha256': 'ab' * 32,
      'size': installer.length,
      'mandatory': false,
      'min_version': '1.1.0',
      'notes': 'Fixes',
      'published_at': '2026-11-10T00:00:00+05:00',
    });
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests.add(req);
      final res = req.response;
      if (req.uri.path == '/desktop/version.json' && manifestBody != null) {
        res.headers.contentType = ContentType('application', 'json');
        res.write(manifestBody);
      } else if (req.uri.path == '/desktop/mynine-setup-1.2.0.exe') {
        final range = req.headers.value('range');
        final start = range == null ? 0 : int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
        if (start > 0) {
          res.statusCode = 206;
          res.headers.set('Content-Range', 'bytes $start-${installer.length - 1}/${installer.length}');
        }
        res.headers.contentLength = installer.length - start;
        res.add(installer.sublist(start));
      } else {
        res.statusCode = 404;
        res.write('<html>404 Not Found</html>');
      }
      await res.close();
    });
    final credentials = DeviceCredentials()..deviceToken = 'secret-device-token';
    api = HttpMynineApi(
      baseUrl: () => 'http://127.0.0.1:${server.port}/api/v1/',
      clientHeader: 'desktop/1.0.0',
      credentials: credentials,
      clock: ServerClock(),
    );
  });

  tearDown(() async {
    await server.close(force: true);
    await tmp.delete(recursive: true);
  });

  test('reads the static version.json without auth and with a cache buster', () async {
    final m = await api.updateManifest();
    expect(m.version, '1.2.0');
    expect(m.minVersion, '1.1.0');
    expect(m.isComplete, isTrue);
    final req = requests.single;
    expect(req.uri.path, '/desktop/version.json');
    expect(int.tryParse(req.uri.queryParameters['t'] ?? ''), isNotNull);
    expect(req.headers.value('x-device-token'), isNull);
    expect(req.headers.value('authorization'), isNull);
    expect(api.updateFileUrl('mynine-setup-1.2.0.exe'),
        'http://127.0.0.1:${server.port}/desktop/mynine-setup-1.2.0.exe');
  });

  test('missing version.json is a 404 ApiException, garbage a FormatException', () async {
    manifestBody = null;
    await expectLater(
        api.updateManifest(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)));
    manifestBody = 'not json';
    await expectLater(api.updateManifest(), throwsA(isA<FormatException>()));
  });

  test('installer download resumes with Range and sends no device token', () async {
    final target = File(p.join(tmp.path, 'mynine-setup-1.2.0.exe'));
    File('${target.path}.part').writeAsBytesSync(installer.sublist(0, 400));
    await api.download(api.updateFileUrl('mynine-setup-1.2.0.exe'), target, anonymous: true);
    expect(target.readAsBytesSync(), installer);
    final req = requests.single;
    expect(req.headers.value('range'), 'bytes=400-');
    expect(req.headers.value('x-device-token'), isNull);
  });
}
