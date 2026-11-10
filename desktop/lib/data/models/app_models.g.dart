// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateManifest _$UpdateManifestFromJson(Map<String, dynamic> json) =>
    _UpdateManifest(
      version: json['version'] == null ? '' : stringOrEmpty(json['version']),
      file: json['file'] == null ? '' : stringOrEmpty(json['file']),
      sha256: json['sha256'] == null ? '' : stringOrEmpty(json['sha256']),
      size: json['size'] == null ? 0 : intFrom(json['size']),
      mandatory: json['mandatory'] == null
          ? false
          : boolTrue(json['mandatory']),
      minVersion: stringOrNull(json['min_version']),
      notes: json['notes'] == null ? '' : stringOrEmpty(json['notes']),
      publishedAt: dateOrNull(json['published_at']),
    );

Map<String, dynamic> _$UpdateManifestToJson(_UpdateManifest instance) =>
    <String, dynamic>{
      'version': instance.version,
      'file': instance.file,
      'sha256': instance.sha256,
      'size': instance.size,
      'mandatory': instance.mandatory,
      'min_version': instance.minVersion,
      'notes': instance.notes,
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
