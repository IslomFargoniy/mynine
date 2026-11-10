import 'dart:io';

import '../../data/models/app_models.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/part_payload.dart';

typedef ProgressCallback = void Function(int received, int total);

/// Device state reported in `POST /device/heartbeat`.
enum DeviceState { idle, updating, exam }

/// Desktop API v1 (see docs/desktop/API.md in the mynine.uz repo).
///
/// The device token is supplied by the implementation's credential holder;
/// exam endpoints take the exam token explicitly so that background sync of
/// an older session (after the Completed screen) can keep using its own token.
abstract class MynineApi {
  // ---- App / updates -------------------------------------------------------
  Future<AppVersionInfo> appVersion({String? current});

  // ---- Device --------------------------------------------------------------
  Future<DeviceRegistration> registerDevice({
    required String machineId,
    required String name,
    required String osVersion,
    required String appVersion,
  });

  Future<DeviceHeartbeat> deviceHeartbeat({
    required String appVersion,
    required DeviceState state,
  });

  /// Verifies the center exit password online. Returns false on 422.
  Future<bool> deviceUnlock(String password);

  Future<DeviceConfig> deviceConfig();

  // ---- Exam auth -----------------------------------------------------------
  Future<LoginResponse> login(String code);

  Future<void> logout(String examToken);

  // ---- Exam ------------------------------------------------------------------
  Future<ExamState> examState(String examToken);

  Future<PrefetchPayload> prefetch(String examToken);

  Future<PartPayload> part(String examToken, int partId);

  Future<ModuleStartResponse> startModule(String examToken, int typeId);

  Future<AnswersResponse> sendAnswers(String examToken, List<AnswerItem> answers);

  Future<ModuleSubmitResponse> submitModule(String examToken, int typeId);

  Future<ExamSubmitResponse> submitExam(String examToken);

  Future<ExamHeartbeatResponse> examHeartbeat(
    String examToken, {
    int? typeId,
    int? partId,
    required int queuedAnswers,
    required int queuedViolations,
    DateTime? onlineSince,
  });

  Future<ViolationsResponse> sendViolations(
    String examToken,
    List<ViolationItem> violations,
  );

  /// Downloads [url] into [target] with HTTP Range resume.
  ///
  /// Data is written to `<target>.part` first and renamed on completion, so an
  /// interrupted download continues where it stopped on the next call. The
  /// caller verifies the SHA-256.
  Future<File> download(
    String url,
    File target, {
    String? examToken,
    ProgressCallback? onProgress,
  });
}

/// Mutable holder for the device token (set after registration).
class DeviceCredentials {
  String? deviceToken;
}
