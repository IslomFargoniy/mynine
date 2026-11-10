// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppVersionInfo _$AppVersionInfoFromJson(Map<String, dynamic> json) =>
    _AppVersionInfo(
      latest: json['latest'] == null
          ? null
          : ReleaseInfo.fromJson(json['latest'] as Map<String, dynamic>),
      minVersion: json['min_version'] as String?,
      updateAvailable: json['update_available'] as bool? ?? false,
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$AppVersionInfoToJson(_AppVersionInfo instance) =>
    <String, dynamic>{
      'latest': instance.latest?.toJson(),
      'min_version': instance.minVersion,
      'update_available': instance.updateAvailable,
      'server_time': dateToJson(instance.serverTime),
    };

_ReleaseInfo _$ReleaseInfoFromJson(Map<String, dynamic> json) => _ReleaseInfo(
  version: json['version'] as String,
  notes: json['notes'] as String? ?? '',
  mandatory: json['mandatory'] as bool? ?? false,
  url: json['url'] as String,
  sha256: json['sha256'] as String,
  size: (json['size'] as num?)?.toInt() ?? 0,
  publishedAt: dateOrNull(json['published_at']),
);

Map<String, dynamic> _$ReleaseInfoToJson(_ReleaseInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'notes': instance.notes,
      'mandatory': instance.mandatory,
      'url': instance.url,
      'sha256': instance.sha256,
      'size': instance.size,
      'published_at': dateToJson(instance.publishedAt),
    };

_DeviceRegistration _$DeviceRegistrationFromJson(Map<String, dynamic> json) =>
    _DeviceRegistration(
      deviceId: (json['device_id'] as num).toInt(),
      deviceToken: json['device_token'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$DeviceRegistrationToJson(_DeviceRegistration instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'device_token': instance.deviceToken,
      'name': instance.name,
    };

_DeviceHeartbeat _$DeviceHeartbeatFromJson(Map<String, dynamic> json) =>
    _DeviceHeartbeat(
      serverTime: dateOrNull(json['server_time']),
      unlock: json['unlock'] as bool? ?? false,
    );

Map<String, dynamic> _$DeviceHeartbeatToJson(_DeviceHeartbeat instance) =>
    <String, dynamic>{
      'server_time': dateToJson(instance.serverTime),
      'unlock': instance.unlock,
    };

_DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) =>
    _DeviceConfig(
      exitPasswordOffline: json['exit_password_offline'] as String?,
      bannedProcesses:
          (json['banned_processes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      heartbeatSeconds: (json['heartbeat_seconds'] as num?)?.toInt() ?? 20,
      violationBatchSeconds:
          (json['violation_batch_seconds'] as num?)?.toInt() ?? 10,
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$DeviceConfigToJson(_DeviceConfig instance) =>
    <String, dynamic>{
      'exit_password_offline': instance.exitPasswordOffline,
      'banned_processes': instance.bannedProcesses,
      'heartbeat_seconds': instance.heartbeatSeconds,
      'violation_batch_seconds': instance.violationBatchSeconds,
      'server_time': dateToJson(instance.serverTime),
    };
