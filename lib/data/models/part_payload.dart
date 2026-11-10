import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

part 'part_payload.freezed.dart';
part 'part_payload.g.dart';

/// Question types (see API.md, PartPayload).
abstract final class QuestionType {
  static const multipleChoice = 'multiple_choice';
  static const multipleResponse = 'multiple_response';
  static const trueFalse = 'true_false';
  static const yesNo = 'yes_no';
  static const fillBlank = 'fill_blank';
  static const matching = 'matching';
  static const essay = 'essay';
  static const completeSection = 'complete_section';
  static const dragAndDrop = 'drag_and_drop';

  static const all = {
    multipleChoice,
    multipleResponse,
    trueFalse,
    yesNo,
    fillBlank,
    matching,
    essay,
    completeSection,
    dragAndDrop,
  };

  /// Types whose answer is a list of option ids.
  static const optionTypes = {multipleChoice, multipleResponse, trueFalse, yesNo};
}

/// One part of a module, with its sections and questions (answer keys stripped).
@freezed
abstract class PartPayload with _$PartPayload {
  const PartPayload._();

  const factory PartPayload({
    required int id,

    /// `listening` | `reading` | `writing`
    required String type,
    required int typeId,
    required String name,
    @Default(1) int order,
    @Default(1) int firstQuestionNumber,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String html,
    String? audioKey,
    @Default(<SectionPayload>[]) List<SectionPayload> sections,
  }) = _PartPayload;

  factory PartPayload.fromJson(Map<String, Object?> json) =>
      _$PartPayloadFromJson(json);

  Iterable<QuestionPayload> get allQuestions =>
      sections.expand((s) => s.questions);
}

@freezed
abstract class SectionPayload with _$SectionPayload {
  const SectionPayload._();

  const factory SectionPayload({
    required int id,
    required String questionType,
    @Default('text') String inputType,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String html,
    @JsonKey(fromJson: stringOrNull) String? fromOption,
    @JsonKey(fromJson: stringOrNull) String? toOption,
    @Default(<OptionPayload>[]) List<OptionPayload> options,
    @Default(<DragOptionPayload>[]) List<DragOptionPayload> dragOptions,
    @Default(<QuestionPayload>[]) List<QuestionPayload> questions,
  }) = _SectionPayload;

  factory SectionPayload.fromJson(Map<String, Object?> json) =>
      _$SectionPayloadFromJson(json);

  bool get usesOptionIds => QuestionType.optionTypes.contains(questionType);
}

@freezed
abstract class OptionPayload with _$OptionPayload {
  const factory OptionPayload({
    required int id,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String html,
  }) = _OptionPayload;

  factory OptionPayload.fromJson(Map<String, Object?> json) =>
      _$OptionPayloadFromJson(json);
}

@freezed
abstract class DragOptionPayload with _$DragOptionPayload {
  const factory DragOptionPayload({
    @JsonKey(fromJson: stringOrEmpty) required String id,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String label,
  }) = _DragOptionPayload;

  factory DragOptionPayload.fromJson(Map<String, Object?> json) =>
      _$DragOptionPayloadFromJson(json);
}

@freezed
abstract class QuestionPayload with _$QuestionPayload {
  const factory QuestionPayload({
    required int id,
    required int number,
    @Default(1) int order,
    @JsonKey(fromJson: stringOrEmpty) @Default('') String html,
    @Default(<OptionPayload>[]) List<OptionPayload> options,
    @Default(SavedAnswer()) SavedAnswer answer,

    /// How many question numbers the question covers (`number_count`;
    /// e.g. 2 for "Choose TWO letters"). `number` is the first of them.
    @JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson)
    @Default(1)
    int answerCount,
  }) = _QuestionPayload;

  factory QuestionPayload.fromJson(Map<String, Object?> json) =>
      _$QuestionPayloadFromJson(json);
}

int _answerCountFromJson(Object? value) {
  final n = intFrom(value, 1);
  return n < 1 ? 1 : n;
}

@freezed
abstract class SavedAnswer with _$SavedAnswer {
  const SavedAnswer._();

  const factory SavedAnswer({
    String? text,
    @Default(<int>[]) List<int> optionIds,
  }) = _SavedAnswer;

  factory SavedAnswer.fromJson(Map<String, Object?> json) =>
      _$SavedAnswerFromJson(json);

  bool get isAnswered =>
      optionIds.isNotEmpty || (text != null && text!.trim().isNotEmpty);
}
