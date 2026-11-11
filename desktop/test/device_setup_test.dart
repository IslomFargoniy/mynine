import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/app/widgets.dart';
import 'package:mynine_desktop/core/api/api_exception.dart';
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/storage/settings_store.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/data/models/app_models.dart';
import 'package:mynine_desktop/data/repositories/device_repository.dart';
import 'package:mynine_desktop/features/setup/setup_views.dart';
import 'package:mynine_desktop/platform/lockdown/lockdown.dart';

/// Fake server that has forgotten this PC (401 on device endpoints).
class _ForgottenDeviceApi extends FakeMynineApi {
  _ForgottenDeviceApi() : super(clock: ServerClock(), latency: Duration.zero);

  bool forgotten = false;

  @override
  Future<DeviceHeartbeat> deviceHeartbeat({required String appVersion, required DeviceState state}) {
    if (forgotten) throw ApiException(code: ApiErrorCode.unauthenticated, statusCode: 401);
    return super.deviceHeartbeat(appVersion: appVersion, state: state);
  }
}

Future<(DeviceRepository, MemorySettingsStore)> _device(FakeMynineApi api) async {
  final store = MemorySettingsStore();
  final device = DeviceRepository(
    api: api,
    store: store,
    credentials: DeviceCredentials(),
    lockdown: NoopLockdown(),
    appVersion: '1.0.2',
  );
  await device.load();
  return (device, store);
}

FakeMynineApi _api() => FakeMynineApi(clock: ServerClock(), latency: Duration.zero)..approved = false;

void main() {
  group('registration with the center password', () {
    test('a fresh PC is not registered and registers nothing by itself', () async {
      final api = _api();
      final (device, _) = await _device(api);
      expect(device.isRegistered, isFalse);
      expect(device.isApprovalPending, isFalse);
      expect(api.calls, isNot(contains('registerDevice')));
    });

    test('a wrong password is refused and no token is stored', () async {
      final api = _api();
      final (device, store) = await _device(api);
      await expectLater(
        device.register(password: 'wrong'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.invalidPassword)),
      );
      expect(device.isRegistered, isFalse);
      expect(await store.read(SettingsKeys.deviceToken), isNull);
    });

    test('a server without a center password answers setup_password_missing', () async {
      final api = _api()..centerPasswordMissing = true;
      final (device, _) = await _device(api);
      try {
        await device.register(password: 'mynine');
        fail('expected an ApiException');
      } on ApiException catch (e) {
        expect(e.code, ApiErrorCode.setupPasswordMissing);
        expect(setupErrorMessage(e), contains('Desktop settings'));
      }
      expect(device.isRegistered, isFalse);
    });

    test('the right password registers the PC, which then waits for approval', () async {
      final api = _api();
      final (device, store) = await _device(api);
      await device.register(password: 'mynine');

      expect(device.isRegistered, isTrue);
      expect(device.isApprovalPending, isTrue);
      expect(device.pcNumber, isNull);
      expect(device.pcName, startsWith('PC-'));
      expect(await store.read(SettingsKeys.deviceToken), isNotNull);

      // Still pending after a restart.
      final again = DeviceRepository(
        api: api,
        store: store,
        credentials: DeviceCredentials(),
        lockdown: NoopLockdown(),
        appVersion: '1.0.2',
      );
      await again.load();
      expect(again.isRegistered, isTrue);
      expect(again.isApprovalPending, isTrue);
    });

    test('an optional name is sent to the server', () async {
      final api = _api();
      final (device, _) = await _device(api);
      await device.register(password: 'mynine', name: '  Front row  ');
      expect(device.pcName, 'Front row');
      expect(api.deviceName, 'Front row');
    });
  });

  group('approval and the PC number', () {
    test('config after approval clears pending and gives the number; heartbeat follows renumbering', () async {
      final api = _api()..number = 7;
      final (device, store) = await _device(api);
      await device.register(password: 'mynine');

      await expectLater(device.refreshConfig(), throwsA(isA<ApiException>()));
      expect(device.isApprovalPending, isTrue);

      api.approved = true;
      await device.refreshConfig();
      expect(device.isApprovalPending, isFalse);
      expect(device.pcNumber, 7);
      expect(await store.read(SettingsKeys.pcNumber), '7');

      api.number = 12;
      await device.heartbeat(DeviceState.idle);
      expect(device.pcNumber, 12);

      // Re-registering keeps the number on the server but needs approval again.
      await device.register(password: 'mynine');
      expect(device.isApprovalPending, isTrue);
      await device.heartbeat(DeviceState.idle);
      expect(device.isApprovalPending, isTrue);
    });

    test('a heartbeat that reports the PC as approved ends the waiting state', () async {
      final api = _api();
      final (device, _) = await _device(api);
      await device.register(password: 'mynine');
      expect(device.isApprovalPending, isTrue);
      api.approved = true;
      await device.heartbeat(DeviceState.idle);
      expect(device.isApprovalPending, isFalse);
      expect(device.pcNumber, 7);
    });

    test('a token the server no longer knows sends the PC back to Setup (no automatic re-register)', () async {
      final api = _ForgottenDeviceApi();
      final (device, store) = await _device(api);
      await device.register(password: 'mynine');
      api.forgotten = true;

      await expectLater(device.heartbeat(DeviceState.idle), throwsA(isA<ApiException>()));
      expect(device.isRegistered, isFalse);
      expect(await store.read(SettingsKeys.deviceToken), isNull);
      expect(api.calls.where((c) => c == 'registerDevice').length, 1);
    });
  });

  group('setup screens', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

    testWidgets('setup view shows the password error and passes password + name', (tester) async {
      final calls = <(String, String?)>[];
      await tester.pumpWidget(wrap(SetupView(onRegister: (password, name) async {
        calls.add((password, name));
        if (password != 'mynine') {
          throw ApiException(code: ApiErrorCode.invalidPassword, statusCode: 422);
        }
      })));

      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pump();
      expect(find.text('Enter the center password.'), findsOneWidget);
      expect(calls, isEmpty);

      await tester.enterText(find.byKey(const Key('setup-password')), 'nope');
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Incorrect center password.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('setup-password')), 'mynine');
      await tester.enterText(find.byKey(const Key('setup-name')), 'PC-07');
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pumpAndSettle();
      expect(calls.last, ('mynine', 'PC-07'));
      expect(find.byKey(const Key('setup-error')), findsNothing);
    });

    testWidgets('setup view shows setup_password_missing from the server', (tester) async {
      await tester.pumpWidget(wrap(SetupView(onRegister: (_, _) async {
        throw ApiException(
          code: ApiErrorCode.setupPasswordMissing,
          statusCode: 409,
          message: 'Set the desktop password in Desktop settings first.',
        );
      })));
      await tester.enterText(find.byKey(const Key('setup-password')), 'x');
      await tester.tap(find.byKey(const Key('setup-submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Desktop settings'), findsOneWidget);
    });

    testWidgets('pending view shows the PC name and short machine id', (tester) async {
      await tester.pumpWidget(wrap(const PendingApprovalView(pcName: 'PC-3332', machineIdShort: '…4F4D3332')));
      expect(find.text('Waiting for administrator approval'), findsOneWidget);
      expect(find.text('PC-3332'), findsOneWidget);
      expect(find.text('…4F4D3332'), findsOneWidget);
    });

    testWidgets('PC number badge', (tester) async {
      await tester.pumpWidget(wrap(const PcNumberBadge(number: 7, large: true)));
      expect(find.text('PC 7'), findsOneWidget);
    });
  });
}
