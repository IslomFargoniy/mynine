import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:package_info_plus/package_info_plus.dart';

import '../core/api/fake_mynine_api.dart';
import '../core/api/http_mynine_api.dart';
import '../core/api/mynine_api.dart';
import '../core/config/app_config.dart';
import '../core/storage/app_paths.dart';
import '../core/storage/settings_store.dart';
import '../core/time/server_clock.dart';
import '../data/db/app_database.dart';
import '../data/repositories/answer_queue.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/exam_repository.dart';
import '../data/repositories/sync_service.dart';
import '../data/repositories/violation_queue.dart';
import '../features/exam/exam_controller.dart';
import '../features/updater/update_service.dart';
import '../platform/lockdown/lockdown.dart';
import 'kiosk_controller.dart';
import 'providers.dart';

/// Builds every long-lived service and returns the ProviderScope overrides.
Future<List<Override>> bootstrap() async {
  final info = await PackageInfo.fromPlatform();
  final config = AppConfig.fromEnvironment(info.version.isEmpty ? '1.0.0' : info.version);
  final paths = await AppPaths.resolve();
  await paths.data.create(recursive: true);
  final db = AppDatabase.open(paths.data);
  final store = config.apiFake ? MemorySettingsStore() : SecureSettingsStore(paths.data);
  final clock = ServerClock();
  final credentials = DeviceCredentials();
  final serverUrl = ServerUrl(config.defaultBaseUrl);
  final lockdown = config.kioskEnabled ? createLockdown() : NoopLockdown();

  final MynineApi api = config.apiFake
      ? (FakeMynineApi(
          clock: clock,
          appVersionString: config.appVersion,
          offerUpdate: const bool.fromEnvironment('FAKE_UPDATE'),
        )
          // Demo: the Setup screen asks for the center password "mynine";
          // FAKE_UNAPPROVED=true stops on "Waiting for administrator approval".
          ..autoApprove = !const bool.fromEnvironment('FAKE_UNAPPROVED')
          ..approved = false)
      : HttpMynineApi(
          baseUrl: () => serverUrl.value,
          clientHeader: config.clientHeader,
          credentials: credentials,
          clock: clock,
        );

  final connection = ConnectionStatus();
  final answers = AnswerQueueRepository(db);
  final violations = ViolationQueueRepository(db);
  final sync = SyncService(
    api: api,
    db: db,
    answers: answers,
    violations: violations,
    connection: connection,
  );
  final device = DeviceRepository(
    api: api,
    store: store,
    credentials: credentials,
    lockdown: lockdown,
    appVersion: config.appVersion,
  );
  final exam = ExamController(
    api: api,
    db: db,
    clock: clock,
    examRepo: ExamRepository(api: api, db: db, paths: paths),
    answerQueue: answers,
    violationQueue: violations,
    sync: sync,
    device: device,
    connection: connection,
  );
  final updates = UpdateService(
    api: api,
    paths: paths,
    currentVersion: config.appVersion,
    runner: ProcessInstallerRunner(beforeExit: () async {
      await lockdown.disable();
    }),
  );
  final kiosk = KioskController(
    config: config,
    device: device,
    exam: exam,
    updates: updates,
    lockdown: lockdown,
    connection: connection,
    store: store,
    serverUrl: serverUrl,
  );

  await kiosk.init();
  await updates.startupSelfCheck();
  sync.start();

  return [
    appConfigProvider.overrideWithValue(config),
    appPathsProvider.overrideWithValue(paths),
    databaseProvider.overrideWithValue(db),
    serverClockProvider.overrideWithValue(clock),
    apiProvider.overrideWithValue(api),
    lockdownProvider.overrideWithValue(lockdown),
    connectionProvider.overrideWithValue(connection),
    syncServiceProvider.overrideWithValue(sync),
    deviceRepositoryProvider.overrideWithValue(device),
    examControllerProvider.overrideWithValue(exam),
    updateServiceProvider.overrideWithValue(updates),
    kioskControllerProvider.overrideWithValue(kiosk),
  ];
}
