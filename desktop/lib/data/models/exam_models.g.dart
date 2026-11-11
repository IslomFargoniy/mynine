// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    _LoginResponse(
      token: json['token'] as String,
      expiresAt: dateOrNull(json['expires_at']),
      candidate: Candidate.fromJson(json['candidate'] as Map<String, dynamic>),
      mock: MockInfo.fromJson(json['mock'] as Map<String, dynamic>),
      attemptId: (json['attempt_id'] as num).toInt(),
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$LoginResponseToJson(_LoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expires_at': dateToJson(instance.expiresAt),
      'candidate': instance.candidate.toJson(),
      'mock': instance.mock.toJson(),
      'attempt_id': instance.attemptId,
      'server_time': dateToJson(instance.serverTime),
    };

_Candidate _$CandidateFromJson(Map<String, dynamic> json) => _Candidate(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$CandidateToJson(_Candidate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
    };

_MockInfo _$MockInfoFromJson(Map<String, dynamic> json) => _MockInfo(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  startsAt: dateOrNull(json['starts_at']),
  endsAt: dateOrNull(json['ends_at']),
);

Map<String, dynamic> _$MockInfoToJson(_MockInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'starts_at': dateToJson(instance.startsAt),
  'ends_at': dateToJson(instance.endsAt),
};

_ExamState _$ExamStateFromJson(Map<String, dynamic> json) => _ExamState(
  attempt: AttemptInfo.fromJson(json['attempt'] as Map<String, dynamic>),
  modules:
      (json['modules'] as List<dynamic>?)
          ?.map((e) => ExamModule.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ExamModule>[],
  serverTime: dateOrNull(json['server_time']),
);

Map<String, dynamic> _$ExamStateToJson(_ExamState instance) =>
    <String, dynamic>{
      'attempt': instance.attempt.toJson(),
      'modules': instance.modules.map((e) => e.toJson()).toList(),
      'server_time': dateToJson(instance.serverTime),
    };

_AttemptInfo _$AttemptInfoFromJson(Map<String, dynamic> json) => _AttemptInfo(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String? ?? 'in_progress',
  paused: json['paused'] as bool? ?? false,
  finished: json['finished'] as bool? ?? false,
);

Map<String, dynamic> _$AttemptInfoToJson(_AttemptInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'paused': instance.paused,
      'finished': instance.finished,
    };

_ExamModule _$ExamModuleFromJson(Map<String, dynamic> json) => _ExamModule(
  typeId: (json['type_id'] as num).toInt(),
  type: json['type'] as String,
  title: json['title'] as String,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? ModuleStatus.notStarted,
  startedAt: dateOrNull(json['started_at']),
  finishedAt: dateOrNull(json['finished_at']),
  audio: json['audio'] == null
      ? null
      : ModuleAudio.fromJson(json['audio'] as Map<String, dynamic>),
  parts:
      (json['parts'] as List<dynamic>?)
          ?.map((e) => PartSummary.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PartSummary>[],
);

Map<String, dynamic> _$ExamModuleToJson(_ExamModule instance) =>
    <String, dynamic>{
      'type_id': instance.typeId,
      'type': instance.type,
      'title': instance.title,
      'duration_seconds': instance.durationSeconds,
      'status': instance.status,
      'started_at': dateToJson(instance.startedAt),
      'finished_at': dateToJson(instance.finishedAt),
      'audio': instance.audio?.toJson(),
      'parts': instance.parts.map((e) => e.toJson()).toList(),
    };

_ModuleAudio _$ModuleAudioFromJson(Map<String, dynamic> json) => _ModuleAudio(
  url: json['url'] as String,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ModuleAudioToJson(_ModuleAudio instance) =>
    <String, dynamic>{
      'url': instance.url,
      'duration_seconds': instance.durationSeconds,
    };

_PartSummary _$PartSummaryFromJson(Map<String, dynamic> json) => _PartSummary(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  order: (json['order'] as num?)?.toInt() ?? 1,
  questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
  firstQuestionNumber: (json['first_question_number'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$PartSummaryToJson(_PartSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'order': instance.order,
      'question_count': instance.questionCount,
      'first_question_number': instance.firstQuestionNumber,
    };

_PrefetchPayload _$PrefetchPayloadFromJson(Map<String, dynamic> json) =>
    _PrefetchPayload(
      modules:
          (json['modules'] as List<dynamic>?)
              ?.map((e) => ExamModule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ExamModule>[],
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map((e) => PartPayload.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PartPayload>[],
      audio:
          (json['audio'] as List<dynamic>?)
              ?.map((e) => AudioAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AudioAsset>[],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$PrefetchPayloadToJson(_PrefetchPayload instance) =>
    <String, dynamic>{
      'modules': instance.modules.map((e) => e.toJson()).toList(),
      'parts': instance.parts.map((e) => e.toJson()).toList(),
      'audio': instance.audio.map((e) => e.toJson()).toList(),
      'images': instance.images,
      'server_time': dateToJson(instance.serverTime),
    };

_AudioAsset _$AudioAssetFromJson(Map<String, dynamic> json) => _AudioAsset(
  key: json['key'] as String,
  url: json['url'] as String,
  size: (json['size'] as num?)?.toInt() ?? 0,
  sha256: json['sha256'] as String?,
);

Map<String, dynamic> _$AudioAssetToJson(_AudioAsset instance) =>
    <String, dynamic>{
      'key': instance.key,
      'url': instance.url,
      'size': instance.size,
      'sha256': instance.sha256,
    };

_ModuleStartResponse _$ModuleStartResponseFromJson(Map<String, dynamic> json) =>
    _ModuleStartResponse(
      typeId: (json['type_id'] as num).toInt(),
      status: json['status'] as String,
      startedAt: dateOrNull(json['started_at']),
      finishedAt: dateOrNull(json['finished_at']),
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$ModuleStartResponseToJson(
  _ModuleStartResponse instance,
) => <String, dynamic>{
  'type_id': instance.typeId,
  'status': instance.status,
  'started_at': dateToJson(instance.startedAt),
  'finished_at': dateToJson(instance.finishedAt),
  'server_time': dateToJson(instance.serverTime),
};

_ModuleSubmitResponse _$ModuleSubmitResponseFromJson(
  Map<String, dynamic> json,
) => _ModuleSubmitResponse(
  typeId: (json['type_id'] as num).toInt(),
  status: json['status'] as String,
  serverTime: dateOrNull(json['server_time']),
);

Map<String, dynamic> _$ModuleSubmitResponseToJson(
  _ModuleSubmitResponse instance,
) => <String, dynamic>{
  'type_id': instance.typeId,
  'status': instance.status,
  'server_time': dateToJson(instance.serverTime),
};

_ExamSubmitResponse _$ExamSubmitResponseFromJson(Map<String, dynamic> json) =>
    _ExamSubmitResponse(
      status: json['status'] as String,
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$ExamSubmitResponseToJson(_ExamSubmitResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'server_time': dateToJson(instance.serverTime),
    };

_AnswerItem _$AnswerItemFromJson(Map<String, dynamic> json) => _AnswerItem(
  clientUuid: json['client_uuid'] as String,
  partId: (json['part_id'] as num).toInt(),
  questionId: (json['question_id'] as num).toInt(),
  text: json['text'] as String?,
  optionIds:
      (json['option_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  changedAt: dateRequired(json['changed_at']),
  seq: (json['seq'] as num?)?.toInt(),
);

Map<String, dynamic> _$AnswerItemToJson(_AnswerItem instance) =>
    <String, dynamic>{
      'client_uuid': instance.clientUuid,
      'part_id': instance.partId,
      'question_id': instance.questionId,
      'text': instance.text,
      'option_ids': instance.optionIds,
      'changed_at': dateRequiredToJson(instance.changedAt),
      'seq': ?instance.seq,
    };

_AnswerResult _$AnswerResultFromJson(Map<String, dynamic> json) =>
    _AnswerResult(
      clientUuid: json['client_uuid'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$AnswerResultToJson(_AnswerResult instance) =>
    <String, dynamic>{
      'client_uuid': instance.clientUuid,
      'status': instance.status,
      'reason': instance.reason,
    };

_AnswersResponse _$AnswersResponseFromJson(Map<String, dynamic> json) =>
    _AnswersResponse(
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => AnswerResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AnswerResult>[],
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$AnswersResponseToJson(_AnswersResponse instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
      'server_time': dateToJson(instance.serverTime),
    };

_ExamHeartbeatResponse _$ExamHeartbeatResponseFromJson(
  Map<String, dynamic> json,
) => _ExamHeartbeatResponse(
  serverTime: dateOrNull(json['server_time']),
  paused: json['paused'] as bool? ?? false,
  finished: json['finished'] as bool? ?? false,
  unlock: json['unlock'] as bool? ?? false,
  modules:
      (json['modules'] as List<dynamic>?)
          ?.map((e) => ModuleTimer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ModuleTimer>[],
  expiresAt: dateOrNull(json['expires_at']),
);

Map<String, dynamic> _$ExamHeartbeatResponseToJson(
  _ExamHeartbeatResponse instance,
) => <String, dynamic>{
  'server_time': dateToJson(instance.serverTime),
  'paused': instance.paused,
  'finished': instance.finished,
  'unlock': instance.unlock,
  'modules': instance.modules.map((e) => e.toJson()).toList(),
  'expires_at': dateToJson(instance.expiresAt),
};

_ModuleTimer _$ModuleTimerFromJson(Map<String, dynamic> json) => _ModuleTimer(
  typeId: (json['type_id'] as num).toInt(),
  status: json['status'] as String,
  finishedAt: dateOrNull(json['finished_at']),
);

Map<String, dynamic> _$ModuleTimerToJson(_ModuleTimer instance) =>
    <String, dynamic>{
      'type_id': instance.typeId,
      'status': instance.status,
      'finished_at': dateToJson(instance.finishedAt),
    };

_ViolationItem _$ViolationItemFromJson(Map<String, dynamic> json) =>
    _ViolationItem(
      clientUuid: json['client_uuid'] as String,
      type: json['type'] as String,
      detail: json['detail'] as Map<String, dynamic>?,
      occurredAt: dateRequired(json['occurred_at']),
    );

Map<String, dynamic> _$ViolationItemToJson(_ViolationItem instance) =>
    <String, dynamic>{
      'client_uuid': instance.clientUuid,
      'type': instance.type,
      'detail': instance.detail,
      'occurred_at': dateRequiredToJson(instance.occurredAt),
    };

_ViolationsResponse _$ViolationsResponseFromJson(Map<String, dynamic> json) =>
    _ViolationsResponse(
      accepted: (json['accepted'] as num?)?.toInt() ?? 0,
      serverTime: dateOrNull(json['server_time']),
    );

Map<String, dynamic> _$ViolationsResponseToJson(_ViolationsResponse instance) =>
    <String, dynamic>{
      'accepted': instance.accepted,
      'server_time': dateToJson(instance.serverTime),
    };
