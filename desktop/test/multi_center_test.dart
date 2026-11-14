import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/app/providers.dart';
import 'package:mynine_desktop/app/theme.dart';
import 'package:mynine_desktop/core/api/api_exception.dart';
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/api/http_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/config/app_config.dart';
import 'package:mynine_desktop/core/storage/app_paths.dart';
import 'package:mynine_desktop/core/storage/settings_store.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/data/models/app_models.dart';
import 'package:mynine_desktop/data/repositories/device_repository.dart';
import 'package:mynine_desktop/features/code_entry/code_entry_screen.dart';
import 'package:mynine_desktop/features/setup/setup_views.dart';
import 'package:mynine_desktop/features/updater/update_service.dart';
import 'package:mynine_desktop/platform/lockdown/lockdown.dart';

import 'support/harness.dart';

class _NoRunner implements InstallerRunner {
  @override
  bool get canInstall => false;
  @override
  Future<void> runSilentAndExit(File installer) async {}
}

Future<(DeviceRepository, MemorySettingsStore)> _device(FakeMynineApi api, {Directory? dir}) async {
  final store = MemorySettingsStore();
  final device = DeviceRepository(
    api: api,
    store: store,
    credentials: DeviceCredentials(),
    lockdown: NoopLockdown(),
    appVersion: '1.0.0',
    backgroundDir: dir,
  );
  await device.load();
  return (device, store);
}

