// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'part_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PartPayload _$PartPayloadFromJson(Map<String, dynamic> json) => _PartPayload(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  typeId: (json['type_id'] as num).toInt(),
  name: json['name'] as String,
  order: (json['order'] as num?)?.toInt() ?? 1,
  firstQuestionNumber: (json['first_question_number'] as num?)?.toInt() ?? 1,
  html: json['html'] == null ? '' : stringOrEmpty(json['html']),
  audioKey: json['audio_key'] as String?,
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => SectionPayload.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SectionPayload>[],
);

Map<String, dynamic> _$PartPayloadToJson(_PartPayload instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'type_id': instance.typeId,
      'name': instance.name,
      'order': instance.order,
      'first_question_number': instance.firstQuestionNumber,
      'html': instance.html,
      'audio_key': instance.audioKey,
      'sections': instance.sections.map((e) => e.toJson()).toList(),
    };

_SectionPayload _$SectionPayloadFromJson(Map<String, dynamic> json) =>
    _SectionPayload(
      id: (json['id'] as num).toInt(),
      questionType: json['question_type'] as String,
      inputType: json['input_type'] as String? ?? 'text',
      html: json['html'] == null ? '' : stringOrEmpty(json['html']),
      fromOption: stringOrNull(json['from_option']),
      toOption: stringOrNull(json['to_option']),
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => OptionPayload.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OptionPayload>[],
      dragOptions:
          (json['drag_options'] as List<dynamic>?)
              ?.map(
                (e) => DragOptionPayload.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <DragOptionPayload>[],
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionPayload.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <QuestionPayload>[],
    );

Map<String, dynamic> _$SectionPayloadToJson(_SectionPayload instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question_type': instance.questionType,
      'input_type': instance.inputType,
      'html': instance.html,
      'from_option': instance.fromOption,
      'to_option': instance.toOption,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'drag_options': instance.dragOptions.map((e) => e.toJson()).toList(),
      'questions': instance.questions.map((e) => e.toJson()).toList(),
    };

_OptionPayload _$OptionPayloadFromJson(Map<String, dynamic> json) =>
    _OptionPayload(
      id: (json['id'] as num).toInt(),
      html: json['html'] == null ? '' : stringOrEmpty(json['html']),
    );

Map<String, dynamic> _$OptionPayloadToJson(_OptionPayload instance) =>
    <String, dynamic>{'id': instance.id, 'html': instance.html};

_DragOptionPayload _$DragOptionPayloadFromJson(Map<String, dynamic> json) =>
    _DragOptionPayload(
      id: stringOrEmpty(json['id']),
      label: json['label'] == null ? '' : stringOrEmpty(json['label']),
    );

Map<String, dynamic> _$DragOptionPayloadToJson(_DragOptionPayload instance) =>
    <String, dynamic>{'id': instance.id, 'label': instance.label};

_QuestionPayload _$QuestionPayloadFromJson(Map<String, dynamic> json) =>
    _QuestionPayload(
      id: (json['id'] as num).toInt(),
      number: (json['number'] as num).toInt(),
      order: (json['order'] as num?)?.toInt() ?? 1,
      html: json['html'] == null ? '' : stringOrEmpty(json['html']),
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => OptionPayload.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OptionPayload>[],
      answer: json['answer'] == null
          ? const SavedAnswer()
          : SavedAnswer.fromJson(json['answer'] as Map<String, dynamic>),
      answerCount: readAnswerCount(json, 'number_count') == null
          ? 1
          : _answerCountFromJson(readAnswerCount(json, 'number_count')),
    );

Map<String, dynamic> _$QuestionPayloadToJson(_QuestionPayload instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'order': instance.order,
      'html': instance.html,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'answer': instance.answer.toJson(),
      'number_count': instance.answerCount,
    };

_SavedAnswer _$SavedAnswerFromJson(Map<String, dynamic> json) => _SavedAnswer(
  text: json['text'] as String?,
  optionIds:
      (json['option_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
);

Map<String, dynamic> _$SavedAnswerToJson(_SavedAnswer instance) =>
    <String, dynamic>{'text': instance.text, 'option_ids': instance.optionIds};
