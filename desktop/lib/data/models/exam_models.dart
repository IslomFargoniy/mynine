import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';
import 'part_payload.dart';

part 'exam_models.freezed.dart';
part 'exam_models.g.dart';

/// `POST /exam/login` response.
@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String token,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? expiresAt,
    required Candidate candidate,
    required MockInfo mock,
    required int attemptId,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, Object?> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
abstract class Candidate with _$Candidate {
  const factory Candidate({
    required int id,
    required String name,
    required String code,
  }) = _Candidate;

  factory Candidate.fromJson(Map<String, Object?> json) =>
      _$CandidateFromJson(json);
}

@freezed
abstract class MockInfo with _$MockInfo {
  const factory MockInfo({
    required int id,
    required String name,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startsAt,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? endsAt,
  }) = _MockInfo;

  factory MockInfo.fromJson(Map<String, Object?> json) =>
      _$MockInfoFromJson(json);
}

/// Module status strings used by the server.
abstract final class ModuleStatus {
  static const notStarted = 'not_started';
  static const inProgress = 'in_progress';
  static const submitted = 'submitted';
}

/// `GET /exam` response.
@freezed
abstract class ExamState with _$ExamState {
  const factory ExamState({
    required AttemptInfo attempt,
    @Default(<ExamModule>[]) List<ExamModule> modules,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _ExamState;

  factory ExamState.fromJson(Map<String, Object?> json) =>
      _$ExamStateFromJson(json);
}

@freezed
abstract class AttemptInfo with _$AttemptInfo {
  const factory AttemptInfo({
    required int id,
    @Default('in_progress') String status,
    @Default(false) bool paused,
    @Default(false) bool finished,
  }) = _AttemptInfo;

  factory AttemptInfo.fromJson(Map<String, Object?> json) =>
      _$AttemptInfoFromJson(json);
}

@freezed
abstract class ExamModule with _$ExamModule {
  const ExamModule._();

  const factory ExamModule({
    required int typeId,

    /// `listening` | `reading` | `writing`
    required String type,
    required String title,
    @Default(0) int durationSeconds,
    @Default(ModuleStatus.notStarted) String status,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startedAt,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt,
    ModuleAudio? audio,
    @Default(<PartSummary>[]) List<PartSummary> parts,
  }) = _ExamModule;

  factory ExamModule.fromJson(Map<String, Object?> json) =>
      _$ExamModuleFromJson(json);

  bool get isListening => type == 'listening';
  bool get isReading => type == 'reading';
  bool get isWriting => type == 'writing';
  bool get isSubmitted => status == ModuleStatus.submitted;
  bool get isInProgress => status == ModuleStatus.inProgress;
  bool get isNotStarted => status == ModuleStatus.notStarted;
}

@freezed
abstract class ModuleAudio with _$ModuleAudio {
  const factory ModuleAudio({
    required String url,
    @Default(0) int durationSeconds,
  }) = _ModuleAudio;

  factory ModuleAudio.fromJson(Map<String, Object?> json) =>
      _$ModuleAudioFromJson(json);
}

@freezed
abstract class PartSummary with _$PartSummary {
  const factory PartSummary({
    required int id,
    required String name,
    @Default(1) int order,
    @Default(0) int questionCount,
    @Default(1) int firstQuestionNumber,
  }) = _PartSummary;

  factory PartSummary.fromJson(Map<String, Object?> json) =>
      _$PartSummaryFromJson(json);
}

/// `GET /exam/prefetch` response.
@freezed
abstract class PrefetchPayload with _$PrefetchPayload {
  const factory PrefetchPayload({
    @Default(<ExamModule>[]) List<ExamModule> modules,
    @Default(<PartPayload>[]) List<PartPayload> parts,
    @Default(<AudioAsset>[]) List<AudioAsset> audio,
    @Default(<String>[]) List<String> images,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _PrefetchPayload;

  factory PrefetchPayload.fromJson(Map<String, Object?> json) =>
      _$PrefetchPayloadFromJson(json);
}

@freezed
abstract class AudioAsset with _$AudioAsset {
  const factory AudioAsset({
    required String key,
    required String url,
    @Default(0) int size,
    String? sha256,
  }) = _AudioAsset;

  factory AudioAsset.fromJson(Map<String, Object?> json) =>
      _$AudioAssetFromJson(json);
}

/// `POST /exam/modules/{type_id}/start` response.
@freezed
abstract class ModuleStartResponse with _$ModuleStartResponse {
  const factory ModuleStartResponse({
    required int typeId,
    required String status,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startedAt,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _ModuleStartResponse;

  factory ModuleStartResponse.fromJson(Map<String, Object?> json) =>
      _$ModuleStartResponseFromJson(json);
}

/// `POST /exam/modules/{type_id}/submit` response.
@freezed
abstract class ModuleSubmitResponse with _$ModuleSubmitResponse {
  const factory ModuleSubmitResponse({
    required int typeId,
    required String status,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _ModuleSubmitResponse;

  factory ModuleSubmitResponse.fromJson(Map<String, Object?> json) =>
      _$ModuleSubmitResponseFromJson(json);
}

/// `POST /exam/submit` response.
@freezed
abstract class ExamSubmitResponse with _$ExamSubmitResponse {
  const factory ExamSubmitResponse({
    required String status,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _ExamSubmitResponse;

  factory ExamSubmitResponse.fromJson(Map<String, Object?> json) =>
      _$ExamSubmitResponseFromJson(json);
}

/// One queued answer change (`POST /exam/answers` item).
@freezed
abstract class AnswerItem with _$AnswerItem {
  const factory AnswerItem({
    required String clientUuid,
    required int partId,
    required int questionId,
    String? text,
    @Default(<int>[]) List<int> optionIds,
    @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)
    required DateTime changedAt,

    /// API v1.1: client-side counter per question per attempt (monotonic,
    /// persisted), used by the server for last-write-wins. Omitted when null.
    @JsonKey(includeIfNull: false) int? seq,
  }) = _AnswerItem;

  factory AnswerItem.fromJson(Map<String, Object?> json) =>
      _$AnswerItemFromJson(json);
}

/// Result statuses for `POST /exam/answers`.
abstract final class AnswerResultStatus {
  static const saved = 'saved';
  static const duplicate = 'duplicate';
  static const stale = 'stale';
  static const rejected = 'rejected';

  /// API v1.1: not applied yet (attempt paused) — keep the item queued and
  /// send it again after the resume.
  static const deferred = 'deferred';

  /// Final statuses: the item is removed from the queue. `deferred` (and any
  /// unknown status) keeps it queued.
  static const finalStatuses = {saved, duplicate, stale, rejected};
}

@freezed
abstract class AnswerResult with _$AnswerResult {
  const factory AnswerResult({
    required String clientUuid,
    required String status,
    String? reason,
  }) = _AnswerResult;

  factory AnswerResult.fromJson(Map<String, Object?> json) =>
      _$AnswerResultFromJson(json);
}

@freezed
abstract class AnswersResponse with _$AnswersResponse {
  const factory AnswersResponse({
    @Default(<AnswerResult>[]) List<AnswerResult> results,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _AnswersResponse;

  factory AnswersResponse.fromJson(Map<String, Object?> json) =>
      _$AnswersResponseFromJson(json);
}

/// `POST /exam/heartbeat` response.
@freezed
abstract class ExamHeartbeatResponse with _$ExamHeartbeatResponse {
  const factory ExamHeartbeatResponse({
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
    @Default(false) bool paused,
    @Default(false) bool finished,
    @Default(false) bool unlock,
    @Default(<ModuleTimer>[]) List<ModuleTimer> modules,

    /// API v1.1: the heartbeat extends the exam token (optional field).
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? expiresAt,
  }) = _ExamHeartbeatResponse;

  factory ExamHeartbeatResponse.fromJson(Map<String, Object?> json) =>
      _$ExamHeartbeatResponseFromJson(json);
}

@freezed
abstract class ModuleTimer with _$ModuleTimer {
  const factory ModuleTimer({
    required int typeId,
    required String status,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt,
  }) = _ModuleTimer;

  factory ModuleTimer.fromJson(Map<String, Object?> json) =>
      _$ModuleTimerFromJson(json);
}

/// Violation types accepted by `POST /exam/violations`.
abstract final class ViolationType {
  static const focusLost = 'focus_lost';
  static const secondMonitor = 'second_monitor';
  static const bannedProcess = 'banned_process';
  static const screenCaptureAttempt = 'screen_capture_attempt';
  static const appRestarted = 'app_restarted';
  static const networkLost = 'network_lost';
  static const clipboard = 'clipboard';
  static const vmDetected = 'vm_detected';
}

@freezed
abstract class ViolationItem with _$ViolationItem {
  const factory ViolationItem({
    required String clientUuid,
    required String type,
    Map<String, Object?>? detail,
    @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)
    required DateTime occurredAt,
  }) = _ViolationItem;

  factory ViolationItem.fromJson(Map<String, Object?> json) =>
      _$ViolationItemFromJson(json);
}

@freezed
abstract class ViolationsResponse with _$ViolationsResponse {
  const factory ViolationsResponse({
    @Default(0) int accepted,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _ViolationsResponse;

  factory ViolationsResponse.fromJson(Map<String, Object?> json) =>
      _$ViolationsResponseFromJson(json);
}
