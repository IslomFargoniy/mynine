import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

part 'app_models.freezed.dart';
part 'app_models.g.dart';

/// `GET /app/version` response.
@freezed
abstract class AppVersionInfo with _$AppVersionInfo {
  const factory AppVersionInfo({
    ReleaseInfo? latest,
    String? minVersion,
    @Default(false) bool updateAvailable,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _AppVersionInfo;

  factory AppVersionInfo.fromJson(Map<String, Object?> json) =>
      _$AppVersionInfoFromJson(json);
}

@freezed
abstract class ReleaseInfo with _$ReleaseInfo {
  const factory ReleaseInfo({
    required String version,
    @Default('') String notes,
    @Default(false) bool mandatory,
    required String url,
    required String sha256,
    @Default(0) int size,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? publishedAt,
  }) = _ReleaseInfo;

  factory ReleaseInfo.fromJson(Map<String, Object?> json) =>
      _$ReleaseInfoFromJson(json);
}

/// `POST /device/register` response.
@freezed
abstract class DeviceRegistration with _$DeviceRegistration {
  const factory DeviceRegistration({
    required int deviceId,
    required String deviceToken,
    required String name,
  }) = _DeviceRegistration;

  factory DeviceRegistration.fromJson(Map<String, Object?> json) =>
      _$DeviceRegistrationFromJson(json);
}

/// `POST /device/heartbeat` response.
@freezed
abstract class DeviceHeartbeat with _$DeviceHeartbeat {
  const factory DeviceHeartbeat({
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
    @Default(false) bool unlock,
  }) = _DeviceHeartbeat;

  factory DeviceHeartbeat.fromJson(Map<String, Object?> json) =>
      _$DeviceHeartbeatFromJson(json);
}

/// `GET /device/config` response. Cached locally so the PC keeps working
/// (banned process list, offline exit password) while offline.
@freezed
abstract class DeviceConfig with _$DeviceConfig {
  const factory DeviceConfig({
    String? exitPasswordOffline,
    @Default(<String>[]) List<String> bannedProcesses,
    @Default(20) int heartbeatSeconds,
    @Default(10) int violationBatchSeconds,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,
  }) = _DeviceConfig;

  factory DeviceConfig.fromJson(Map<String, Object?> json) =>
      _$DeviceConfigFromJson(json);
}