void main() {
  group('config parsing', () {
    test('config with a center object', () {
      final c = DeviceConfig.fromJson({
        'name': 'PC-07',
        'number': 7,
        'approved': true,
        'banned_processes': ['a.exe'],
        'center': {'code': 'ACME', 'name': 'Acme Learning', 'logo_url': 'https://x/logo.png', 'suspended': true},
      });
      expect(c.center, const CenterInfo(code: 'ACME', name: 'Acme Learning', logoUrl: 'https://x/logo.png', suspended: true));
      // Survives the cache round trip.
      final again = DeviceConfig.fromJson(c.toJson().cast<String, Object?>());
      expect(again.center, c.center);
    });

    test('config from an older server (no center) and a null logo', () {
      final old = DeviceConfig.fromJson({'name': 'PC-07', 'banned_processes': <String>[]});
      expect(old.center, isNull);
      expect(DeviceConfig.fromJson(old.toJson().cast<String, Object?>()).center, isNull);
      final noLogo = DeviceConfig.fromJson({
        'center': {'code': 'ACME', 'name': 'Acme', 'logo_url': null, 'suspended': false},
      });
      expect(noLogo.center!.logoUrl, isNull);
      expect(noLogo.center!.suspended, isFalse);
      expect(DeviceConfig.fromJson({'center': 'garbage'}).center, isNull);
    });

    test('registration response with and without center', () {
      final r = DeviceRegistration.fromJson({
        'device_id': 7,
        'device_token': 't',
        'name': 'PC-07',
        'center': {'code': 'ACME', 'name': 'Acme', 'logo_url': null, 'suspended': false},
      });
      expect(r.center!.code, 'ACME');
      expect(DeviceRegistration.fromJson({'device_id': 7, 'device_token': 't', 'name': 'PC-07'}).center, isNull);
    });

    test('api origin check for server-named files', () {
      expect(HttpMynineApi.isApiOrigin(Uri.parse('https://mynine.uz/storage/centers/logos/a.png'),
          'https://mynine.uz/api/v1'), isTrue);
      expect(HttpMynineApi.isApiOrigin(Uri.parse('https://evil.example/a.png'), 'https://mynine.uz/api/v1'), isFalse);
    });
  });

  group('error codes', () {
    test('invalid_center_code and center_suspended messages', () {
      final invalid = ApiException(code: ApiErrorCode.fromWire('invalid_center_code', 422), statusCode: 422);
      expect(invalid.code, ApiErrorCode.invalidCenterCode);
      expect(invalid.userMessage, 'Unknown center code. Check it with your center.');
      expect(setupErrorMessage(invalid), 'Unknown center code. Check it with your center.');
      final suspended = ApiException(code: ApiErrorCode.fromWire('center_suspended', 403), statusCode: 403);
      expect(suspended.code, ApiErrorCode.centerSuspended);
      expect(suspended.userMessage, 'This center is not active. Please contact the center administration.');
      expect(setupErrorMessage(suspended), suspended.userMessage);
    });

    test('device_other_center says to remove the PC in the other center first', () {
      final e = ApiException(code: ApiErrorCode.fromWire('device_other_center', 409), statusCode: 409);
      expect(e.code, ApiErrorCode.deviceOtherCenter);
      expect(setupErrorMessage(e), contains('registered to another center'));
      expect(setupErrorMessage(e), isNot(contains('Something went wrong')));
    });
  });

  group('registration with a center code', () {
    test('sends center_code, remembers it and takes the center from the response', () async {
      final api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero)
        ..center = const CenterInfo(code: 'DEMO', name: 'Demo Center');
      final (device, store) = await _device(api);
      await device.register(centerCode: ' demo ', password: 'mynine');
      expect(api.lastCenterCode, 'DEMO');
      expect(device.lastCenterCode, 'DEMO');
      expect(await store.read(SettingsKeys.centerCode), 'DEMO');
      expect(device.centerName, 'Demo Center');

      // Prefilled after a restart.
      final again = DeviceRepository(
        api: api,
        store: store,
        credentials: DeviceCredentials(),
        lockdown: NoopLockdown(),
        appVersion: '1.0.0',
      );
      await again.load();
      expect(again.lastCenterCode, 'DEMO');
      expect(again.centerName, 'Demo Center');
    });

    test('an empty code sends no center_code (Mynine center, older behaviour)', () async {
      final api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero)..center = null;
      final (device, _) = await _device(api);
      await device.register(centerCode: '', password: 'mynine');
      expect(api.lastCenterCode, isNull);
      expect(device.centerName, 'Mynine');
    });

    test('an unknown code is refused with invalid_center_code and nothing is stored', () async {
      final api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero);
      final (device, store) = await _device(api);
      await expectLater(
        device.register(centerCode: 'NOPE', password: 'mynine'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.invalidCenterCode)),
      );
      expect(device.isRegistered, isFalse);
      expect(await store.read(SettingsKeys.centerCode), isNull);
    });

    testWidgets('setup view: code field validates, uppercases, is prefilled and passed on', (tester) async {
      final calls = <(String, String, String?)>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SetupView(
              initialCenterCode: 'ACME',
              onRegister: (code, password, name) async {
                calls.add((code, password, name));
                if (code != 'MYNINE') throw ApiException(code: ApiErrorCode.invalidCenterCode, statusCode: 422);
              },
            ),
          ),
        ),
      ));
      expect(find.text('ACME'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('setup-center-code')), 'ab');
      await tester.enterText(find.byKey(const Key('setup-password')), 'mynine');
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pump();
      expect(find.text('The center code has 3–12 letters or digits.'), findsOneWidget);
      expect(calls, isEmpty);

      await tester.enterText(find.byKey(const Key('setup-center-code')), 'acme-1');
      expect(find.text('ACME1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pumpAndSettle();
      expect(calls.last.$1, 'ACME1');
      expect(find.text('Unknown center code. Check it with your center.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('setup-center-code')), 'mynine');
      await tester.enterText(find.byKey(const Key('setup-password')), 'mynine');
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pumpAndSettle();
      expect(calls.last, ('MYNINE', 'mynine', null));
      expect(find.byKey(const Key('setup-error')), findsNothing);
    });
  });

  group('center logo', () {
    test('downloaded from the API server only, dropped when removed', () async {
      final dir = await Directory.systemTemp.createTemp('mynine-logo');
      addTearDown(() => dir.delete(recursive: true));
      final api = FakeMynineApi(clock: ServerClock(), latency: Duration.zero)
        ..autoApprove = true
        ..logoBytes = Uint8List.fromList(List.generate(500, (i) => i % 200))
        ..center = const CenterInfo(code: 'ACME', name: 'Acme', logoUrl: 'fake://logo/acme.png');
      final (device, _) = await _device(api, dir: dir);
      await device.register(centerCode: 'DEMO', password: 'mynine');
      await device.refreshConfig();
      await device.syncLogo();
      expect(device.logoFile, isNotNull);
      expect(device.logoFile!.readAsBytesSync(), api.logoBytes);

      // Another origin is never fetched.
      api.center = const CenterInfo(code: 'ACME', name: 'Acme', logoUrl: 'https://evil.example/logo.png');
      await device.refreshConfig();
      await device.syncLogo();
      expect(device.logoFile, isNull);
      expect(api.calls.where((c) => c == 'download').length, 1);

      api.center = const CenterInfo(code: 'ACME', name: 'Acme');
      await device.refreshConfig();
      await device.syncLogo();
      expect(device.logoFile, isNull);
      expect(dir.listSync().where((f) => f.path.contains('logo-')), isEmpty);
    });
  });

  group('code entry screen', () {
    Future<(Harness, UpdateService, Directory)> setUpScreen(WidgetTester tester, {CenterInfo? center, Uint8List? logo}) async {
      late Harness h;
      late UpdateService updates;
      late Directory tmp;
      await tester.runAsync(() async {
        h = await Harness.create(approved: true, number: 7);
        h.api
          ..center = center
          ..logoBytes = logo;
        tmp = await Directory.systemTemp.createTemp('mynine-code');
        updates = UpdateService(
          api: h.api,
          paths: AppPaths(tmp),
          currentVersion: '1.0.0',
          runner: _NoRunner(),
          serverReachable: () async => true,
        );
      });
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      return (h, updates, tmp);
    }

    Future<void> pumpScreen(WidgetTester tester, Harness h, UpdateService updates, DeviceRepository device) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
              const AppConfig(appVersion: '1.0.0', apiFake: false, defaultBaseUrl: 'fake://', kioskEnabled: false)),
          examControllerProvider.overrideWithValue(h.exam),
          deviceRepositoryProvider.overrideWithValue(device),
          connectionProvider.overrideWithValue(h.connection),
          updateServiceProvider.overrideWithValue(updates),
          apiProvider.overrideWithValue(h.api),
        ],
        child: MaterialApp(theme: buildTheme(), home: const CodeEntryScreen()),
      ));
      await tester.pump();
    }

    Future<void> tearDownScreen(WidgetTester tester, Harness h, UpdateService updates, Directory tmp) async {
      await tester.pumpWidget(const SizedBox());
      updates.stopPeriodic();
      await tester.runAsync(() async {
        await h.dispose();
        try {
          await tmp.delete(recursive: true);
        } catch (_) {}
      });
    }

    testWidgets('shows the center name and logo, and "Powered by Mynine"', (tester) async {
      final (h, updates, tmp) = await setUpScreen(
        tester,
        center: const CenterInfo(code: 'ACME', name: 'Acme Learning', logoUrl: 'fake://logo/acme.png'),
        logo: _png,
      );
      late DeviceRepository device;
      late Directory logoDir;
      await tester.runAsync(() async {
        logoDir = await Directory.systemTemp.createTemp('mynine-logo');
        device = DeviceRepository(
          api: h.api,
          store: MemorySettingsStore(),
          credentials: DeviceCredentials(),
          lockdown: NoopLockdown(),
          appVersion: '1.0.0',
          backgroundDir: logoDir,
        );
        await device.load();
        await device.register(centerCode: 'DEMO', password: 'mynine');
        await device.refreshConfig();
        await device.syncLogo();
      });
      await pumpScreen(tester, h, updates, device);

      expect(find.text('Acme Learning'), findsOneWidget);
      expect(find.text('Mynine'), findsNothing);
      expect(find.byKey(const Key('center-logo')), findsOneWidget);
      expect(find.text('Powered by Mynine'), findsOneWidget);
      expect(find.byKey(const Key('center-suspended')), findsNothing);
      expect(tester.widget<FilledButton>(find.byKey(const Key('code-submit'))).onPressed, isNotNull);

      await tearDownScreen(tester, h, updates, tmp);
      await tester.runAsync(() => logoDir.delete(recursive: true));
    });

    testWidgets('an older server (no center) keeps the Mynine name', (tester) async {
      final (h, updates, tmp) = await setUpScreen(tester);
      await tester.runAsync(() => h.device.refreshConfig());
      await pumpScreen(tester, h, updates, h.device);
      expect(find.byKey(const Key('center-name')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('center-name'))).data, 'Mynine');
      expect(find.byKey(const Key('center-logo')), findsNothing);
      await tearDownScreen(tester, h, updates, tmp);
    });

    testWidgets('a suspended center shows a notice and disables START', (tester) async {
      final (h, updates, tmp) = await setUpScreen(
        tester,
        center: const CenterInfo(code: 'ACME', name: 'Acme Learning', suspended: true),
      );
      await tester.runAsync(() => h.device.refreshConfig());
      await pumpScreen(tester, h, updates, h.device);

      expect(find.byKey(const Key('center-suspended')), findsOneWidget);
      expect(find.text(centerSuspendedMessage), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('code-submit'))).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('code-field')), '123456');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(h.api.calls, isNot(contains('login')));

      // The center is active again: the next config re-enables START.
      h.api.center = const CenterInfo(code: 'ACME', name: 'Acme Learning');
      await tester.runAsync(() => h.device.refreshConfig());
      await tester.pump();
      expect(find.byKey(const Key('center-suspended')), findsNothing);
      expect(tester.widget<FilledButton>(find.byKey(const Key('code-submit'))).onPressed, isNotNull);

      await tearDownScreen(tester, h, updates, tmp);
    });
  });

  test('a login answered center_suspended marks the center suspended until the config says active', () async {
    final h = await Harness.create();
    addTearDown(h.dispose);
    h.api.centerSuspended = true;
    await h.exam.login('DEMO1');
    expect(h.exam.error, centerSuspendedMessage);
    expect(h.device.centerSuspended, isTrue);

    h.api.centerSuspended = false;
    await h.device.refreshConfig(); // the idle PC re-reads the config every minute
    expect(h.device.centerSuspended, isFalse);
  });
}

/// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);
