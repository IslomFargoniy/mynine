// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'part_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PartPayload {

 int get id;/// `listening` | `reading` | `writing`
 String get type; int get typeId; String get name; int get order; int get firstQuestionNumber;@JsonKey(fromJson: stringOrEmpty) String get html; String? get audioKey; List<SectionPayload> get sections;
/// Create a copy of PartPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartPayloadCopyWith<PartPayload> get copyWith => _$PartPayloadCopyWithImpl<PartPayload>(this as PartPayload, _$identity);

  /// Serializes this PartPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PartPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartPayload&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.typeId, _this.typeId) || other.typeId == _this.typeId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.firstQuestionNumber, _this.firstQuestionNumber) || other.firstQuestionNumber == _this.firstQuestionNumber)&&(identical(other.html, _this.html) || other.html == _this.html)&&(identical(other.audioKey, _this.audioKey) || other.audioKey == _this.audioKey)&&const DeepCollectionEquality().equals(other.sections, _this.sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PartPayload;
  return Object.hash(runtimeType,_this.id,_this.type,_this.typeId,_this.name,_this.order,_this.firstQuestionNumber,_this.html,_this.audioKey,const DeepCollectionEquality().hash(_this.sections));
}

@override
String toString() {
  final _this = this as PartPayload;
  return 'PartPayload(id: ${_this.id}, type: ${_this.type}, typeId: ${_this.typeId}, name: ${_this.name}, order: ${_this.order}, firstQuestionNumber: ${_this.firstQuestionNumber}, html: ${_this.html}, audioKey: ${_this.audioKey}, sections: ${_this.sections})';
}


}

/// @nodoc
abstract mixin class $PartPayloadCopyWith<$Res>  {
  factory $PartPayloadCopyWith(PartPayload value, $Res Function(PartPayload) _then) = _$PartPayloadCopyWithImpl;
@useResult
$Res call({
 int id, String type, int typeId, String name, int order, int firstQuestionNumber,@JsonKey(fromJson: stringOrEmpty) String html, String? audioKey, List<SectionPayload> sections
});




}
/// @nodoc
class _$PartPayloadCopyWithImpl<$Res>
    implements $PartPayloadCopyWith<$Res> {
  _$PartPayloadCopyWithImpl(this._self, this._then);

  final PartPayload _self;
  final $Res Function(PartPayload) _then;

/// Create a copy of PartPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? typeId = null,Object? name = null,Object? order = null,Object? firstQuestionNumber = null,Object? html = null,Object? audioKey = freezed,Object? sections = null,}) {
  return _then(PartPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,firstQuestionNumber: null == firstQuestionNumber ? _self.firstQuestionNumber : firstQuestionNumber // ignore: cast_nullable_to_non_nullable
as int,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,audioKey: freezed == audioKey ? _self.audioKey : audioKey // ignore: cast_nullable_to_non_nullable
as String?,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<SectionPayload>,
  ));
}

}


