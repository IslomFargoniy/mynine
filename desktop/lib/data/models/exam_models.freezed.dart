// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoginResponse {

 String get token;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get expiresAt; Candidate get candidate; MockInfo get mock; int get attemptId;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginResponseCopyWith<LoginResponse> get copyWith => _$LoginResponseCopyWithImpl<LoginResponse>(this as LoginResponse, _$identity);

  /// Serializes this LoginResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LoginResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginResponse&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.candidate, _this.candidate) || other.candidate == _this.candidate)&&(identical(other.mock, _this.mock) || other.mock == _this.mock)&&(identical(other.attemptId, _this.attemptId) || other.attemptId == _this.attemptId)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LoginResponse;
  return Object.hash(runtimeType,_this.token,_this.expiresAt,_this.candidate,_this.mock,_this.attemptId,_this.serverTime);
}

@override
String toString() {
  final _this = this as LoginResponse;
  return 'LoginResponse(token: ${_this.token}, expiresAt: ${_this.expiresAt}, candidate: ${_this.candidate}, mock: ${_this.mock}, attemptId: ${_this.attemptId}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $LoginResponseCopyWith<$Res>  {
  factory $LoginResponseCopyWith(LoginResponse value, $Res Function(LoginResponse) _then) = _$LoginResponseCopyWithImpl;
@useResult
$Res call({
 String token,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? expiresAt, Candidate candidate, MockInfo mock, int attemptId,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});


$CandidateCopyWith<$Res> get candidate;$MockInfoCopyWith<$Res> get mock;

}
/// @nodoc
class _$LoginResponseCopyWithImpl<$Res>
    implements $LoginResponseCopyWith<$Res> {
  _$LoginResponseCopyWithImpl(this._self, this._then);

  final LoginResponse _self;
  final $Res Function(LoginResponse) _then;

/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? expiresAt = freezed,Object? candidate = null,Object? mock = null,Object? attemptId = null,Object? serverTime = freezed,}) {
  return _then(LoginResponse(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,candidate: null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as Candidate,mock: null == mock ? _self.mock : mock // ignore: cast_nullable_to_non_nullable
as MockInfo,attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CandidateCopyWith<$Res> get candidate {
  
  return $CandidateCopyWith<$Res>(_self.candidate, (value) {
    return _then(_self.copyWith(candidate: value));
  });
}/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MockInfoCopyWith<$Res> get mock {
  
  return $MockInfoCopyWith<$Res>(_self.mock, (value) {
    return _then(_self.copyWith(mock: value));
  });
}
}


/// Adds pattern-matching-related methods to [LoginResponse].
extension LoginResponsePatterns on LoginResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginResponse value)  $default,){
final _that = this;
switch (_that) {
case _LoginResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginResponse value)?  $default,){
final _that = this;
switch (_that) {
case _LoginResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? expiresAt,  Candidate candidate,  MockInfo mock,  int attemptId, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginResponse() when $default != null:
return $default(_that.token,_that.expiresAt,_that.candidate,_that.mock,_that.attemptId,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? expiresAt,  Candidate candidate,  MockInfo mock,  int attemptId, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _LoginResponse():
return $default(_that.token,_that.expiresAt,_that.candidate,_that.mock,_that.attemptId,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? expiresAt,  Candidate candidate,  MockInfo mock,  int attemptId, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _LoginResponse() when $default != null:
return $default(_that.token,_that.expiresAt,_that.candidate,_that.mock,_that.attemptId,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LoginResponse implements LoginResponse {
  const _LoginResponse({required this.token, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.expiresAt, required this.candidate, required this.mock, required this.attemptId, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime});
  factory _LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);

@override final  String token;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? expiresAt;
@override final  Candidate candidate;
@override final  MockInfo mock;
@override final  int attemptId;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginResponseCopyWith<_LoginResponse> get copyWith => __$LoginResponseCopyWithImpl<_LoginResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoginResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginResponse&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.candidate, candidate) || other.candidate == candidate)&&(identical(other.mock, mock) || other.mock == mock)&&(identical(other.attemptId, attemptId) || other.attemptId == attemptId)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,token,expiresAt,candidate,mock,attemptId,serverTime);
}

@override
String toString() {
    return 'LoginResponse(token: $token, expiresAt: $expiresAt, candidate: $candidate, mock: $mock, attemptId: $attemptId, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$LoginResponseCopyWith<$Res> implements $LoginResponseCopyWith<$Res> {
  factory _$LoginResponseCopyWith(_LoginResponse value, $Res Function(_LoginResponse) _then) = __$LoginResponseCopyWithImpl;
@override @useResult
$Res call({
 String token,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? expiresAt, Candidate candidate, MockInfo mock, int attemptId,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});


@override $CandidateCopyWith<$Res> get candidate;@override $MockInfoCopyWith<$Res> get mock;

}
/// @nodoc
class __$LoginResponseCopyWithImpl<$Res>
    implements _$LoginResponseCopyWith<$Res> {
  __$LoginResponseCopyWithImpl(this._self, this._then);

  final _LoginResponse _self;
  final $Res Function(_LoginResponse) _then;

/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? expiresAt = freezed,Object? candidate = null,Object? mock = null,Object? attemptId = null,Object? serverTime = freezed,}) {
  return _then(_LoginResponse(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,candidate: null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as Candidate,mock: null == mock ? _self.mock : mock // ignore: cast_nullable_to_non_nullable
as MockInfo,attemptId: null == attemptId ? _self.attemptId : attemptId // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CandidateCopyWith<$Res> get candidate {
  
  return $CandidateCopyWith<$Res>(_self.candidate, (value) {
    return _then(_self.copyWith(candidate: value));
  });
}/// Create a copy of LoginResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MockInfoCopyWith<$Res> get mock {
  
  return $MockInfoCopyWith<$Res>(_self.mock, (value) {
    return _then(_self.copyWith(mock: value));
  });
}
}


/// @nodoc
mixin _$Candidate {

 int get id; String get name; String get code;
/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandidateCopyWith<Candidate> get copyWith => _$CandidateCopyWithImpl<Candidate>(this as Candidate, _$identity);

  /// Serializes this Candidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Candidate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Candidate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.code, _this.code) || other.code == _this.code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Candidate;
  return Object.hash(runtimeType,_this.id,_this.name,_this.code);
}

@override
String toString() {
  final _this = this as Candidate;
  return 'Candidate(id: ${_this.id}, name: ${_this.name}, code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $CandidateCopyWith<$Res>  {
  factory $CandidateCopyWith(Candidate value, $Res Function(Candidate) _then) = _$CandidateCopyWithImpl;
@useResult
$Res call({
 int id, String name, String code
});




}
/// @nodoc
class _$CandidateCopyWithImpl<$Res>
    implements $CandidateCopyWith<$Res> {
  _$CandidateCopyWithImpl(this._self, this._then);

  final Candidate _self;
  final $Res Function(Candidate) _then;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = null,}) {
  return _then(Candidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Candidate].
extension CandidatePatterns on Candidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Candidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Candidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Candidate value)  $default,){
final _that = this;
switch (_that) {
case _Candidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Candidate value)?  $default,){
final _that = this;
switch (_that) {
case _Candidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that.id,_that.name,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String code)  $default,) {final _that = this;
switch (_that) {
case _Candidate():
return $default(_that.id,_that.name,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String code)?  $default,) {final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that.id,_that.name,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Candidate implements Candidate {
  const _Candidate({required this.id, required this.name, required this.code});
  factory _Candidate.fromJson(Map<String, dynamic> json) => _$CandidateFromJson(json);

@override final  int id;
@override final  String name;
@override final  String code;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CandidateCopyWith<_Candidate> get copyWith => __$CandidateCopyWithImpl<_Candidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CandidateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Candidate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,code);
}

@override
String toString() {
    return 'Candidate(id: $id, name: $name, code: $code)';
}


}

