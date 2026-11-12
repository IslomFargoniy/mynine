// Real HTTP (no widget binding: it would answer every request with 400).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/api/http_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';

void main() {
  test('HTTP: register sends center_code (uppercased) only when given', () async {
    final bodies = <Map<String, Object?>>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((req) async {
      bodies.add((jsonDecode(await utf8.decodeStream(req)) as Map).cast<String, Object?>());
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'device_id': 7,
          'device_token': 't',
          'name': 'PC-07',
          'approved': false,
          'center': {'code': 'ACME', 'name': 'Acme', 'logo_url': null, 'suspended': false},
        }));
      await req.response.close();
    });
    final api = HttpMynineApi(
      baseUrl: () => 'http://127.0.0.1:${server.port}/api/v1',
      clientHeader: 'desktop/1.0.0',
      credentials: DeviceCredentials(),
      clock: ServerClock(),
    );
    final r = await api.registerDevice(
        machineId: 'm', centerCode: 'acme', password: 'p', osVersion: 'w', appVersion: '1.0.0');
    expect(bodies.last['center_code'], 'ACME');
    expect(r.center!.name, 'Acme');
    await api.registerDevice(machineId: 'm', centerCode: '', password: 'p', osVersion: 'w', appVersion: '1.0.0');
    expect(bodies.last.containsKey('center_code'), isFalse);
    expect(api.isApiUrl('http://127.0.0.1:${server.port}/storage/centers/logos/a.png'), isTrue);
    expect(api.isApiUrl('http://evil.example/a.png'), isFalse);
  });

}