/// Adds pattern-matching-related methods to [PartPayload].
extension PartPayloadPatterns on PartPayload {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartPayload() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartPayload value)  $default,){
final _that = this;
switch (_that) {
case _PartPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartPayload value)?  $default,){
final _that = this;
switch (_that) {
case _PartPayload() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  int typeId,  String name,  int order,  int firstQuestionNumber, @JsonKey(fromJson: stringOrEmpty)  String html,  String? audioKey,  List<SectionPayload> sections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartPayload() when $default != null:
return $default(_that.id,_that.type,_that.typeId,_that.name,_that.order,_that.firstQuestionNumber,_that.html,_that.audioKey,_that.sections);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  int typeId,  String name,  int order,  int firstQuestionNumber, @JsonKey(fromJson: stringOrEmpty)  String html,  String? audioKey,  List<SectionPayload> sections)  $default,) {final _that = this;
switch (_that) {
case _PartPayload():
return $default(_that.id,_that.type,_that.typeId,_that.name,_that.order,_that.firstQuestionNumber,_that.html,_that.audioKey,_that.sections);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  int typeId,  String name,  int order,  int firstQuestionNumber, @JsonKey(fromJson: stringOrEmpty)  String html,  String? audioKey,  List<SectionPayload> sections)?  $default,) {final _that = this;
switch (_that) {
case _PartPayload() when $default != null:
return $default(_that.id,_that.type,_that.typeId,_that.name,_that.order,_that.firstQuestionNumber,_that.html,_that.audioKey,_that.sections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PartPayload extends PartPayload {
  const _PartPayload({required this.id, required this.type, required this.typeId, required this.name, this.order = 1, this.firstQuestionNumber = 1, @JsonKey(fromJson: stringOrEmpty) this.html = '', this.audioKey,  List<SectionPayload> sections = const <SectionPayload>[]}): _sections = sections,super._();
  factory _PartPayload.fromJson(Map<String, dynamic> json) => _$PartPayloadFromJson(json);

@override final  int id;
/// `listening` | `reading` | `writing`
@override final  String type;
@override final  int typeId;
@override final  String name;
@override@JsonKey() final  int order;
@override@JsonKey() final  int firstQuestionNumber;
@override@JsonKey(fromJson: stringOrEmpty) final  String html;
@override final  String? audioKey;
 final  List<SectionPayload> _sections;
@override@JsonKey() List<SectionPayload> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}


/// Create a copy of PartPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartPayloadCopyWith<_PartPayload> get copyWith => __$PartPayloadCopyWithImpl<_PartPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeId, typeId) || other.typeId == typeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.firstQuestionNumber, firstQuestionNumber) || other.firstQuestionNumber == firstQuestionNumber)&&(identical(other.html, html) || other.html == html)&&(identical(other.audioKey, audioKey) || other.audioKey == audioKey)&&const DeepCollectionEquality().equals(other.sections, _sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,typeId,name,order,firstQuestionNumber,html,audioKey,const DeepCollectionEquality().hash(_sections));
}

@override
String toString() {
    return 'PartPayload(id: $id, type: $type, typeId: $typeId, name: $name, order: $order, firstQuestionNumber: $firstQuestionNumber, html: $html, audioKey: $audioKey, sections: $sections)';
}


}

/// @nodoc
abstract mixin class _$PartPayloadCopyWith<$Res> implements $PartPayloadCopyWith<$Res> {
  factory _$PartPayloadCopyWith(_PartPayload value, $Res Function(_PartPayload) _then) = __$PartPayloadCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, int typeId, String name, int order, int firstQuestionNumber,@JsonKey(fromJson: stringOrEmpty) String html, String? audioKey, List<SectionPayload> sections
});




}
/// @nodoc
class __$PartPayloadCopyWithImpl<$Res>
    implements _$PartPayloadCopyWith<$Res> {
  __$PartPayloadCopyWithImpl(this._self, this._then);

  final _PartPayload _self;
  final $Res Function(_PartPayload) _then;

/// Create a copy of PartPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? typeId = null,Object? name = null,Object? order = null,Object? firstQuestionNumber = null,Object? html = null,Object? audioKey = freezed,Object? sections = null,}) {
  return _then(_PartPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,firstQuestionNumber: null == firstQuestionNumber ? _self.firstQuestionNumber : firstQuestionNumber // ignore: cast_nullable_to_non_nullable
as int,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,audioKey: freezed == audioKey ? _self.audioKey : audioKey // ignore: cast_nullable_to_non_nullable
as String?,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<SectionPayload>,
  ));
}


}


/// @nodoc
mixin _$SectionPayload {

 int get id; String get questionType; String get inputType;@JsonKey(fromJson: stringOrEmpty) String get html;@JsonKey(fromJson: stringOrNull) String? get fromOption;@JsonKey(fromJson: stringOrNull) String? get toOption; List<OptionPayload> get options; List<DragOptionPayload> get dragOptions; List<QuestionPayload> get questions;
/// Create a copy of SectionPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectionPayloadCopyWith<SectionPayload> get copyWith => _$SectionPayloadCopyWithImpl<SectionPayload>(this as SectionPayload, _$identity);

  /// Serializes this SectionPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SectionPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectionPayload&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.questionType, _this.questionType) || other.questionType == _this.questionType)&&(identical(other.inputType, _this.inputType) || other.inputType == _this.inputType)&&(identical(other.html, _this.html) || other.html == _this.html)&&(identical(other.fromOption, _this.fromOption) || other.fromOption == _this.fromOption)&&(identical(other.toOption, _this.toOption) || other.toOption == _this.toOption)&&const DeepCollectionEquality().equals(other.options, _this.options)&&const DeepCollectionEquality().equals(other.dragOptions, _this.dragOptions)&&const DeepCollectionEquality().equals(other.questions, _this.questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SectionPayload;
  return Object.hash(runtimeType,_this.id,_this.questionType,_this.inputType,_this.html,_this.fromOption,_this.toOption,const DeepCollectionEquality().hash(_this.options),const DeepCollectionEquality().hash(_this.dragOptions),const DeepCollectionEquality().hash(_this.questions));
}