/// @nodoc
abstract mixin class _$CandidateCopyWith<$Res> implements $CandidateCopyWith<$Res> {
  factory _$CandidateCopyWith(_Candidate value, $Res Function(_Candidate) _then) = __$CandidateCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String code
});




}
/// @nodoc
class __$CandidateCopyWithImpl<$Res>
    implements _$CandidateCopyWith<$Res> {
  __$CandidateCopyWithImpl(this._self, this._then);

  final _Candidate _self;
  final $Res Function(_Candidate) _then;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = null,}) {
  return _then(_Candidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MockInfo {

 int get id; String get name;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get startsAt;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get endsAt;
/// Create a copy of MockInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MockInfoCopyWith<MockInfo> get copyWith => _$MockInfoCopyWithImpl<MockInfo>(this as MockInfo, _$identity);

  /// Serializes this MockInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MockInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MockInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.startsAt, _this.startsAt) || other.startsAt == _this.startsAt)&&(identical(other.endsAt, _this.endsAt) || other.endsAt == _this.endsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MockInfo;
  return Object.hash(runtimeType,_this.id,_this.name,_this.startsAt,_this.endsAt);
}

@override
String toString() {
  final _this = this as MockInfo;
  return 'MockInfo(id: ${_this.id}, name: ${_this.name}, startsAt: ${_this.startsAt}, endsAt: ${_this.endsAt})';
}


}

/// @nodoc
abstract mixin class $MockInfoCopyWith<$Res>  {
  factory $MockInfoCopyWith(MockInfo value, $Res Function(MockInfo) _then) = _$MockInfoCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startsAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? endsAt
});




}
/// @nodoc
class _$MockInfoCopyWithImpl<$Res>
    implements $MockInfoCopyWith<$Res> {
  _$MockInfoCopyWithImpl(this._self, this._then);

  final MockInfo _self;
  final $Res Function(MockInfo) _then;

/// Create a copy of MockInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? startsAt = freezed,Object? endsAt = freezed,}) {
  return _then(MockInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MockInfo].
extension MockInfoPatterns on MockInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MockInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MockInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MockInfo value)  $default,){
final _that = this;
switch (_that) {
case _MockInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MockInfo value)?  $default,){
final _that = this;
switch (_that) {
case _MockInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startsAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? endsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MockInfo() when $default != null:
return $default(_that.id,_that.name,_that.startsAt,_that.endsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startsAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? endsAt)  $default,) {final _that = this;
switch (_that) {
case _MockInfo():
return $default(_that.id,_that.name,_that.startsAt,_that.endsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startsAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? endsAt)?  $default,) {final _that = this;
switch (_that) {
case _MockInfo() when $default != null:
return $default(_that.id,_that.name,_that.startsAt,_that.endsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MockInfo implements MockInfo {
  const _MockInfo({required this.id, required this.name, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.startsAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.endsAt});
  factory _MockInfo.fromJson(Map<String, dynamic> json) => _$MockInfoFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? startsAt;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? endsAt;

/// Create a copy of MockInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MockInfoCopyWith<_MockInfo> get copyWith => __$MockInfoCopyWithImpl<_MockInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MockInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MockInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.startsAt, startsAt) || other.startsAt == startsAt)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,startsAt,endsAt);
}

@override
String toString() {
    return 'MockInfo(id: $id, name: $name, startsAt: $startsAt, endsAt: $endsAt)';
}


}

/// @nodoc
abstract mixin class _$MockInfoCopyWith<$Res> implements $MockInfoCopyWith<$Res> {
  factory _$MockInfoCopyWith(_MockInfo value, $Res Function(_MockInfo) _then) = __$MockInfoCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startsAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? endsAt
});




}
/// @nodoc
class __$MockInfoCopyWithImpl<$Res>
    implements _$MockInfoCopyWith<$Res> {
  __$MockInfoCopyWithImpl(this._self, this._then);

  final _MockInfo _self;
  final $Res Function(_MockInfo) _then;

/// Create a copy of MockInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? startsAt = freezed,Object? endsAt = freezed,}) {
  return _then(_MockInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startsAt: freezed == startsAt ? _self.startsAt : startsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ExamState {

 AttemptInfo get attempt; List<ExamModule> get modules;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of ExamState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamStateCopyWith<ExamState> get copyWith => _$ExamStateCopyWithImpl<ExamState>(this as ExamState, _$identity);

  /// Serializes this ExamState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExamState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamState&&(identical(other.attempt, _this.attempt) || other.attempt == _this.attempt)&&const DeepCollectionEquality().equals(other.modules, _this.modules)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExamState;
  return Object.hash(runtimeType,_this.attempt,const DeepCollectionEquality().hash(_this.modules),_this.serverTime);
}

@override
String toString() {
  final _this = this as ExamState;
  return 'ExamState(attempt: ${_this.attempt}, modules: ${_this.modules}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $ExamStateCopyWith<$Res>  {
  factory $ExamStateCopyWith(ExamState value, $Res Function(ExamState) _then) = _$ExamStateCopyWithImpl;
@useResult
$Res call({
 AttemptInfo attempt, List<ExamModule> modules,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});


$AttemptInfoCopyWith<$Res> get attempt;

}
/// @nodoc
class _$ExamStateCopyWithImpl<$Res>
    implements $ExamStateCopyWith<$Res> {
  _$ExamStateCopyWithImpl(this._self, this._then);

  final ExamState _self;
  final $Res Function(ExamState) _then;

/// Create a copy of ExamState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempt = null,Object? modules = null,Object? serverTime = freezed,}) {
  return _then(ExamState(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as AttemptInfo,modules: null == modules ? _self.modules : modules // ignore: cast_nullable_to_non_nullable
as List<ExamModule>,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of ExamState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AttemptInfoCopyWith<$Res> get attempt {
  
  return $AttemptInfoCopyWith<$Res>(_self.attempt, (value) {
    return _then(_self.copyWith(attempt: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExamState].
extension ExamStatePatterns on ExamState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamState value)  $default,){
final _that = this;
switch (_that) {
case _ExamState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamState value)?  $default,){
final _that = this;
switch (_that) {
case _ExamState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AttemptInfo attempt,  List<ExamModule> modules, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamState() when $default != null:
return $default(_that.attempt,_that.modules,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AttemptInfo attempt,  List<ExamModule> modules, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _ExamState():
return $default(_that.attempt,_that.modules,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AttemptInfo attempt,  List<ExamModule> modules, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _ExamState() when $default != null:
return $default(_that.attempt,_that.modules,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExamState implements ExamState {
  const _ExamState({required this.attempt,  List<ExamModule> modules = const <ExamModule>[], @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime}): _modules = modules;
  factory _ExamState.fromJson(Map<String, dynamic> json) => _$ExamStateFromJson(json);

@override final  AttemptInfo attempt;
 final  List<ExamModule> _modules;
@override@JsonKey() List<ExamModule> get modules {
  if (_modules is EqualUnmodifiableListView) return _modules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modules);
}

@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of ExamState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamStateCopyWith<_ExamState> get copyWith => __$ExamStateCopyWithImpl<_ExamState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamState&&(identical(other.attempt, attempt) || other.attempt == attempt)&&const DeepCollectionEquality().equals(other.modules, _modules)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,attempt,const DeepCollectionEquality().hash(_modules),serverTime);
}

@override
String toString() {
    return 'ExamState(attempt: $attempt, modules: $modules, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$ExamStateCopyWith<$Res> implements $ExamStateCopyWith<$Res> {
  factory _$ExamStateCopyWith(_ExamState value, $Res Function(_ExamState) _then) = __$ExamStateCopyWithImpl;
@override @useResult
$Res call({
 AttemptInfo attempt, List<ExamModule> modules,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});


@override $AttemptInfoCopyWith<$Res> get attempt;

}
/// @nodoc
class __$ExamStateCopyWithImpl<$Res>
    implements _$ExamStateCopyWith<$Res> {
  __$ExamStateCopyWithImpl(this._self, this._then);

  final _ExamState _self;
  final $Res Function(_ExamState) _then;

/// Create a copy of ExamState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempt = null,Object? modules = null,Object? serverTime = freezed,}) {
  return _then(_ExamState(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as AttemptInfo,modules: null == modules ? _self._modules : modules // ignore: cast_nullable_to_non_nullable
as List<ExamModule>,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of ExamState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AttemptInfoCopyWith<$Res> get attempt {
  
  return $AttemptInfoCopyWith<$Res>(_self.attempt, (value) {
    return _then(_self.copyWith(attempt: value));
  });
}
}


/// @nodoc
mixin _$AttemptInfo {

 int get id; String get status; bool get paused; bool get finished;
/// Create a copy of AttemptInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttemptInfoCopyWith<AttemptInfo> get copyWith => _$AttemptInfoCopyWithImpl<AttemptInfo>(this as AttemptInfo, _$identity);

  /// Serializes this AttemptInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AttemptInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttemptInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.paused, _this.paused) || other.paused == _this.paused)&&(identical(other.finished, _this.finished) || other.finished == _this.finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AttemptInfo;
  return Object.hash(runtimeType,_this.id,_this.status,_this.paused,_this.finished);
}

@override
String toString() {
  final _this = this as AttemptInfo;
  return 'AttemptInfo(id: ${_this.id}, status: ${_this.status}, paused: ${_this.paused}, finished: ${_this.finished})';
}


}

/// @nodoc
abstract mixin class $AttemptInfoCopyWith<$Res>  {
  factory $AttemptInfoCopyWith(AttemptInfo value, $Res Function(AttemptInfo) _then) = _$AttemptInfoCopyWithImpl;
@useResult
$Res call({
 int id, String status, bool paused, bool finished
});




}
/// @nodoc
class _$AttemptInfoCopyWithImpl<$Res>
    implements $AttemptInfoCopyWith<$Res> {
  _$AttemptInfoCopyWithImpl(this._self, this._then);

  final AttemptInfo _self;
  final $Res Function(AttemptInfo) _then;

/// Create a copy of AttemptInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? paused = null,Object? finished = null,}) {
  return _then(AttemptInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AttemptInfo].
extension AttemptInfoPatterns on AttemptInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttemptInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttemptInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttemptInfo value)  $default,){
final _that = this;
switch (_that) {
case _AttemptInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttemptInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AttemptInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String status,  bool paused,  bool finished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttemptInfo() when $default != null:
return $default(_that.id,_that.status,_that.paused,_that.finished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String status,  bool paused,  bool finished)  $default,) {final _that = this;
switch (_that) {
case _AttemptInfo():
return $default(_that.id,_that.status,_that.paused,_that.finished);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String status,  bool paused,  bool finished)?  $default,) {final _that = this;
switch (_that) {
case _AttemptInfo() when $default != null:
return $default(_that.id,_that.status,_that.paused,_that.finished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttemptInfo implements AttemptInfo {
  const _AttemptInfo({required this.id, this.status = 'in_progress', this.paused = false, this.finished = false});
  factory _AttemptInfo.fromJson(Map<String, dynamic> json) => _$AttemptInfoFromJson(json);

@override final  int id;
@override@JsonKey() final  String status;
@override@JsonKey() final  bool paused;
@override@JsonKey() final  bool finished;

/// Create a copy of AttemptInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttemptInfoCopyWith<_AttemptInfo> get copyWith => __$AttemptInfoCopyWithImpl<_AttemptInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttemptInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttemptInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.paused, paused) || other.paused == paused)&&(identical(other.finished, finished) || other.finished == finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,status,paused,finished);
}

@override
String toString() {
    return 'AttemptInfo(id: $id, status: $status, paused: $paused, finished: $finished)';
}


}

/// @nodoc
abstract mixin class _$AttemptInfoCopyWith<$Res> implements $AttemptInfoCopyWith<$Res> {
  factory _$AttemptInfoCopyWith(_AttemptInfo value, $Res Function(_AttemptInfo) _then) = __$AttemptInfoCopyWithImpl;
@override @useResult
$Res call({
 int id, String status, bool paused, bool finished
});




}
/// @nodoc
class __$AttemptInfoCopyWithImpl<$Res>
    implements _$AttemptInfoCopyWith<$Res> {
  __$AttemptInfoCopyWithImpl(this._self, this._then);

  final _AttemptInfo _self;
  final $Res Function(_AttemptInfo) _then;

/// Create a copy of AttemptInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? paused = null,Object? finished = null,}) {
  return _then(_AttemptInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ExamModule {

 int get typeId;/// `listening` | `reading` | `writing`
 String get type; String get title; int get durationSeconds; String get status;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get startedAt;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get finishedAt; ModuleAudio? get audio; List<PartSummary> get parts;
/// Create a copy of ExamModule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamModuleCopyWith<ExamModule> get copyWith => _$ExamModuleCopyWithImpl<ExamModule>(this as ExamModule, _$identity);

  /// Serializes this ExamModule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExamModule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamModule&&(identical(other.typeId, _this.typeId) || other.typeId == _this.typeId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.finishedAt, _this.finishedAt) || other.finishedAt == _this.finishedAt)&&(identical(other.audio, _this.audio) || other.audio == _this.audio)&&const DeepCollectionEquality().equals(other.parts, _this.parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExamModule;
  return Object.hash(runtimeType,_this.typeId,_this.type,_this.title,_this.durationSeconds,_this.status,_this.startedAt,_this.finishedAt,_this.audio,const DeepCollectionEquality().hash(_this.parts));
}

@override
String toString() {
  final _this = this as ExamModule;
  return 'ExamModule(typeId: ${_this.typeId}, type: ${_this.type}, title: ${_this.title}, durationSeconds: ${_this.durationSeconds}, status: ${_this.status}, startedAt: ${_this.startedAt}, finishedAt: ${_this.finishedAt}, audio: ${_this.audio}, parts: ${_this.parts})';
}


}

/// @nodoc
abstract mixin class $ExamModuleCopyWith<$Res>  {
  factory $ExamModuleCopyWith(ExamModule value, $Res Function(ExamModule) _then) = _$ExamModuleCopyWithImpl;
@useResult
$Res call({
 int typeId, String type, String title, int durationSeconds, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startedAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt, ModuleAudio? audio, List<PartSummary> parts
});


$ModuleAudioCopyWith<$Res>? get audio;

}
/// @nodoc
class _$ExamModuleCopyWithImpl<$Res>
    implements $ExamModuleCopyWith<$Res> {
  _$ExamModuleCopyWithImpl(this._self, this._then);

  final ExamModule _self;
  final $Res Function(ExamModule) _then;

/// Create a copy of ExamModule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? typeId = null,Object? type = null,Object? title = null,Object? durationSeconds = null,Object? status = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? audio = freezed,Object? parts = null,}) {
  return _then(ExamModule(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as ModuleAudio?,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<PartSummary>,
  ));
}
/// Create a copy of ExamModule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModuleAudioCopyWith<$Res>? get audio {
    if (_self.audio == null) {
    return null;
  }

  return $ModuleAudioCopyWith<$Res>(_self.audio!, (value) {
    return _then(_self.copyWith(audio: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExamModule].
extension ExamModulePatterns on ExamModule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamModule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamModule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamModule value)  $default,){
final _that = this;
switch (_that) {
case _ExamModule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamModule value)?  $default,){
final _that = this;
switch (_that) {
case _ExamModule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int typeId,  String type,  String title,  int durationSeconds,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt,  ModuleAudio? audio,  List<PartSummary> parts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamModule() when $default != null:
return $default(_that.typeId,_that.type,_that.title,_that.durationSeconds,_that.status,_that.startedAt,_that.finishedAt,_that.audio,_that.parts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int typeId,  String type,  String title,  int durationSeconds,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt,  ModuleAudio? audio,  List<PartSummary> parts)  $default,) {final _that = this;
switch (_that) {
case _ExamModule():
return $default(_that.typeId,_that.type,_that.title,_that.durationSeconds,_that.status,_that.startedAt,_that.finishedAt,_that.audio,_that.parts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int typeId,  String type,  String title,  int durationSeconds,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt,  ModuleAudio? audio,  List<PartSummary> parts)?  $default,) {final _that = this;
switch (_that) {
case _ExamModule() when $default != null:
return $default(_that.typeId,_that.type,_that.title,_that.durationSeconds,_that.status,_that.startedAt,_that.finishedAt,_that.audio,_that.parts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExamModule extends ExamModule {
  const _ExamModule({required this.typeId, required this.type, required this.title, this.durationSeconds = 0, this.status = ModuleStatus.notStarted, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.finishedAt, this.audio,  List<PartSummary> parts = const <PartSummary>[]}): _parts = parts,super._();
  factory _ExamModule.fromJson(Map<String, dynamic> json) => _$ExamModuleFromJson(json);

@override final  int typeId;
/// `listening` | `reading` | `writing`
@override final  String type;
@override final  String title;
@override@JsonKey() final  int durationSeconds;
@override@JsonKey() final  String status;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? startedAt;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? finishedAt;
@override final  ModuleAudio? audio;
 final  List<PartSummary> _parts;
@override@JsonKey() List<PartSummary> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}


/// Create a copy of ExamModule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamModuleCopyWith<_ExamModule> get copyWith => __$ExamModuleCopyWithImpl<_ExamModule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamModuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamModule&&(identical(other.typeId, typeId) || other.typeId == typeId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.audio, audio) || other.audio == audio)&&const DeepCollectionEquality().equals(other.parts, _parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,typeId,type,title,durationSeconds,status,startedAt,finishedAt,audio,const DeepCollectionEquality().hash(_parts));
}

@override
String toString() {
    return 'ExamModule(typeId: $typeId, type: $type, title: $title, durationSeconds: $durationSeconds, status: $status, startedAt: $startedAt, finishedAt: $finishedAt, audio: $audio, parts: $parts)';
}


}

/// @nodoc
abstract mixin class _$ExamModuleCopyWith<$Res> implements $ExamModuleCopyWith<$Res> {
  factory _$ExamModuleCopyWith(_ExamModule value, $Res Function(_ExamModule) _then) = __$ExamModuleCopyWithImpl;
@override @useResult
$Res call({
 int typeId, String type, String title, int durationSeconds, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startedAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt, ModuleAudio? audio, List<PartSummary> parts
});


@override $ModuleAudioCopyWith<$Res>? get audio;

}
/// @nodoc
class __$ExamModuleCopyWithImpl<$Res>
    implements _$ExamModuleCopyWith<$Res> {
  __$ExamModuleCopyWithImpl(this._self, this._then);

  final _ExamModule _self;
  final $Res Function(_ExamModule) _then;

/// Create a copy of ExamModule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? typeId = null,Object? type = null,Object? title = null,Object? durationSeconds = null,Object? status = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? audio = freezed,Object? parts = null,}) {
  return _then(_ExamModule(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as ModuleAudio?,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<PartSummary>,
  ));
}

/// Create a copy of ExamModule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModuleAudioCopyWith<$Res>? get audio {
    if (_self.audio == null) {
    return null;
  }

  return $ModuleAudioCopyWith<$Res>(_self.audio!, (value) {
    return _then(_self.copyWith(audio: value));
  });
}
}


/// @nodoc
mixin _$ModuleAudio {

 String get url; int get durationSeconds;
/// Create a copy of ModuleAudio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModuleAudioCopyWith<ModuleAudio> get copyWith => _$ModuleAudioCopyWithImpl<ModuleAudio>(this as ModuleAudio, _$identity);

  /// Serializes this ModuleAudio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ModuleAudio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModuleAudio&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ModuleAudio;
  return Object.hash(runtimeType,_this.url,_this.durationSeconds);
}

@override
String toString() {
  final _this = this as ModuleAudio;
  return 'ModuleAudio(url: ${_this.url}, durationSeconds: ${_this.durationSeconds})';
}


}

/// @nodoc
abstract mixin class $ModuleAudioCopyWith<$Res>  {
  factory $ModuleAudioCopyWith(ModuleAudio value, $Res Function(ModuleAudio) _then) = _$ModuleAudioCopyWithImpl;
@useResult
$Res call({
 String url, int durationSeconds
});




}
/// @nodoc
class _$ModuleAudioCopyWithImpl<$Res>
    implements $ModuleAudioCopyWith<$Res> {
  _$ModuleAudioCopyWithImpl(this._self, this._then);

  final ModuleAudio _self;
  final $Res Function(ModuleAudio) _then;

/// Create a copy of ModuleAudio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? durationSeconds = null,}) {
  return _then(ModuleAudio(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModuleAudio].
extension ModuleAudioPatterns on ModuleAudio {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModuleAudio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModuleAudio() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModuleAudio value)  $default,){
final _that = this;
switch (_that) {
case _ModuleAudio():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModuleAudio value)?  $default,){
final _that = this;
switch (_that) {
case _ModuleAudio() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  int durationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModuleAudio() when $default != null:
return $default(_that.url,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  int durationSeconds)  $default,) {final _that = this;
switch (_that) {
case _ModuleAudio():
return $default(_that.url,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  int durationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _ModuleAudio() when $default != null:
return $default(_that.url,_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModuleAudio implements ModuleAudio {
  const _ModuleAudio({required this.url, this.durationSeconds = 0});
  factory _ModuleAudio.fromJson(Map<String, dynamic> json) => _$ModuleAudioFromJson(json);

@override final  String url;
@override@JsonKey() final  int durationSeconds;

/// Create a copy of ModuleAudio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModuleAudioCopyWith<_ModuleAudio> get copyWith => __$ModuleAudioCopyWithImpl<_ModuleAudio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModuleAudioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModuleAudio&&(identical(other.url, url) || other.url == url)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,url,durationSeconds);
}

@override
String toString() {
    return 'ModuleAudio(url: $url, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class _$ModuleAudioCopyWith<$Res> implements $ModuleAudioCopyWith<$Res> {
  factory _$ModuleAudioCopyWith(_ModuleAudio value, $Res Function(_ModuleAudio) _then) = __$ModuleAudioCopyWithImpl;
@override @useResult
$Res call({
 String url, int durationSeconds
});




}
/// @nodoc
class __$ModuleAudioCopyWithImpl<$Res>
    implements _$ModuleAudioCopyWith<$Res> {
  __$ModuleAudioCopyWithImpl(this._self, this._then);

  final _ModuleAudio _self;
  final $Res Function(_ModuleAudio) _then;

/// Create a copy of ModuleAudio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? durationSeconds = null,}) {
  return _then(_ModuleAudio(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PartSummary {

 int get id; String get name; int get order; int get questionCount; int get firstQuestionNumber;
/// Create a copy of PartSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartSummaryCopyWith<PartSummary> get copyWith => _$PartSummaryCopyWithImpl<PartSummary>(this as PartSummary, _$identity);

  /// Serializes this PartSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PartSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.questionCount, _this.questionCount) || other.questionCount == _this.questionCount)&&(identical(other.firstQuestionNumber, _this.firstQuestionNumber) || other.firstQuestionNumber == _this.firstQuestionNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PartSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.order,_this.questionCount,_this.firstQuestionNumber);
}

@override
String toString() {
  final _this = this as PartSummary;
  return 'PartSummary(id: ${_this.id}, name: ${_this.name}, order: ${_this.order}, questionCount: ${_this.questionCount}, firstQuestionNumber: ${_this.firstQuestionNumber})';
}


}

/// @nodoc
abstract mixin class $PartSummaryCopyWith<$Res>  {
  factory $PartSummaryCopyWith(PartSummary value, $Res Function(PartSummary) _then) = _$PartSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String name, int order, int questionCount, int firstQuestionNumber
});




}
/// @nodoc
class _$PartSummaryCopyWithImpl<$Res>
    implements $PartSummaryCopyWith<$Res> {
  _$PartSummaryCopyWithImpl(this._self, this._then);

  final PartSummary _self;
  final $Res Function(PartSummary) _then;

/// Create a copy of PartSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? order = null,Object? questionCount = null,Object? firstQuestionNumber = null,}) {
  return _then(PartSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,firstQuestionNumber: null == firstQuestionNumber ? _self.firstQuestionNumber : firstQuestionNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PartSummary].
extension PartSummaryPatterns on PartSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartSummary value)  $default,){
final _that = this;
switch (_that) {
case _PartSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PartSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int order,  int questionCount,  int firstQuestionNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartSummary() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.questionCount,_that.firstQuestionNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int order,  int questionCount,  int firstQuestionNumber)  $default,) {final _that = this;
switch (_that) {
case _PartSummary():
return $default(_that.id,_that.name,_that.order,_that.questionCount,_that.firstQuestionNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int order,  int questionCount,  int firstQuestionNumber)?  $default,) {final _that = this;
switch (_that) {
case _PartSummary() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.questionCount,_that.firstQuestionNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PartSummary implements PartSummary {
  const _PartSummary({required this.id, required this.name, this.order = 1, this.questionCount = 0, this.firstQuestionNumber = 1});
  factory _PartSummary.fromJson(Map<String, dynamic> json) => _$PartSummaryFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey() final  int order;
@override@JsonKey() final  int questionCount;
@override@JsonKey() final  int firstQuestionNumber;

/// Create a copy of PartSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartSummaryCopyWith<_PartSummary> get copyWith => __$PartSummaryCopyWithImpl<_PartSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.questionCount, questionCount) || other.questionCount == questionCount)&&(identical(other.firstQuestionNumber, firstQuestionNumber) || other.firstQuestionNumber == firstQuestionNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,order,questionCount,firstQuestionNumber);
}

@override
String toString() {
    return 'PartSummary(id: $id, name: $name, order: $order, questionCount: $questionCount, firstQuestionNumber: $firstQuestionNumber)';
}


}

/// @nodoc
abstract mixin class _$PartSummaryCopyWith<$Res> implements $PartSummaryCopyWith<$Res> {
  factory _$PartSummaryCopyWith(_PartSummary value, $Res Function(_PartSummary) _then) = __$PartSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int order, int questionCount, int firstQuestionNumber
});




}
/// @nodoc
class __$PartSummaryCopyWithImpl<$Res>
    implements _$PartSummaryCopyWith<$Res> {
  __$PartSummaryCopyWithImpl(this._self, this._then);

  final _PartSummary _self;
  final $Res Function(_PartSummary) _then;

/// Create a copy of PartSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? order = null,Object? questionCount = null,Object? firstQuestionNumber = null,}) {
  return _then(_PartSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,questionCount: null == questionCount ? _self.questionCount : questionCount // ignore: cast_nullable_to_non_nullable
as int,firstQuestionNumber: null == firstQuestionNumber ? _self.firstQuestionNumber : firstQuestionNumber // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PrefetchPayload {

 List<ExamModule> get modules; List<PartPayload> get parts; List<AudioAsset> get audio; List<String> get images;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of PrefetchPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrefetchPayloadCopyWith<PrefetchPayload> get copyWith => _$PrefetchPayloadCopyWithImpl<PrefetchPayload>(this as PrefetchPayload, _$identity);

  /// Serializes this PrefetchPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PrefetchPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrefetchPayload&&const DeepCollectionEquality().equals(other.modules, _this.modules)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&const DeepCollectionEquality().equals(other.audio, _this.audio)&&const DeepCollectionEquality().equals(other.images, _this.images)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PrefetchPayload;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.modules),const DeepCollectionEquality().hash(_this.parts),const DeepCollectionEquality().hash(_this.audio),const DeepCollectionEquality().hash(_this.images),_this.serverTime);
}

@override
String toString() {
  final _this = this as PrefetchPayload;
  return 'PrefetchPayload(modules: ${_this.modules}, parts: ${_this.parts}, audio: ${_this.audio}, images: ${_this.images}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $PrefetchPayloadCopyWith<$Res>  {
  factory $PrefetchPayloadCopyWith(PrefetchPayload value, $Res Function(PrefetchPayload) _then) = _$PrefetchPayloadCopyWithImpl;
@useResult
$Res call({
 List<ExamModule> modules, List<PartPayload> parts, List<AudioAsset> audio, List<String> images,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class _$PrefetchPayloadCopyWithImpl<$Res>
    implements $PrefetchPayloadCopyWith<$Res> {
  _$PrefetchPayloadCopyWithImpl(this._self, this._then);

  final PrefetchPayload _self;
  final $Res Function(PrefetchPayload) _then;

/// Create a copy of PrefetchPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modules = null,Object? parts = null,Object? audio = null,Object? images = null,Object? serverTime = freezed,}) {
  return _then(PrefetchPayload(
modules: null == modules ? _self.modules : modules // ignore: cast_nullable_to_non_nullable
as List<ExamModule>,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<PartPayload>,audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as List<AudioAsset>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PrefetchPayload].
extension PrefetchPayloadPatterns on PrefetchPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrefetchPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrefetchPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrefetchPayload value)  $default,){
final _that = this;
switch (_that) {
case _PrefetchPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrefetchPayload value)?  $default,){
final _that = this;
switch (_that) {
case _PrefetchPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ExamModule> modules,  List<PartPayload> parts,  List<AudioAsset> audio,  List<String> images, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrefetchPayload() when $default != null:
return $default(_that.modules,_that.parts,_that.audio,_that.images,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ExamModule> modules,  List<PartPayload> parts,  List<AudioAsset> audio,  List<String> images, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _PrefetchPayload():
return $default(_that.modules,_that.parts,_that.audio,_that.images,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ExamModule> modules,  List<PartPayload> parts,  List<AudioAsset> audio,  List<String> images, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _PrefetchPayload() when $default != null:
return $default(_that.modules,_that.parts,_that.audio,_that.images,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrefetchPayload implements PrefetchPayload {
  const _PrefetchPayload({ List<ExamModule> modules = const <ExamModule>[],  List<PartPayload> parts = const <PartPayload>[],  List<AudioAsset> audio = const <AudioAsset>[],  List<String> images = const <String>[], @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime}): _modules = modules,_parts = parts,_audio = audio,_images = images;
  factory _PrefetchPayload.fromJson(Map<String, dynamic> json) => _$PrefetchPayloadFromJson(json);

 final  List<ExamModule> _modules;
@override@JsonKey() List<ExamModule> get modules {
  if (_modules is EqualUnmodifiableListView) return _modules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modules);
}

 final  List<PartPayload> _parts;
@override@JsonKey() List<PartPayload> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

 final  List<AudioAsset> _audio;
@override@JsonKey() List<AudioAsset> get audio {
  if (_audio is EqualUnmodifiableListView) return _audio;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audio);
}

 final  List<String> _images;
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of PrefetchPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrefetchPayloadCopyWith<_PrefetchPayload> get copyWith => __$PrefetchPayloadCopyWithImpl<_PrefetchPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrefetchPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrefetchPayload&&const DeepCollectionEquality().equals(other.modules, _modules)&&const DeepCollectionEquality().equals(other.parts, _parts)&&const DeepCollectionEquality().equals(other.audio, _audio)&&const DeepCollectionEquality().equals(other.images, _images)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_modules),const DeepCollectionEquality().hash(_parts),const DeepCollectionEquality().hash(_audio),const DeepCollectionEquality().hash(_images),serverTime);
}

@override
String toString() {
    return 'PrefetchPayload(modules: $modules, parts: $parts, audio: $audio, images: $images, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$PrefetchPayloadCopyWith<$Res> implements $PrefetchPayloadCopyWith<$Res> {
  factory _$PrefetchPayloadCopyWith(_PrefetchPayload value, $Res Function(_PrefetchPayload) _then) = __$PrefetchPayloadCopyWithImpl;
@override @useResult
$Res call({
 List<ExamModule> modules, List<PartPayload> parts, List<AudioAsset> audio, List<String> images,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class __$PrefetchPayloadCopyWithImpl<$Res>
    implements _$PrefetchPayloadCopyWith<$Res> {
  __$PrefetchPayloadCopyWithImpl(this._self, this._then);

  final _PrefetchPayload _self;
  final $Res Function(_PrefetchPayload) _then;

/// Create a copy of PrefetchPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modules = null,Object? parts = null,Object? audio = null,Object? images = null,Object? serverTime = freezed,}) {
  return _then(_PrefetchPayload(
modules: null == modules ? _self._modules : modules // ignore: cast_nullable_to_non_nullable
as List<ExamModule>,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<PartPayload>,audio: null == audio ? _self._audio : audio // ignore: cast_nullable_to_non_nullable
as List<AudioAsset>,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AudioAsset {

 String get key; String get url; int get size; String? get sha256;
/// Create a copy of AudioAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioAssetCopyWith<AudioAsset> get copyWith => _$AudioAssetCopyWithImpl<AudioAsset>(this as AudioAsset, _$identity);

  /// Serializes this AudioAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AudioAsset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioAsset&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AudioAsset;
  return Object.hash(runtimeType,_this.key,_this.url,_this.size,_this.sha256);
}

@override
String toString() {
  final _this = this as AudioAsset;
  return 'AudioAsset(key: ${_this.key}, url: ${_this.url}, size: ${_this.size}, sha256: ${_this.sha256})';
}


}

/// @nodoc
abstract mixin class $AudioAssetCopyWith<$Res>  {
  factory $AudioAssetCopyWith(AudioAsset value, $Res Function(AudioAsset) _then) = _$AudioAssetCopyWithImpl;
@useResult
$Res call({
 String key, String url, int size, String? sha256
});




}
/// @nodoc
class _$AudioAssetCopyWithImpl<$Res>
    implements $AudioAssetCopyWith<$Res> {
  _$AudioAssetCopyWithImpl(this._self, this._then);

  final AudioAsset _self;
  final $Res Function(AudioAsset) _then;

/// Create a copy of AudioAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? url = null,Object? size = null,Object? sha256 = freezed,}) {
  return _then(AudioAsset(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioAsset].
extension AudioAssetPatterns on AudioAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioAsset value)  $default,){
final _that = this;
switch (_that) {
case _AudioAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioAsset value)?  $default,){
final _that = this;
switch (_that) {
case _AudioAsset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String url,  int size,  String? sha256)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioAsset() when $default != null:
return $default(_that.key,_that.url,_that.size,_that.sha256);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String url,  int size,  String? sha256)  $default,) {final _that = this;
switch (_that) {
case _AudioAsset():
return $default(_that.key,_that.url,_that.size,_that.sha256);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String url,  int size,  String? sha256)?  $default,) {final _that = this;
switch (_that) {
case _AudioAsset() when $default != null:
return $default(_that.key,_that.url,_that.size,_that.sha256);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AudioAsset implements AudioAsset {
  const _AudioAsset({required this.key, required this.url, this.size = 0, this.sha256});
  factory _AudioAsset.fromJson(Map<String, dynamic> json) => _$AudioAssetFromJson(json);

@override final  String key;
@override final  String url;
@override@JsonKey() final  int size;
@override final  String? sha256;

/// Create a copy of AudioAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioAssetCopyWith<_AudioAsset> get copyWith => __$AudioAssetCopyWithImpl<_AudioAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AudioAssetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioAsset&&(identical(other.key, key) || other.key == key)&&(identical(other.url, url) || other.url == url)&&(identical(other.size, size) || other.size == size)&&(identical(other.sha256, sha256) || other.sha256 == sha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,url,size,sha256);
}

@override
String toString() {
    return 'AudioAsset(key: $key, url: $url, size: $size, sha256: $sha256)';
}


}

/// @nodoc
abstract mixin class _$AudioAssetCopyWith<$Res> implements $AudioAssetCopyWith<$Res> {
  factory _$AudioAssetCopyWith(_AudioAsset value, $Res Function(_AudioAsset) _then) = __$AudioAssetCopyWithImpl;
@override @useResult
$Res call({
 String key, String url, int size, String? sha256
});




}
/// @nodoc
class __$AudioAssetCopyWithImpl<$Res>
    implements _$AudioAssetCopyWith<$Res> {
  __$AudioAssetCopyWithImpl(this._self, this._then);

  final _AudioAsset _self;
  final $Res Function(_AudioAsset) _then;

/// Create a copy of AudioAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? url = null,Object? size = null,Object? sha256 = freezed,}) {
  return _then(_AudioAsset(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ModuleStartResponse {

 int get typeId; String get status;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get startedAt;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get finishedAt;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of ModuleStartResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModuleStartResponseCopyWith<ModuleStartResponse> get copyWith => _$ModuleStartResponseCopyWithImpl<ModuleStartResponse>(this as ModuleStartResponse, _$identity);

  /// Serializes this ModuleStartResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ModuleStartResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModuleStartResponse&&(identical(other.typeId, _this.typeId) || other.typeId == _this.typeId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.finishedAt, _this.finishedAt) || other.finishedAt == _this.finishedAt)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ModuleStartResponse;
  return Object.hash(runtimeType,_this.typeId,_this.status,_this.startedAt,_this.finishedAt,_this.serverTime);
}

@override
String toString() {
  final _this = this as ModuleStartResponse;
  return 'ModuleStartResponse(typeId: ${_this.typeId}, status: ${_this.status}, startedAt: ${_this.startedAt}, finishedAt: ${_this.finishedAt}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $ModuleStartResponseCopyWith<$Res>  {
  factory $ModuleStartResponseCopyWith(ModuleStartResponse value, $Res Function(ModuleStartResponse) _then) = _$ModuleStartResponseCopyWithImpl;
@useResult
$Res call({
 int typeId, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startedAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class _$ModuleStartResponseCopyWithImpl<$Res>
    implements $ModuleStartResponseCopyWith<$Res> {
  _$ModuleStartResponseCopyWithImpl(this._self, this._then);

  final ModuleStartResponse _self;
  final $Res Function(ModuleStartResponse) _then;

/// Create a copy of ModuleStartResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? typeId = null,Object? status = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? serverTime = freezed,}) {
  return _then(ModuleStartResponse(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModuleStartResponse].
extension ModuleStartResponsePatterns on ModuleStartResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModuleStartResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModuleStartResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModuleStartResponse value)  $default,){
final _that = this;
switch (_that) {
case _ModuleStartResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModuleStartResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ModuleStartResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModuleStartResponse() when $default != null:
return $default(_that.typeId,_that.status,_that.startedAt,_that.finishedAt,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _ModuleStartResponse():
return $default(_that.typeId,_that.status,_that.startedAt,_that.finishedAt,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _ModuleStartResponse() when $default != null:
return $default(_that.typeId,_that.status,_that.startedAt,_that.finishedAt,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModuleStartResponse implements ModuleStartResponse {
  const _ModuleStartResponse({required this.typeId, required this.status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.startedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.finishedAt, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime});
  factory _ModuleStartResponse.fromJson(Map<String, dynamic> json) => _$ModuleStartResponseFromJson(json);

@override final  int typeId;
@override final  String status;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? startedAt;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? finishedAt;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of ModuleStartResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModuleStartResponseCopyWith<_ModuleStartResponse> get copyWith => __$ModuleStartResponseCopyWithImpl<_ModuleStartResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModuleStartResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModuleStartResponse&&(identical(other.typeId, typeId) || other.typeId == typeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,typeId,status,startedAt,finishedAt,serverTime);
}

@override
String toString() {
    return 'ModuleStartResponse(typeId: $typeId, status: $status, startedAt: $startedAt, finishedAt: $finishedAt, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$ModuleStartResponseCopyWith<$Res> implements $ModuleStartResponseCopyWith<$Res> {
  factory _$ModuleStartResponseCopyWith(_ModuleStartResponse value, $Res Function(_ModuleStartResponse) _then) = __$ModuleStartResponseCopyWithImpl;
@override @useResult
$Res call({
 int typeId, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? startedAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class __$ModuleStartResponseCopyWithImpl<$Res>
    implements _$ModuleStartResponseCopyWith<$Res> {
  __$ModuleStartResponseCopyWithImpl(this._self, this._then);

  final _ModuleStartResponse _self;
  final $Res Function(_ModuleStartResponse) _then;

/// Create a copy of ModuleStartResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? typeId = null,Object? status = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? serverTime = freezed,}) {
  return _then(_ModuleStartResponse(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ModuleSubmitResponse {

 int get typeId; String get status;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of ModuleSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModuleSubmitResponseCopyWith<ModuleSubmitResponse> get copyWith => _$ModuleSubmitResponseCopyWithImpl<ModuleSubmitResponse>(this as ModuleSubmitResponse, _$identity);

  /// Serializes this ModuleSubmitResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ModuleSubmitResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModuleSubmitResponse&&(identical(other.typeId, _this.typeId) || other.typeId == _this.typeId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ModuleSubmitResponse;
  return Object.hash(runtimeType,_this.typeId,_this.status,_this.serverTime);
}

@override
String toString() {
  final _this = this as ModuleSubmitResponse;
  return 'ModuleSubmitResponse(typeId: ${_this.typeId}, status: ${_this.status}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $ModuleSubmitResponseCopyWith<$Res>  {
  factory $ModuleSubmitResponseCopyWith(ModuleSubmitResponse value, $Res Function(ModuleSubmitResponse) _then) = _$ModuleSubmitResponseCopyWithImpl;
@useResult
$Res call({
 int typeId, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class _$ModuleSubmitResponseCopyWithImpl<$Res>
    implements $ModuleSubmitResponseCopyWith<$Res> {
  _$ModuleSubmitResponseCopyWithImpl(this._self, this._then);

  final ModuleSubmitResponse _self;
  final $Res Function(ModuleSubmitResponse) _then;

/// Create a copy of ModuleSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? typeId = null,Object? status = null,Object? serverTime = freezed,}) {
  return _then(ModuleSubmitResponse(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModuleSubmitResponse].
extension ModuleSubmitResponsePatterns on ModuleSubmitResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModuleSubmitResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModuleSubmitResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModuleSubmitResponse value)  $default,){
final _that = this;
switch (_that) {
case _ModuleSubmitResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModuleSubmitResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ModuleSubmitResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModuleSubmitResponse() when $default != null:
return $default(_that.typeId,_that.status,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _ModuleSubmitResponse():
return $default(_that.typeId,_that.status,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _ModuleSubmitResponse() when $default != null:
return $default(_that.typeId,_that.status,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModuleSubmitResponse implements ModuleSubmitResponse {
  const _ModuleSubmitResponse({required this.typeId, required this.status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime});
  factory _ModuleSubmitResponse.fromJson(Map<String, dynamic> json) => _$ModuleSubmitResponseFromJson(json);

@override final  int typeId;
@override final  String status;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of ModuleSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModuleSubmitResponseCopyWith<_ModuleSubmitResponse> get copyWith => __$ModuleSubmitResponseCopyWithImpl<_ModuleSubmitResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModuleSubmitResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModuleSubmitResponse&&(identical(other.typeId, typeId) || other.typeId == typeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,typeId,status,serverTime);
}

@override
String toString() {
    return 'ModuleSubmitResponse(typeId: $typeId, status: $status, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$ModuleSubmitResponseCopyWith<$Res> implements $ModuleSubmitResponseCopyWith<$Res> {
  factory _$ModuleSubmitResponseCopyWith(_ModuleSubmitResponse value, $Res Function(_ModuleSubmitResponse) _then) = __$ModuleSubmitResponseCopyWithImpl;
@override @useResult
$Res call({
 int typeId, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class __$ModuleSubmitResponseCopyWithImpl<$Res>
    implements _$ModuleSubmitResponseCopyWith<$Res> {
  __$ModuleSubmitResponseCopyWithImpl(this._self, this._then);

  final _ModuleSubmitResponse _self;
  final $Res Function(_ModuleSubmitResponse) _then;

/// Create a copy of ModuleSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? typeId = null,Object? status = null,Object? serverTime = freezed,}) {
  return _then(_ModuleSubmitResponse(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ExamSubmitResponse {

 String get status;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of ExamSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamSubmitResponseCopyWith<ExamSubmitResponse> get copyWith => _$ExamSubmitResponseCopyWithImpl<ExamSubmitResponse>(this as ExamSubmitResponse, _$identity);

  /// Serializes this ExamSubmitResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExamSubmitResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamSubmitResponse&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExamSubmitResponse;
  return Object.hash(runtimeType,_this.status,_this.serverTime);
}

@override
String toString() {
  final _this = this as ExamSubmitResponse;
  return 'ExamSubmitResponse(status: ${_this.status}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $ExamSubmitResponseCopyWith<$Res>  {
  factory $ExamSubmitResponseCopyWith(ExamSubmitResponse value, $Res Function(ExamSubmitResponse) _then) = _$ExamSubmitResponseCopyWithImpl;
@useResult
$Res call({
 String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class _$ExamSubmitResponseCopyWithImpl<$Res>
    implements $ExamSubmitResponseCopyWith<$Res> {
  _$ExamSubmitResponseCopyWithImpl(this._self, this._then);

  final ExamSubmitResponse _self;
  final $Res Function(ExamSubmitResponse) _then;

/// Create a copy of ExamSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? serverTime = freezed,}) {
  return _then(ExamSubmitResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExamSubmitResponse].
extension ExamSubmitResponsePatterns on ExamSubmitResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamSubmitResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamSubmitResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamSubmitResponse value)  $default,){
final _that = this;
switch (_that) {
case _ExamSubmitResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamSubmitResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ExamSubmitResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamSubmitResponse() when $default != null:
return $default(_that.status,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _ExamSubmitResponse():
return $default(_that.status,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _ExamSubmitResponse() when $default != null:
return $default(_that.status,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExamSubmitResponse implements ExamSubmitResponse {
  const _ExamSubmitResponse({required this.status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime});
  factory _ExamSubmitResponse.fromJson(Map<String, dynamic> json) => _$ExamSubmitResponseFromJson(json);

@override final  String status;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of ExamSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamSubmitResponseCopyWith<_ExamSubmitResponse> get copyWith => __$ExamSubmitResponseCopyWithImpl<_ExamSubmitResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamSubmitResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamSubmitResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,serverTime);
}

@override
String toString() {
    return 'ExamSubmitResponse(status: $status, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$ExamSubmitResponseCopyWith<$Res> implements $ExamSubmitResponseCopyWith<$Res> {
  factory _$ExamSubmitResponseCopyWith(_ExamSubmitResponse value, $Res Function(_ExamSubmitResponse) _then) = __$ExamSubmitResponseCopyWithImpl;
@override @useResult
$Res call({
 String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class __$ExamSubmitResponseCopyWithImpl<$Res>
    implements _$ExamSubmitResponseCopyWith<$Res> {
  __$ExamSubmitResponseCopyWithImpl(this._self, this._then);

  final _ExamSubmitResponse _self;
  final $Res Function(_ExamSubmitResponse) _then;

/// Create a copy of ExamSubmitResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? serverTime = freezed,}) {
  return _then(_ExamSubmitResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$AnswerItem {

 String get clientUuid; int get partId; int get questionId; String? get text; List<int> get optionIds;@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) DateTime get changedAt;
/// Create a copy of AnswerItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswerItemCopyWith<AnswerItem> get copyWith => _$AnswerItemCopyWithImpl<AnswerItem>(this as AnswerItem, _$identity);

  /// Serializes this AnswerItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AnswerItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswerItem&&(identical(other.clientUuid, _this.clientUuid) || other.clientUuid == _this.clientUuid)&&(identical(other.partId, _this.partId) || other.partId == _this.partId)&&(identical(other.questionId, _this.questionId) || other.questionId == _this.questionId)&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.optionIds, _this.optionIds)&&(identical(other.changedAt, _this.changedAt) || other.changedAt == _this.changedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AnswerItem;
  return Object.hash(runtimeType,_this.clientUuid,_this.partId,_this.questionId,_this.text,const DeepCollectionEquality().hash(_this.optionIds),_this.changedAt);
}

@override
String toString() {
  final _this = this as AnswerItem;
  return 'AnswerItem(clientUuid: ${_this.clientUuid}, partId: ${_this.partId}, questionId: ${_this.questionId}, text: ${_this.text}, optionIds: ${_this.optionIds}, changedAt: ${_this.changedAt})';
}


}

/// @nodoc
abstract mixin class $AnswerItemCopyWith<$Res>  {
  factory $AnswerItemCopyWith(AnswerItem value, $Res Function(AnswerItem) _then) = _$AnswerItemCopyWithImpl;
@useResult
$Res call({
 String clientUuid, int partId, int questionId, String? text, List<int> optionIds,@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) DateTime changedAt
});




}
/// @nodoc
class _$AnswerItemCopyWithImpl<$Res>
    implements $AnswerItemCopyWith<$Res> {
  _$AnswerItemCopyWithImpl(this._self, this._then);

  final AnswerItem _self;
  final $Res Function(AnswerItem) _then;

/// Create a copy of AnswerItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientUuid = null,Object? partId = null,Object? questionId = null,Object? text = freezed,Object? optionIds = null,Object? changedAt = null,}) {
  return _then(AnswerItem(
clientUuid: null == clientUuid ? _self.clientUuid : clientUuid // ignore: cast_nullable_to_non_nullable
as String,partId: null == partId ? _self.partId : partId // ignore: cast_nullable_to_non_nullable
as int,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,optionIds: null == optionIds ? _self.optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as List<int>,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AnswerItem].
extension AnswerItemPatterns on AnswerItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnswerItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnswerItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnswerItem value)  $default,){
final _that = this;
switch (_that) {
case _AnswerItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnswerItem value)?  $default,){
final _that = this;
switch (_that) {
case _AnswerItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientUuid,  int partId,  int questionId,  String? text,  List<int> optionIds, @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)  DateTime changedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnswerItem() when $default != null:
return $default(_that.clientUuid,_that.partId,_that.questionId,_that.text,_that.optionIds,_that.changedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientUuid,  int partId,  int questionId,  String? text,  List<int> optionIds, @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)  DateTime changedAt)  $default,) {final _that = this;
switch (_that) {
case _AnswerItem():
return $default(_that.clientUuid,_that.partId,_that.questionId,_that.text,_that.optionIds,_that.changedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientUuid,  int partId,  int questionId,  String? text,  List<int> optionIds, @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)  DateTime changedAt)?  $default,) {final _that = this;
switch (_that) {
case _AnswerItem() when $default != null:
return $default(_that.clientUuid,_that.partId,_that.questionId,_that.text,_that.optionIds,_that.changedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnswerItem implements AnswerItem {
  const _AnswerItem({required this.clientUuid, required this.partId, required this.questionId, this.text,  List<int> optionIds = const <int>[], @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) required this.changedAt}): _optionIds = optionIds;
  factory _AnswerItem.fromJson(Map<String, dynamic> json) => _$AnswerItemFromJson(json);

@override final  String clientUuid;
@override final  int partId;
@override final  int questionId;
@override final  String? text;
 final  List<int> _optionIds;
@override@JsonKey() List<int> get optionIds {
  if (_optionIds is EqualUnmodifiableListView) return _optionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_optionIds);
}

@override@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) final  DateTime changedAt;

/// Create a copy of AnswerItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswerItemCopyWith<_AnswerItem> get copyWith => __$AnswerItemCopyWithImpl<_AnswerItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnswerItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnswerItem&&(identical(other.clientUuid, clientUuid) || other.clientUuid == clientUuid)&&(identical(other.partId, partId) || other.partId == partId)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.optionIds, _optionIds)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientUuid,partId,questionId,text,const DeepCollectionEquality().hash(_optionIds),changedAt);
}

@override
String toString() {
    return 'AnswerItem(clientUuid: $clientUuid, partId: $partId, questionId: $questionId, text: $text, optionIds: $optionIds, changedAt: $changedAt)';
}


}

/// @nodoc
abstract mixin class _$AnswerItemCopyWith<$Res> implements $AnswerItemCopyWith<$Res> {
  factory _$AnswerItemCopyWith(_AnswerItem value, $Res Function(_AnswerItem) _then) = __$AnswerItemCopyWithImpl;
@override @useResult
$Res call({
 String clientUuid, int partId, int questionId, String? text, List<int> optionIds,@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) DateTime changedAt
});




}
/// @nodoc
class __$AnswerItemCopyWithImpl<$Res>
    implements _$AnswerItemCopyWith<$Res> {
  __$AnswerItemCopyWithImpl(this._self, this._then);

  final _AnswerItem _self;
  final $Res Function(_AnswerItem) _then;

/// Create a copy of AnswerItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientUuid = null,Object? partId = null,Object? questionId = null,Object? text = freezed,Object? optionIds = null,Object? changedAt = null,}) {
  return _then(_AnswerItem(
clientUuid: null == clientUuid ? _self.clientUuid : clientUuid // ignore: cast_nullable_to_non_nullable
as String,partId: null == partId ? _self.partId : partId // ignore: cast_nullable_to_non_nullable
as int,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,optionIds: null == optionIds ? _self._optionIds : optionIds // ignore: cast_nullable_to_non_nullable
as List<int>,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$AnswerResult {

 String get clientUuid; String get status; String? get reason;
/// Create a copy of AnswerResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswerResultCopyWith<AnswerResult> get copyWith => _$AnswerResultCopyWithImpl<AnswerResult>(this as AnswerResult, _$identity);

  /// Serializes this AnswerResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AnswerResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswerResult&&(identical(other.clientUuid, _this.clientUuid) || other.clientUuid == _this.clientUuid)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AnswerResult;
  return Object.hash(runtimeType,_this.clientUuid,_this.status,_this.reason);
}

@override
String toString() {
  final _this = this as AnswerResult;
  return 'AnswerResult(clientUuid: ${_this.clientUuid}, status: ${_this.status}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $AnswerResultCopyWith<$Res>  {
  factory $AnswerResultCopyWith(AnswerResult value, $Res Function(AnswerResult) _then) = _$AnswerResultCopyWithImpl;
@useResult
$Res call({
 String clientUuid, String status, String? reason
});




}
/// @nodoc
class _$AnswerResultCopyWithImpl<$Res>
    implements $AnswerResultCopyWith<$Res> {
  _$AnswerResultCopyWithImpl(this._self, this._then);

  final AnswerResult _self;
  final $Res Function(AnswerResult) _then;

/// Create a copy of AnswerResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientUuid = null,Object? status = null,Object? reason = freezed,}) {
  return _then(AnswerResult(
clientUuid: null == clientUuid ? _self.clientUuid : clientUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnswerResult].
extension AnswerResultPatterns on AnswerResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnswerResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnswerResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnswerResult value)  $default,){
final _that = this;
switch (_that) {
case _AnswerResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnswerResult value)?  $default,){
final _that = this;
switch (_that) {
case _AnswerResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientUuid,  String status,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnswerResult() when $default != null:
return $default(_that.clientUuid,_that.status,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientUuid,  String status,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _AnswerResult():
return $default(_that.clientUuid,_that.status,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientUuid,  String status,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _AnswerResult() when $default != null:
return $default(_that.clientUuid,_that.status,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnswerResult implements AnswerResult {
  const _AnswerResult({required this.clientUuid, required this.status, this.reason});
  factory _AnswerResult.fromJson(Map<String, dynamic> json) => _$AnswerResultFromJson(json);

@override final  String clientUuid;
@override final  String status;
@override final  String? reason;

/// Create a copy of AnswerResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswerResultCopyWith<_AnswerResult> get copyWith => __$AnswerResultCopyWithImpl<_AnswerResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnswerResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnswerResult&&(identical(other.clientUuid, clientUuid) || other.clientUuid == clientUuid)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientUuid,status,reason);
}

@override
String toString() {
    return 'AnswerResult(clientUuid: $clientUuid, status: $status, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$AnswerResultCopyWith<$Res> implements $AnswerResultCopyWith<$Res> {
  factory _$AnswerResultCopyWith(_AnswerResult value, $Res Function(_AnswerResult) _then) = __$AnswerResultCopyWithImpl;
@override @useResult
$Res call({
 String clientUuid, String status, String? reason
});




}
/// @nodoc
class __$AnswerResultCopyWithImpl<$Res>
    implements _$AnswerResultCopyWith<$Res> {
  __$AnswerResultCopyWithImpl(this._self, this._then);

  final _AnswerResult _self;
  final $Res Function(_AnswerResult) _then;

/// Create a copy of AnswerResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientUuid = null,Object? status = null,Object? reason = freezed,}) {
  return _then(_AnswerResult(
clientUuid: null == clientUuid ? _self.clientUuid : clientUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AnswersResponse {

 List<AnswerResult> get results;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of AnswersResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswersResponseCopyWith<AnswersResponse> get copyWith => _$AnswersResponseCopyWithImpl<AnswersResponse>(this as AnswersResponse, _$identity);

  /// Serializes this AnswersResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AnswersResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswersResponse&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AnswersResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.results),_this.serverTime);
}

@override
String toString() {
  final _this = this as AnswersResponse;
  return 'AnswersResponse(results: ${_this.results}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $AnswersResponseCopyWith<$Res>  {
  factory $AnswersResponseCopyWith(AnswersResponse value, $Res Function(AnswersResponse) _then) = _$AnswersResponseCopyWithImpl;
@useResult
$Res call({
 List<AnswerResult> results,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class _$AnswersResponseCopyWithImpl<$Res>
    implements $AnswersResponseCopyWith<$Res> {
  _$AnswersResponseCopyWithImpl(this._self, this._then);

  final AnswersResponse _self;
  final $Res Function(AnswersResponse) _then;

/// Create a copy of AnswersResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? results = null,Object? serverTime = freezed,}) {
  return _then(AnswersResponse(
results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<AnswerResult>,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnswersResponse].
extension AnswersResponsePatterns on AnswersResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnswersResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnswersResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnswersResponse value)  $default,){
final _that = this;
switch (_that) {
case _AnswersResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnswersResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AnswersResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AnswerResult> results, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnswersResponse() when $default != null:
return $default(_that.results,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AnswerResult> results, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _AnswersResponse():
return $default(_that.results,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AnswerResult> results, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _AnswersResponse() when $default != null:
return $default(_that.results,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnswersResponse implements AnswersResponse {
  const _AnswersResponse({ List<AnswerResult> results = const <AnswerResult>[], @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime}): _results = results;
  factory _AnswersResponse.fromJson(Map<String, dynamic> json) => _$AnswersResponseFromJson(json);

 final  List<AnswerResult> _results;
@override@JsonKey() List<AnswerResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of AnswersResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswersResponseCopyWith<_AnswersResponse> get copyWith => __$AnswersResponseCopyWithImpl<_AnswersResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnswersResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnswersResponse&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_results),serverTime);
}

@override
String toString() {
    return 'AnswersResponse(results: $results, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$AnswersResponseCopyWith<$Res> implements $AnswersResponseCopyWith<$Res> {
  factory _$AnswersResponseCopyWith(_AnswersResponse value, $Res Function(_AnswersResponse) _then) = __$AnswersResponseCopyWithImpl;
@override @useResult
$Res call({
 List<AnswerResult> results,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class __$AnswersResponseCopyWithImpl<$Res>
    implements _$AnswersResponseCopyWith<$Res> {
  __$AnswersResponseCopyWithImpl(this._self, this._then);

  final _AnswersResponse _self;
  final $Res Function(_AnswersResponse) _then;

/// Create a copy of AnswersResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? results = null,Object? serverTime = freezed,}) {
  return _then(_AnswersResponse(
results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<AnswerResult>,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ExamHeartbeatResponse {

@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime; bool get paused; bool get finished; bool get unlock; List<ModuleTimer> get modules;
/// Create a copy of ExamHeartbeatResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamHeartbeatResponseCopyWith<ExamHeartbeatResponse> get copyWith => _$ExamHeartbeatResponseCopyWithImpl<ExamHeartbeatResponse>(this as ExamHeartbeatResponse, _$identity);

  /// Serializes this ExamHeartbeatResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ExamHeartbeatResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamHeartbeatResponse&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.paused, _this.paused) || other.paused == _this.paused)&&(identical(other.finished, _this.finished) || other.finished == _this.finished)&&(identical(other.unlock, _this.unlock) || other.unlock == _this.unlock)&&const DeepCollectionEquality().equals(other.modules, _this.modules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ExamHeartbeatResponse;
  return Object.hash(runtimeType,_this.serverTime,_this.paused,_this.finished,_this.unlock,const DeepCollectionEquality().hash(_this.modules));
}

@override
String toString() {
  final _this = this as ExamHeartbeatResponse;
  return 'ExamHeartbeatResponse(serverTime: ${_this.serverTime}, paused: ${_this.paused}, finished: ${_this.finished}, unlock: ${_this.unlock}, modules: ${_this.modules})';
}


}

/// @nodoc
abstract mixin class $ExamHeartbeatResponseCopyWith<$Res>  {
  factory $ExamHeartbeatResponseCopyWith(ExamHeartbeatResponse value, $Res Function(ExamHeartbeatResponse) _then) = _$ExamHeartbeatResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime, bool paused, bool finished, bool unlock, List<ModuleTimer> modules
});




}
/// @nodoc
class _$ExamHeartbeatResponseCopyWithImpl<$Res>
    implements $ExamHeartbeatResponseCopyWith<$Res> {
  _$ExamHeartbeatResponseCopyWithImpl(this._self, this._then);

  final ExamHeartbeatResponse _self;
  final $Res Function(ExamHeartbeatResponse) _then;

/// Create a copy of ExamHeartbeatResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverTime = freezed,Object? paused = null,Object? finished = null,Object? unlock = null,Object? modules = null,}) {
  return _then(ExamHeartbeatResponse(
serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,unlock: null == unlock ? _self.unlock : unlock // ignore: cast_nullable_to_non_nullable
as bool,modules: null == modules ? _self.modules : modules // ignore: cast_nullable_to_non_nullable
as List<ModuleTimer>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExamHeartbeatResponse].
extension ExamHeartbeatResponsePatterns on ExamHeartbeatResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamHeartbeatResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamHeartbeatResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamHeartbeatResponse value)  $default,){
final _that = this;
switch (_that) {
case _ExamHeartbeatResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamHeartbeatResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ExamHeartbeatResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool paused,  bool finished,  bool unlock,  List<ModuleTimer> modules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamHeartbeatResponse() when $default != null:
return $default(_that.serverTime,_that.paused,_that.finished,_that.unlock,_that.modules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool paused,  bool finished,  bool unlock,  List<ModuleTimer> modules)  $default,) {final _that = this;
switch (_that) {
case _ExamHeartbeatResponse():
return $default(_that.serverTime,_that.paused,_that.finished,_that.unlock,_that.modules);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool paused,  bool finished,  bool unlock,  List<ModuleTimer> modules)?  $default,) {final _that = this;
switch (_that) {
case _ExamHeartbeatResponse() when $default != null:
return $default(_that.serverTime,_that.paused,_that.finished,_that.unlock,_that.modules);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExamHeartbeatResponse implements ExamHeartbeatResponse {
  const _ExamHeartbeatResponse({@JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime, this.paused = false, this.finished = false, this.unlock = false,  List<ModuleTimer> modules = const <ModuleTimer>[]}): _modules = modules;
  factory _ExamHeartbeatResponse.fromJson(Map<String, dynamic> json) => _$ExamHeartbeatResponseFromJson(json);

@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;
@override@JsonKey() final  bool paused;
@override@JsonKey() final  bool finished;
@override@JsonKey() final  bool unlock;
 final  List<ModuleTimer> _modules;
@override@JsonKey() List<ModuleTimer> get modules {
  if (_modules is EqualUnmodifiableListView) return _modules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modules);
}


/// Create a copy of ExamHeartbeatResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamHeartbeatResponseCopyWith<_ExamHeartbeatResponse> get copyWith => __$ExamHeartbeatResponseCopyWithImpl<_ExamHeartbeatResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamHeartbeatResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamHeartbeatResponse&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.paused, paused) || other.paused == paused)&&(identical(other.finished, finished) || other.finished == finished)&&(identical(other.unlock, unlock) || other.unlock == unlock)&&const DeepCollectionEquality().equals(other.modules, _modules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,serverTime,paused,finished,unlock,const DeepCollectionEquality().hash(_modules));
}

@override
String toString() {
    return 'ExamHeartbeatResponse(serverTime: $serverTime, paused: $paused, finished: $finished, unlock: $unlock, modules: $modules)';
}


}

/// @nodoc
abstract mixin class _$ExamHeartbeatResponseCopyWith<$Res> implements $ExamHeartbeatResponseCopyWith<$Res> {
  factory _$ExamHeartbeatResponseCopyWith(_ExamHeartbeatResponse value, $Res Function(_ExamHeartbeatResponse) _then) = __$ExamHeartbeatResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime, bool paused, bool finished, bool unlock, List<ModuleTimer> modules
});




}
/// @nodoc
class __$ExamHeartbeatResponseCopyWithImpl<$Res>
    implements _$ExamHeartbeatResponseCopyWith<$Res> {
  __$ExamHeartbeatResponseCopyWithImpl(this._self, this._then);

  final _ExamHeartbeatResponse _self;
  final $Res Function(_ExamHeartbeatResponse) _then;

/// Create a copy of ExamHeartbeatResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverTime = freezed,Object? paused = null,Object? finished = null,Object? unlock = null,Object? modules = null,}) {
  return _then(_ExamHeartbeatResponse(
serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,unlock: null == unlock ? _self.unlock : unlock // ignore: cast_nullable_to_non_nullable
as bool,modules: null == modules ? _self._modules : modules // ignore: cast_nullable_to_non_nullable
as List<ModuleTimer>,
  ));
}


}


/// @nodoc
mixin _$ModuleTimer {

 int get typeId; String get status;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get finishedAt;
/// Create a copy of ModuleTimer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModuleTimerCopyWith<ModuleTimer> get copyWith => _$ModuleTimerCopyWithImpl<ModuleTimer>(this as ModuleTimer, _$identity);

  /// Serializes this ModuleTimer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ModuleTimer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModuleTimer&&(identical(other.typeId, _this.typeId) || other.typeId == _this.typeId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.finishedAt, _this.finishedAt) || other.finishedAt == _this.finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ModuleTimer;
  return Object.hash(runtimeType,_this.typeId,_this.status,_this.finishedAt);
}

@override
String toString() {
  final _this = this as ModuleTimer;
  return 'ModuleTimer(typeId: ${_this.typeId}, status: ${_this.status}, finishedAt: ${_this.finishedAt})';
}


}

/// @nodoc
abstract mixin class $ModuleTimerCopyWith<$Res>  {
  factory $ModuleTimerCopyWith(ModuleTimer value, $Res Function(ModuleTimer) _then) = _$ModuleTimerCopyWithImpl;
@useResult
$Res call({
 int typeId, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt
});




}
/// @nodoc
class _$ModuleTimerCopyWithImpl<$Res>
    implements $ModuleTimerCopyWith<$Res> {
  _$ModuleTimerCopyWithImpl(this._self, this._then);

  final ModuleTimer _self;
  final $Res Function(ModuleTimer) _then;

/// Create a copy of ModuleTimer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? typeId = null,Object? status = null,Object? finishedAt = freezed,}) {
  return _then(ModuleTimer(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModuleTimer].
extension ModuleTimerPatterns on ModuleTimer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModuleTimer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModuleTimer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModuleTimer value)  $default,){
final _that = this;
switch (_that) {
case _ModuleTimer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModuleTimer value)?  $default,){
final _that = this;
switch (_that) {
case _ModuleTimer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModuleTimer() when $default != null:
return $default(_that.typeId,_that.status,_that.finishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt)  $default,) {final _that = this;
switch (_that) {
case _ModuleTimer():
return $default(_that.typeId,_that.status,_that.finishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int typeId,  String status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? finishedAt)?  $default,) {final _that = this;
switch (_that) {
case _ModuleTimer() when $default != null:
return $default(_that.typeId,_that.status,_that.finishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModuleTimer implements ModuleTimer {
  const _ModuleTimer({required this.typeId, required this.status, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.finishedAt});
  factory _ModuleTimer.fromJson(Map<String, dynamic> json) => _$ModuleTimerFromJson(json);

@override final  int typeId;
@override final  String status;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? finishedAt;

/// Create a copy of ModuleTimer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModuleTimerCopyWith<_ModuleTimer> get copyWith => __$ModuleTimerCopyWithImpl<_ModuleTimer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModuleTimerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModuleTimer&&(identical(other.typeId, typeId) || other.typeId == typeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,typeId,status,finishedAt);
}

@override
String toString() {
    return 'ModuleTimer(typeId: $typeId, status: $status, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class _$ModuleTimerCopyWith<$Res> implements $ModuleTimerCopyWith<$Res> {
  factory _$ModuleTimerCopyWith(_ModuleTimer value, $Res Function(_ModuleTimer) _then) = __$ModuleTimerCopyWithImpl;
@override @useResult
$Res call({
 int typeId, String status,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? finishedAt
});




}
/// @nodoc
class __$ModuleTimerCopyWithImpl<$Res>
    implements _$ModuleTimerCopyWith<$Res> {
  __$ModuleTimerCopyWithImpl(this._self, this._then);

  final _ModuleTimer _self;
  final $Res Function(_ModuleTimer) _then;

/// Create a copy of ModuleTimer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? typeId = null,Object? status = null,Object? finishedAt = freezed,}) {
  return _then(_ModuleTimer(
typeId: null == typeId ? _self.typeId : typeId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ViolationItem {

 String get clientUuid; String get type; Map<String, Object?>? get detail;@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) DateTime get occurredAt;
/// Create a copy of ViolationItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ViolationItemCopyWith<ViolationItem> get copyWith => _$ViolationItemCopyWithImpl<ViolationItem>(this as ViolationItem, _$identity);

  /// Serializes this ViolationItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ViolationItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ViolationItem&&(identical(other.clientUuid, _this.clientUuid) || other.clientUuid == _this.clientUuid)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.detail, _this.detail)&&(identical(other.occurredAt, _this.occurredAt) || other.occurredAt == _this.occurredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ViolationItem;
  return Object.hash(runtimeType,_this.clientUuid,_this.type,const DeepCollectionEquality().hash(_this.detail),_this.occurredAt);
}

@override
String toString() {
  final _this = this as ViolationItem;
  return 'ViolationItem(clientUuid: ${_this.clientUuid}, type: ${_this.type}, detail: ${_this.detail}, occurredAt: ${_this.occurredAt})';
}


}

/// @nodoc
abstract mixin class $ViolationItemCopyWith<$Res>  {
  factory $ViolationItemCopyWith(ViolationItem value, $Res Function(ViolationItem) _then) = _$ViolationItemCopyWithImpl;
@useResult
$Res call({
 String clientUuid, String type, Map<String, Object?>? detail,@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) DateTime occurredAt
});




}
/// @nodoc
class _$ViolationItemCopyWithImpl<$Res>
    implements $ViolationItemCopyWith<$Res> {
  _$ViolationItemCopyWithImpl(this._self, this._then);

  final ViolationItem _self;
  final $Res Function(ViolationItem) _then;

/// Create a copy of ViolationItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientUuid = null,Object? type = null,Object? detail = freezed,Object? occurredAt = null,}) {
  return _then(ViolationItem(
clientUuid: null == clientUuid ? _self.clientUuid : clientUuid // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ViolationItem].
extension ViolationItemPatterns on ViolationItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ViolationItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ViolationItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ViolationItem value)  $default,){
final _that = this;
switch (_that) {
case _ViolationItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ViolationItem value)?  $default,){
final _that = this;
switch (_that) {
case _ViolationItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientUuid,  String type,  Map<String, Object?>? detail, @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)  DateTime occurredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ViolationItem() when $default != null:
return $default(_that.clientUuid,_that.type,_that.detail,_that.occurredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientUuid,  String type,  Map<String, Object?>? detail, @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)  DateTime occurredAt)  $default,) {final _that = this;
switch (_that) {
case _ViolationItem():
return $default(_that.clientUuid,_that.type,_that.detail,_that.occurredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientUuid,  String type,  Map<String, Object?>? detail, @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson)  DateTime occurredAt)?  $default,) {final _that = this;
switch (_that) {
case _ViolationItem() when $default != null:
return $default(_that.clientUuid,_that.type,_that.detail,_that.occurredAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ViolationItem implements ViolationItem {
  const _ViolationItem({required this.clientUuid, required this.type,  Map<String, Object?>? detail, @JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) required this.occurredAt}): _detail = detail;
  factory _ViolationItem.fromJson(Map<String, dynamic> json) => _$ViolationItemFromJson(json);

@override final  String clientUuid;
@override final  String type;
 final  Map<String, Object?>? _detail;
@override Map<String, Object?>? get detail {
  final value = _detail;
  if (value == null) return null;
  if (_detail is EqualUnmodifiableMapView) return _detail;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) final  DateTime occurredAt;

/// Create a copy of ViolationItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ViolationItemCopyWith<_ViolationItem> get copyWith => __$ViolationItemCopyWithImpl<_ViolationItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ViolationItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ViolationItem&&(identical(other.clientUuid, clientUuid) || other.clientUuid == clientUuid)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.detail, _detail)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientUuid,type,const DeepCollectionEquality().hash(_detail),occurredAt);
}

@override
String toString() {
    return 'ViolationItem(clientUuid: $clientUuid, type: $type, detail: $detail, occurredAt: $occurredAt)';
}


}

/// @nodoc
abstract mixin class _$ViolationItemCopyWith<$Res> implements $ViolationItemCopyWith<$Res> {
  factory _$ViolationItemCopyWith(_ViolationItem value, $Res Function(_ViolationItem) _then) = __$ViolationItemCopyWithImpl;
@override @useResult
$Res call({
 String clientUuid, String type, Map<String, Object?>? detail,@JsonKey(fromJson: dateRequired, toJson: dateRequiredToJson) DateTime occurredAt
});




}
/// @nodoc
class __$ViolationItemCopyWithImpl<$Res>
    implements _$ViolationItemCopyWith<$Res> {
  __$ViolationItemCopyWithImpl(this._self, this._then);

  final _ViolationItem _self;
  final $Res Function(_ViolationItem) _then;

/// Create a copy of ViolationItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientUuid = null,Object? type = null,Object? detail = freezed,Object? occurredAt = null,}) {
  return _then(_ViolationItem(
clientUuid: null == clientUuid ? _self.clientUuid : clientUuid // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,detail: freezed == detail ? _self._detail : detail // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ViolationsResponse {

 int get accepted;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of ViolationsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ViolationsResponseCopyWith<ViolationsResponse> get copyWith => _$ViolationsResponseCopyWithImpl<ViolationsResponse>(this as ViolationsResponse, _$identity);

  /// Serializes this ViolationsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ViolationsResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ViolationsResponse&&(identical(other.accepted, _this.accepted) || other.accepted == _this.accepted)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ViolationsResponse;
  return Object.hash(runtimeType,_this.accepted,_this.serverTime);
}

@override
String toString() {
  final _this = this as ViolationsResponse;
  return 'ViolationsResponse(accepted: ${_this.accepted}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $ViolationsResponseCopyWith<$Res>  {
  factory $ViolationsResponseCopyWith(ViolationsResponse value, $Res Function(ViolationsResponse) _then) = _$ViolationsResponseCopyWithImpl;
@useResult
$Res call({
 int accepted,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class _$ViolationsResponseCopyWithImpl<$Res>
    implements $ViolationsResponseCopyWith<$Res> {
  _$ViolationsResponseCopyWithImpl(this._self, this._then);

  final ViolationsResponse _self;
  final $Res Function(ViolationsResponse) _then;

/// Create a copy of ViolationsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accepted = null,Object? serverTime = freezed,}) {
  return _then(ViolationsResponse(
accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ViolationsResponse].
extension ViolationsResponsePatterns on ViolationsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ViolationsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ViolationsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ViolationsResponse value)  $default,){
final _that = this;
switch (_that) {
case _ViolationsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ViolationsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ViolationsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int accepted, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ViolationsResponse() when $default != null:
return $default(_that.accepted,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int accepted, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _ViolationsResponse():
return $default(_that.accepted,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int accepted, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _ViolationsResponse() when $default != null:
return $default(_that.accepted,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ViolationsResponse implements ViolationsResponse {
  const _ViolationsResponse({this.accepted = 0, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime});
  factory _ViolationsResponse.fromJson(Map<String, dynamic> json) => _$ViolationsResponseFromJson(json);

@override@JsonKey() final  int accepted;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of ViolationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ViolationsResponseCopyWith<_ViolationsResponse> get copyWith => __$ViolationsResponseCopyWithImpl<_ViolationsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ViolationsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ViolationsResponse&&(identical(other.accepted, accepted) || other.accepted == accepted)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accepted,serverTime);
}

@override
String toString() {
    return 'ViolationsResponse(accepted: $accepted, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$ViolationsResponseCopyWith<$Res> implements $ViolationsResponseCopyWith<$Res> {
  factory _$ViolationsResponseCopyWith(_ViolationsResponse value, $Res Function(_ViolationsResponse) _then) = __$ViolationsResponseCopyWithImpl;
@override @useResult
$Res call({
 int accepted,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});




}
/// @nodoc
class __$ViolationsResponseCopyWithImpl<$Res>
    implements _$ViolationsResponseCopyWith<$Res> {
  __$ViolationsResponseCopyWithImpl(this._self, this._then);

  final _ViolationsResponse _self;
  final $Res Function(_ViolationsResponse) _then;

/// Create a copy of ViolationsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accepted = null,Object? serverTime = freezed,}) {
  return _then(_ViolationsResponse(
accepted: null == accepted ? _self.accepted : accepted // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
