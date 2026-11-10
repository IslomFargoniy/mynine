import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

part 'app_models.freezed.dart';
part 'app_models.g.dart';

/// Static update manifest `{site}/desktop/version.json` (served by nginx from
/// the server's `public/desktop/` folder, next to the installers).
///
/// `sha256` / `size` are filled at release time; until then (or when `file`
/// is missing) the manifest is [isComplete] == false and means "no update".
@freezed
abstract class UpdateManifest with _$UpdateManifest {
  const UpdateManifest._();

  const factory UpdateManifest({
    @JsonKey(fromJson: stringOrEmpty) @Default('') String version,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String file,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String sha256,
    @JsonKey(fromJson: intFrom) @Default(0) int size,
    @JsonKey(fromJson: boolTrue) @Default(false) bool mandatory,
    @JsonKey(fromJson: stringOrNull) String? minVersion,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String notes,
    @JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? publishedAt,
  }) = _UpdateManifest;

  factory UpdateManifest.fromJson(Map<String, Object?> json) =>
      _$UpdateManifestFromJson(json);

  static final _semver = RegExp(r'^\d+\.\d+\.\d+$');
  static final _fileName = RegExp(r'^[A-Za-z0-9._-]+\.exe$');
  static final _sha = RegExp(r'^[0-9a-fA-F]{64}$');

  /// True when the manifest describes a downloadable, verifiable installer.
  bool get isComplete =>
      _semver.hasMatch(version) &&
      _fileName.hasMatch(file) &&
      !file.contains('..') &&
      _sha.hasMatch(sha256) &&
      size > 0;
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