@override
String toString() {
  final _this = this as SectionPayload;
  return 'SectionPayload(id: ${_this.id}, questionType: ${_this.questionType}, inputType: ${_this.inputType}, html: ${_this.html}, fromOption: ${_this.fromOption}, toOption: ${_this.toOption}, options: ${_this.options}, dragOptions: ${_this.dragOptions}, questions: ${_this.questions})';
}


}

/// @nodoc
abstract mixin class $SectionPayloadCopyWith<$Res>  {
  factory $SectionPayloadCopyWith(SectionPayload value, $Res Function(SectionPayload) _then) = _$SectionPayloadCopyWithImpl;
@useResult
$Res call({
 int id, String questionType, String inputType,@JsonKey(fromJson: stringOrEmpty) String html,@JsonKey(fromJson: stringOrNull) String? fromOption,@JsonKey(fromJson: stringOrNull) String? toOption, List<OptionPayload> options, List<DragOptionPayload> dragOptions, List<QuestionPayload> questions
});




}
/// @nodoc
class _$SectionPayloadCopyWithImpl<$Res>
    implements $SectionPayloadCopyWith<$Res> {
  _$SectionPayloadCopyWithImpl(this._self, this._then);

  final SectionPayload _self;
  final $Res Function(SectionPayload) _then;

/// Create a copy of SectionPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? questionType = null,Object? inputType = null,Object? html = null,Object? fromOption = freezed,Object? toOption = freezed,Object? options = null,Object? dragOptions = null,Object? questions = null,}) {
  return _then(SectionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,questionType: null == questionType ? _self.questionType : questionType // ignore: cast_nullable_to_non_nullable
as String,inputType: null == inputType ? _self.inputType : inputType // ignore: cast_nullable_to_non_nullable
as String,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,fromOption: freezed == fromOption ? _self.fromOption : fromOption // ignore: cast_nullable_to_non_nullable
as String?,toOption: freezed == toOption ? _self.toOption : toOption // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<OptionPayload>,dragOptions: null == dragOptions ? _self.dragOptions : dragOptions // ignore: cast_nullable_to_non_nullable
as List<DragOptionPayload>,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<QuestionPayload>,
  ));
}

}


