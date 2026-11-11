// Shared test harness: real controller + drift (in memory) + fake API.
import 'dart:io';

import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/api/mynine_api.dart';
import 'package:mynine_desktop/core/storage/app_paths.dart';
import 'package:mynine_desktop/core/storage/settings_store.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/data/db/app_database.dart';
import 'package:mynine_desktop/data/repositories/answer_queue.dart';
import 'package:mynine_desktop/data/repositories/device_repository.dart';
import 'package:mynine_desktop/data/repositories/exam_repository.dart';
import 'package:mynine_desktop/data/repositories/sync_service.dart';
import 'package:mynine_desktop/data/repositories/violation_queue.dart';
import 'package:mynine_desktop/features/exam/exam_controller.dart';
import 'package:mynine_desktop/platform/lockdown/lockdown.dart';

class Harness {
  Harness._(this.api, this.db, this.exam, this.device, this.sync, this.tmp, this.clock);

  final FakeMynineApi api;
  final AppDatabase db;
  final ExamController exam;
  final DeviceRepository device;
  final SyncService sync;
  final Directory tmp;
  final ServerClock clock;

  /// Builds the harness with the PC already registered (center password
  /// `mynine`). [approved] = admin approval; [number] = its exam-room number
  /// (null keeps the exam header as in the goldens). [register] = false
  /// leaves the PC unregistered (Setup screen).
  static Future<Harness> create({
    bool approved = true,
    int? number,
    bool register = true,
    DateTime Function()? now,
  }) async {
    final tmp = await Directory.systemTemp.createTemp('mynine_exam');
    final clock = ServerClock(localNow: now);
    final api = FakeMynineApi(clock: clock, latency: Duration.zero, now: now == null ? null : () => now().toUtc())
      ..autoApprove = approved
      ..approved = approved
      ..number = number;
    final db = AppDatabase.memory();
    final answers = AnswerQueueRepository(db);
    final violations = ViolationQueueRepository(db);
    final connection = ConnectionStatus();
    final sync = SyncService(
        api: api, db: db, answers: answers, violations: violations, connection: connection);
    final device = DeviceRepository(
      api: api,
      store: MemorySettingsStore(),
      credentials: DeviceCredentials(),
      lockdown: NoopLockdown(),
      appVersion: '1.0.0',
    );
    await device.load();
    if (register) await device.register(password: FakeMynineApi.exitPassword);
    final exam = ExamController(
      api: api,
      db: db,
      clock: clock,
      examRepo: ExamRepository(api: api, db: db, paths: AppPaths(tmp)),
      answerQueue: answers,
      violationQueue: violations,
      sync: sync,
      device: device,
      connection: connection,
    );
    return Harness._(api, db, exam, device, sync, tmp, clock);
  }

  Future<void> dispose() async {
    exam.dispose();
    sync.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  }
}

Future<void> waitFor(bool Function() cond, {Duration timeout = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(end)) throw StateError('timeout');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