/// Adds pattern-matching-related methods to [SectionPayload].
extension SectionPayloadPatterns on SectionPayload {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SectionPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SectionPayload() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SectionPayload value)  $default,){
final _that = this;
switch (_that) {
case _SectionPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SectionPayload value)?  $default,){
final _that = this;
switch (_that) {
case _SectionPayload() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String questionType,  String inputType, @JsonKey(fromJson: stringOrEmpty)  String html, @JsonKey(fromJson: stringOrNull)  String? fromOption, @JsonKey(fromJson: stringOrNull)  String? toOption,  List<OptionPayload> options,  List<DragOptionPayload> dragOptions,  List<QuestionPayload> questions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SectionPayload() when $default != null:
return $default(_that.id,_that.questionType,_that.inputType,_that.html,_that.fromOption,_that.toOption,_that.options,_that.dragOptions,_that.questions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String questionType,  String inputType, @JsonKey(fromJson: stringOrEmpty)  String html, @JsonKey(fromJson: stringOrNull)  String? fromOption, @JsonKey(fromJson: stringOrNull)  String? toOption,  List<OptionPayload> options,  List<DragOptionPayload> dragOptions,  List<QuestionPayload> questions)  $default,) {final _that = this;
switch (_that) {
case _SectionPayload():
return $default(_that.id,_that.questionType,_that.inputType,_that.html,_that.fromOption,_that.toOption,_that.options,_that.dragOptions,_that.questions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String questionType,  String inputType, @JsonKey(fromJson: stringOrEmpty)  String html, @JsonKey(fromJson: stringOrNull)  String? fromOption, @JsonKey(fromJson: stringOrNull)  String? toOption,  List<OptionPayload> options,  List<DragOptionPayload> dragOptions,  List<QuestionPayload> questions)?  $default,) {final _that = this;
switch (_that) {
case _SectionPayload() when $default != null:
return $default(_that.id,_that.questionType,_that.inputType,_that.html,_that.fromOption,_that.toOption,_that.options,_that.dragOptions,_that.questions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SectionPayload extends SectionPayload {
  const _SectionPayload({required this.id, required this.questionType, this.inputType = 'text', @JsonKey(fromJson: stringOrEmpty) this.html = '', @JsonKey(fromJson: stringOrNull) this.fromOption, @JsonKey(fromJson: stringOrNull) this.toOption,  List<OptionPayload> options = const <OptionPayload>[],  List<DragOptionPayload> dragOptions = const <DragOptionPayload>[],  List<QuestionPayload> questions = const <QuestionPayload>[]}): _options = options,_dragOptions = dragOptions,_questions = questions,super._();
  factory _SectionPayload.fromJson(Map<String, dynamic> json) => _$SectionPayloadFromJson(json);

@override final  int id;
@override final  String questionType;
@override@JsonKey() final  String inputType;
@override@JsonKey(fromJson: stringOrEmpty) final  String html;
@override@JsonKey(fromJson: stringOrNull) final  String? fromOption;
@override@JsonKey(fromJson: stringOrNull) final  String? toOption;
 final  List<OptionPayload> _options;
@override@JsonKey() List<OptionPayload> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

 final  List<DragOptionPayload> _dragOptions;
@override@JsonKey() List<DragOptionPayload> get dragOptions {
  if (_dragOptions is EqualUnmodifiableListView) return _dragOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dragOptions);
}

 final  List<QuestionPayload> _questions;
@override@JsonKey() List<QuestionPayload> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}


/// Create a copy of SectionPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SectionPayloadCopyWith<_SectionPayload> get copyWith => __$SectionPayloadCopyWithImpl<_SectionPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SectionPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SectionPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.questionType, questionType) || other.questionType == questionType)&&(identical(other.inputType, inputType) || other.inputType == inputType)&&(identical(other.html, html) || other.html == html)&&(identical(other.fromOption, fromOption) || other.fromOption == fromOption)&&(identical(other.toOption, toOption) || other.toOption == toOption)&&const DeepCollectionEquality().equals(other.options, _options)&&const DeepCollectionEquality().equals(other.dragOptions, _dragOptions)&&const DeepCollectionEquality().equals(other.questions, _questions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,questionType,inputType,html,fromOption,toOption,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_dragOptions),const DeepCollectionEquality().hash(_questions));
}

@override
String toString() {
    return 'SectionPayload(id: $id, questionType: $questionType, inputType: $inputType, html: $html, fromOption: $fromOption, toOption: $toOption, options: $options, dragOptions: $dragOptions, questions: $questions)';
}


}

/// @nodoc
abstract mixin class _$SectionPayloadCopyWith<$Res> implements $SectionPayloadCopyWith<$Res> {
  factory _$SectionPayloadCopyWith(_SectionPayload value, $Res Function(_SectionPayload) _then) = __$SectionPayloadCopyWithImpl;
@override @useResult
$Res call({
 int id, String questionType, String inputType,@JsonKey(fromJson: stringOrEmpty) String html,@JsonKey(fromJson: stringOrNull) String? fromOption,@JsonKey(fromJson: stringOrNull) String? toOption, List<OptionPayload> options, List<DragOptionPayload> dragOptions, List<QuestionPayload> questions
});




}
/// @nodoc
class __$SectionPayloadCopyWithImpl<$Res>
    implements _$SectionPayloadCopyWith<$Res> {
  __$SectionPayloadCopyWithImpl(this._self, this._then);

  final _SectionPayload _self;
  final $Res Function(_SectionPayload) _then;

/// Create a copy of SectionPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? questionType = null,Object? inputType = null,Object? html = null,Object? fromOption = freezed,Object? toOption = freezed,Object? options = null,Object? dragOptions = null,Object? questions = null,}) {
  return _then(_SectionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,questionType: null == questionType ? _self.questionType : questionType // ignore: cast_nullable_to_non_nullable
as String,inputType: null == inputType ? _self.inputType : inputType // ignore: cast_nullable_to_non_nullable
as String,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,fromOption: freezed == fromOption ? _self.fromOption : fromOption // ignore: cast_nullable_to_non_nullable
as String?,toOption: freezed == toOption ? _self.toOption : toOption // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<OptionPayload>,dragOptions: null == dragOptions ? _self._dragOptions : dragOptions // ignore: cast_nullable_to_non_nullable
as List<DragOptionPayload>,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<QuestionPayload>,
  ));
}


}


/// @nodoc
mixin _$OptionPayload {

 int get id;@JsonKey(fromJson: stringOrEmpty) String get html;
/// Create a copy of OptionPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptionPayloadCopyWith<OptionPayload> get copyWith => _$OptionPayloadCopyWithImpl<OptionPayload>(this as OptionPayload, _$identity);

  /// Serializes this OptionPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OptionPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptionPayload&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.html, _this.html) || other.html == _this.html));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OptionPayload;
  return Object.hash(runtimeType,_this.id,_this.html);
}

@override
String toString() {
  final _this = this as OptionPayload;
  return 'OptionPayload(id: ${_this.id}, html: ${_this.html})';
}


}

/// @nodoc
abstract mixin class $OptionPayloadCopyWith<$Res>  {
  factory $OptionPayloadCopyWith(OptionPayload value, $Res Function(OptionPayload) _then) = _$OptionPayloadCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(fromJson: stringOrEmpty) String html
});




}
/// @nodoc
class _$OptionPayloadCopyWithImpl<$Res>
    implements $OptionPayloadCopyWith<$Res> {
  _$OptionPayloadCopyWithImpl(this._self, this._then);

  final OptionPayload _self;
  final $Res Function(OptionPayload) _then;

/// Create a copy of OptionPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? html = null,}) {
  return _then(OptionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OptionPayload].
extension OptionPayloadPatterns on OptionPayload {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptionPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptionPayload() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptionPayload value)  $default,){
final _that = this;
switch (_that) {
case _OptionPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptionPayload value)?  $default,){
final _that = this;
switch (_that) {
case _OptionPayload() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(fromJson: stringOrEmpty)  String html)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptionPayload() when $default != null:
return $default(_that.id,_that.html);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(fromJson: stringOrEmpty)  String html)  $default,) {final _that = this;
switch (_that) {
case _OptionPayload():
return $default(_that.id,_that.html);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(fromJson: stringOrEmpty)  String html)?  $default,) {final _that = this;
switch (_that) {
case _OptionPayload() when $default != null:
return $default(_that.id,_that.html);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OptionPayload implements OptionPayload {
  const _OptionPayload({required this.id, @JsonKey(fromJson: stringOrEmpty) this.html = ''});
  factory _OptionPayload.fromJson(Map<String, dynamic> json) => _$OptionPayloadFromJson(json);

@override final  int id;
@override@JsonKey(fromJson: stringOrEmpty) final  String html;

/// Create a copy of OptionPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptionPayloadCopyWith<_OptionPayload> get copyWith => __$OptionPayloadCopyWithImpl<_OptionPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OptionPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptionPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.html, html) || other.html == html));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,html);
}

@override
String toString() {
    return 'OptionPayload(id: $id, html: $html)';
}


}

/// @nodoc
abstract mixin class _$OptionPayloadCopyWith<$Res> implements $OptionPayloadCopyWith<$Res> {
  factory _$OptionPayloadCopyWith(_OptionPayload value, $Res Function(_OptionPayload) _then) = __$OptionPayloadCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(fromJson: stringOrEmpty) String html
});




}
/// @nodoc
class __$OptionPayloadCopyWithImpl<$Res>
    implements _$OptionPayloadCopyWith<$Res> {
  __$OptionPayloadCopyWithImpl(this._self, this._then);

  final _OptionPayload _self;
  final $Res Function(_OptionPayload) _then;

/// Create a copy of OptionPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? html = null,}) {
  return _then(_OptionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DragOptionPayload {

@JsonKey(fromJson: stringOrEmpty) String get id;@JsonKey(fromJson: stringOrEmpty) String get label;
/// Create a copy of DragOptionPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DragOptionPayloadCopyWith<DragOptionPayload> get copyWith => _$DragOptionPayloadCopyWithImpl<DragOptionPayload>(this as DragOptionPayload, _$identity);

  /// Serializes this DragOptionPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DragOptionPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DragOptionPayload&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DragOptionPayload;
  return Object.hash(runtimeType,_this.id,_this.label);
}

@override
String toString() {
  final _this = this as DragOptionPayload;
  return 'DragOptionPayload(id: ${_this.id}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $DragOptionPayloadCopyWith<$Res>  {
  factory $DragOptionPayloadCopyWith(DragOptionPayload value, $Res Function(DragOptionPayload) _then) = _$DragOptionPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: stringOrEmpty) String id,@JsonKey(fromJson: stringOrEmpty) String label
});




}
/// @nodoc
class _$DragOptionPayloadCopyWithImpl<$Res>
    implements $DragOptionPayloadCopyWith<$Res> {
  _$DragOptionPayloadCopyWithImpl(this._self, this._then);

  final DragOptionPayload _self;
  final $Res Function(DragOptionPayload) _then;

/// Create a copy of DragOptionPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,}) {
  return _then(DragOptionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DragOptionPayload].
extension DragOptionPayloadPatterns on DragOptionPayload {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DragOptionPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DragOptionPayload() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DragOptionPayload value)  $default,){
final _that = this;
switch (_that) {
case _DragOptionPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DragOptionPayload value)?  $default,){
final _that = this;
switch (_that) {
case _DragOptionPayload() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringOrEmpty)  String id, @JsonKey(fromJson: stringOrEmpty)  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DragOptionPayload() when $default != null:
return $default(_that.id,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringOrEmpty)  String id, @JsonKey(fromJson: stringOrEmpty)  String label)  $default,) {final _that = this;
switch (_that) {
case _DragOptionPayload():
return $default(_that.id,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: stringOrEmpty)  String id, @JsonKey(fromJson: stringOrEmpty)  String label)?  $default,) {final _that = this;
switch (_that) {
case _DragOptionPayload() when $default != null:
return $default(_that.id,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DragOptionPayload implements DragOptionPayload {
  const _DragOptionPayload({@JsonKey(fromJson: stringOrEmpty) required this.id, @JsonKey(fromJson: stringOrEmpty) this.label = ''});
  factory _DragOptionPayload.fromJson(Map<String, dynamic> json) => _$DragOptionPayloadFromJson(json);

@override@JsonKey(fromJson: stringOrEmpty) final  String id;
@override@JsonKey(fromJson: stringOrEmpty) final  String label;

/// Create a copy of DragOptionPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DragOptionPayloadCopyWith<_DragOptionPayload> get copyWith => __$DragOptionPayloadCopyWithImpl<_DragOptionPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DragOptionPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DragOptionPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label);
}

@override
String toString() {
    return 'DragOptionPayload(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class _$DragOptionPayloadCopyWith<$Res> implements $DragOptionPayloadCopyWith<$Res> {
  factory _$DragOptionPayloadCopyWith(_DragOptionPayload value, $Res Function(_DragOptionPayload) _then) = __$DragOptionPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: stringOrEmpty) String id,@JsonKey(fromJson: stringOrEmpty) String label
});




}
/// @nodoc
class __$DragOptionPayloadCopyWithImpl<$Res>
    implements _$DragOptionPayloadCopyWith<$Res> {
  __$DragOptionPayloadCopyWithImpl(this._self, this._then);

  final _DragOptionPayload _self;
  final $Res Function(_DragOptionPayload) _then;

/// Create a copy of DragOptionPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,}) {
  return _then(_DragOptionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$QuestionPayload {

 int get id; int get number; int get order;@JsonKey(fromJson: stringOrEmpty) String get html; List<OptionPayload> get options; SavedAnswer get answer;/// How many question numbers the question covers (`number_count`;
/// e.g. 2 for "Choose TWO letters"). `number` is the first of them.
@JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson) int get answerCount;
/// Create a copy of QuestionPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionPayloadCopyWith<QuestionPayload> get copyWith => _$QuestionPayloadCopyWithImpl<QuestionPayload>(this as QuestionPayload, _$identity);

  /// Serializes this QuestionPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QuestionPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionPayload&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.html, _this.html) || other.html == _this.html)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.answer, _this.answer) || other.answer == _this.answer)&&(identical(other.answerCount, _this.answerCount) || other.answerCount == _this.answerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QuestionPayload;
  return Object.hash(runtimeType,_this.id,_this.number,_this.order,_this.html,const DeepCollectionEquality().hash(_this.options),_this.answer,_this.answerCount);
}

@override
String toString() {
  final _this = this as QuestionPayload;
  return 'QuestionPayload(id: ${_this.id}, number: ${_this.number}, order: ${_this.order}, html: ${_this.html}, options: ${_this.options}, answer: ${_this.answer}, answerCount: ${_this.answerCount})';
}


}

/// @nodoc
abstract mixin class $QuestionPayloadCopyWith<$Res>  {
  factory $QuestionPayloadCopyWith(QuestionPayload value, $Res Function(QuestionPayload) _then) = _$QuestionPayloadCopyWithImpl;
@useResult
$Res call({
 int id, int number, int order,@JsonKey(fromJson: stringOrEmpty) String html, List<OptionPayload> options, SavedAnswer answer,@JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson) int answerCount
});


$SavedAnswerCopyWith<$Res> get answer;

}
/// @nodoc
class _$QuestionPayloadCopyWithImpl<$Res>
    implements $QuestionPayloadCopyWith<$Res> {
  _$QuestionPayloadCopyWithImpl(this._self, this._then);

  final QuestionPayload _self;
  final $Res Function(QuestionPayload) _then;

/// Create a copy of QuestionPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? order = null,Object? html = null,Object? options = null,Object? answer = null,Object? answerCount = null,}) {
  return _then(QuestionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<OptionPayload>,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as SavedAnswer,answerCount: null == answerCount ? _self.answerCount : answerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of QuestionPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SavedAnswerCopyWith<$Res> get answer {
  
  return $SavedAnswerCopyWith<$Res>(_self.answer, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuestionPayload].
extension QuestionPayloadPatterns on QuestionPayload {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionPayload() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionPayload value)  $default,){
final _that = this;
switch (_that) {
case _QuestionPayload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionPayload value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionPayload() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int number,  int order, @JsonKey(fromJson: stringOrEmpty)  String html,  List<OptionPayload> options,  SavedAnswer answer, @JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson)  int answerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionPayload() when $default != null:
return $default(_that.id,_that.number,_that.order,_that.html,_that.options,_that.answer,_that.answerCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int number,  int order, @JsonKey(fromJson: stringOrEmpty)  String html,  List<OptionPayload> options,  SavedAnswer answer, @JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson)  int answerCount)  $default,) {final _that = this;
switch (_that) {
case _QuestionPayload():
return $default(_that.id,_that.number,_that.order,_that.html,_that.options,_that.answer,_that.answerCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int number,  int order, @JsonKey(fromJson: stringOrEmpty)  String html,  List<OptionPayload> options,  SavedAnswer answer, @JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson)  int answerCount)?  $default,) {final _that = this;
switch (_that) {
case _QuestionPayload() when $default != null:
return $default(_that.id,_that.number,_that.order,_that.html,_that.options,_that.answer,_that.answerCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionPayload implements QuestionPayload {
  const _QuestionPayload({required this.id, required this.number, this.order = 1, @JsonKey(fromJson: stringOrEmpty) this.html = '',  List<OptionPayload> options = const <OptionPayload>[], this.answer = const SavedAnswer(), @JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson) this.answerCount = 1}): _options = options;
  factory _QuestionPayload.fromJson(Map<String, dynamic> json) => _$QuestionPayloadFromJson(json);

@override final  int id;
@override final  int number;
@override@JsonKey() final  int order;
@override@JsonKey(fromJson: stringOrEmpty) final  String html;
 final  List<OptionPayload> _options;
@override@JsonKey() List<OptionPayload> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override@JsonKey() final  SavedAnswer answer;
/// How many question numbers the question covers (`number_count`;
/// e.g. 2 for "Choose TWO letters"). `number` is the first of them.
@override@JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson) final  int answerCount;

/// Create a copy of QuestionPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionPayloadCopyWith<_QuestionPayload> get copyWith => __$QuestionPayloadCopyWithImpl<_QuestionPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionPayload&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.order, order) || other.order == order)&&(identical(other.html, html) || other.html == html)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.answerCount, answerCount) || other.answerCount == answerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,number,order,html,const DeepCollectionEquality().hash(_options),answer,answerCount);
}

@override
String toString() {
    return 'QuestionPayload(id: $id, number: $number, order: $order, html: $html, options: $options, answer: $answer, answerCount: $answerCount)';
}


}

/// @nodoc
abstract mixin class _$QuestionPayloadCopyWith<$Res> implements $QuestionPayloadCopyWith<$Res> {
  factory _$QuestionPayloadCopyWith(_QuestionPayload value, $Res Function(_QuestionPayload) _then) = __$QuestionPayloadCopyWithImpl;
@override @useResult
$Res call({
 int id, int number, int order,@JsonKey(fromJson: stringOrEmpty) String html, List<OptionPayload> options, SavedAnswer answer,@JsonKey(name: 'number_count', readValue: readAnswerCount, fromJson: _answerCountFromJson) int answerCount
});


@override $SavedAnswerCopyWith<$Res> get answer;

}
/// @nodoc
class __$QuestionPayloadCopyWithImpl<$Res>
    implements _$QuestionPayloadCopyWith<$Res> {
  __$QuestionPayloadCopyWithImpl(this._self, this._then);

  final _QuestionPayload _self;
  final $Res Function(_QuestionPayload) _then;

/// Create a copy of QuestionPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? order = null,Object? html = null,Object? options = null,Object? answer = null,Object? answerCount = null,}) {
  return _then(_QuestionPayload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,html: null == html ? _self.html : html // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<OptionPayload>,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as SavedAnswer,answerCount: null == answerCount ? _self.answerCount : answerCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of QuestionPayload
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SavedAnswerCopyWith<$Res> get answer {
  
  return $SavedAnswerCopyWith<$Res>(_self.answer, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}


/// @nodoc
mixin _$SavedAnswer {

 String? get text; List<int> get optionIds;
/// Create a copy of SavedAnswer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedAnswerCopyWith<SavedAnswer> get copyWith => _$SavedAnswerCopyWithImpl<SavedAnswer>(this as SavedAnswer, _$identity);

  /// Serializes this SavedAnswer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SavedAnswer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedAnswer&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.optionIds, _this.optionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SavedAnswer;
  return Object.hash(runtimeType,_this.text,const DeepCollectionEquality().hash(_this.optionIds));
}

@override
String toString() {
  final _this = this as SavedAnswer;
  return 'SavedAnswer(text: ${_this.text}, optionIds: ${_this.optionIds})';
}


}

/// @nodoc
abstract mixin class $SavedAnswerCopyWith<$Res>  {
  factory $SavedAnswerCopyWith(SavedAnswer value, $Res Function(SavedAnswer) _then) = _$SavedAnswerCopyWithImpl;
@useResult
$Res call({
 String? text, List<int> optionIds
});




}
/// @nodoc
class _$SavedAnswerCopyWithImpl<$Res>
    implements $SavedAnswerCopyWith<$Res> {
  _$SavedAnswerCopyWithImpl(this._self, this._then);

  final SavedAnswer _self;
  final $Res Function(SavedAnswer) _then;

/// Create a copy of SavedAnswer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = freezed,Object? optionIds = null,}) {
  return _then(SavedAnswer(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,optionIds: null == optionIds ? _self.optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedAnswer].
extension SavedAnswerPatterns on SavedAnswer {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedAnswer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedAnswer() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedAnswer value)  $default,){
final _that = this;
switch (_that) {
case _SavedAnswer():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedAnswer value)?  $default,){
final _that = this;
switch (_that) {
case _SavedAnswer() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? text,  List<int> optionIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedAnswer() when $default != null:
return $default(_that.text,_that.optionIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? text,  List<int> optionIds)  $default,) {final _that = this;
switch (_that) {
case _SavedAnswer():
return $default(_that.text,_that.optionIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? text,  List<int> optionIds)?  $default,) {final _that = this;
switch (_that) {
case _SavedAnswer() when $default != null:
return $default(_that.text,_that.optionIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedAnswer extends SavedAnswer {
  const _SavedAnswer({this.text,  List<int> optionIds = const <int>[]}): _optionIds = optionIds,super._();
  factory _SavedAnswer.fromJson(Map<String, dynamic> json) => _$SavedAnswerFromJson(json);

@override final  String? text;
 final  List<int> _optionIds;
@override@JsonKey() List<int> get optionIds {
  if (_optionIds is EqualUnmodifiableListView) return _optionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_optionIds);
}


/// Create a copy of SavedAnswer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedAnswerCopyWith<_SavedAnswer> get copyWith => __$SavedAnswerCopyWithImpl<_SavedAnswer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedAnswerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedAnswer&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.optionIds, _optionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_optionIds));
}

@override
String toString() {
    return 'SavedAnswer(text: $text, optionIds: $optionIds)';
}


}

/// @nodoc
abstract mixin class _$SavedAnswerCopyWith<$Res> implements $SavedAnswerCopyWith<$Res> {
  factory _$SavedAnswerCopyWith(_SavedAnswer value, $Res Function(_SavedAnswer) _then) = __$SavedAnswerCopyWithImpl;
@override @useResult
$Res call({
 String? text, List<int> optionIds
});




}
/// @nodoc
class __$SavedAnswerCopyWithImpl<$Res>
    implements _$SavedAnswerCopyWith<$Res> {
  __$SavedAnswerCopyWithImpl(this._self, this._then);

  final _SavedAnswer _self;
  final $Res Function(_SavedAnswer) _then;

/// Create a copy of SavedAnswer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = freezed,Object? optionIds = null,}) {
  return _then(_SavedAnswer(
text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,optionIds: null == optionIds ? _self._optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
