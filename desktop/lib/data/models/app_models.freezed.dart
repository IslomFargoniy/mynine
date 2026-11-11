// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateManifest {

@JsonKey(fromJson: stringOrEmpty) String get version;@JsonKey(fromJson: stringOrEmpty) String get file;@JsonKey(fromJson: stringOrEmpty) String get sha256;@JsonKey(fromJson: intFrom) int get size;@JsonKey(fromJson: boolTrue) bool get mandatory;@JsonKey(fromJson: stringOrNull) String? get minVersion;@JsonKey(fromJson: stringOrEmpty) String get notes;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get publishedAt;
/// Create a copy of UpdateManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateManifestCopyWith<UpdateManifest> get copyWith => _$UpdateManifestCopyWithImpl<UpdateManifest>(this as UpdateManifest, _$identity);

  /// Serializes this UpdateManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateManifest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateManifest&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.file, _this.file) || other.file == _this.file)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.mandatory, _this.mandatory) || other.mandatory == _this.mandatory)&&(identical(other.minVersion, _this.minVersion) || other.minVersion == _this.minVersion)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateManifest;
  return Object.hash(runtimeType,_this.version,_this.file,_this.sha256,_this.size,_this.mandatory,_this.minVersion,_this.notes,_this.publishedAt);
}

@override
String toString() {
  final _this = this as UpdateManifest;
  return 'UpdateManifest(version: ${_this.version}, file: ${_this.file}, sha256: ${_this.sha256}, size: ${_this.size}, mandatory: ${_this.mandatory}, minVersion: ${_this.minVersion}, notes: ${_this.notes}, publishedAt: ${_this.publishedAt})';
}


}

/// @nodoc
abstract mixin class $UpdateManifestCopyWith<$Res>  {
  factory $UpdateManifestCopyWith(UpdateManifest value, $Res Function(UpdateManifest) _then) = _$UpdateManifestCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: stringOrEmpty) String version,@JsonKey(fromJson: stringOrEmpty) String file,@JsonKey(fromJson: stringOrEmpty) String sha256,@JsonKey(fromJson: intFrom) int size,@JsonKey(fromJson: boolTrue) bool mandatory,@JsonKey(fromJson: stringOrNull) String? minVersion,@JsonKey(fromJson: stringOrEmpty) String notes,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? publishedAt
});




}
/// @nodoc
class _$UpdateManifestCopyWithImpl<$Res>
    implements $UpdateManifestCopyWith<$Res> {
  _$UpdateManifestCopyWithImpl(this._self, this._then);

  final UpdateManifest _self;
  final $Res Function(UpdateManifest) _then;

/// Create a copy of UpdateManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? file = null,Object? sha256 = null,Object? size = null,Object? mandatory = null,Object? minVersion = freezed,Object? notes = null,Object? publishedAt = freezed,}) {
  return _then(UpdateManifest(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mandatory: null == mandatory ? _self.mandatory : mandatory // ignore: cast_nullable_to_non_nullable
as bool,minVersion: freezed == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateManifest].
extension UpdateManifestPatterns on UpdateManifest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateManifest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateManifest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateManifest value)  $default,){
final _that = this;
switch (_that) {
case _UpdateManifest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateManifest value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateManifest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringOrEmpty)  String version, @JsonKey(fromJson: stringOrEmpty)  String file, @JsonKey(fromJson: stringOrEmpty)  String sha256, @JsonKey(fromJson: intFrom)  int size, @JsonKey(fromJson: boolTrue)  bool mandatory, @JsonKey(fromJson: stringOrNull)  String? minVersion, @JsonKey(fromJson: stringOrEmpty)  String notes, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateManifest() when $default != null:
return $default(_that.version,_that.file,_that.sha256,_that.size,_that.mandatory,_that.minVersion,_that.notes,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringOrEmpty)  String version, @JsonKey(fromJson: stringOrEmpty)  String file, @JsonKey(fromJson: stringOrEmpty)  String sha256, @JsonKey(fromJson: intFrom)  int size, @JsonKey(fromJson: boolTrue)  bool mandatory, @JsonKey(fromJson: stringOrNull)  String? minVersion, @JsonKey(fromJson: stringOrEmpty)  String notes, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? publishedAt)  $default,) {final _that = this;
switch (_that) {
case _UpdateManifest():
return $default(_that.version,_that.file,_that.sha256,_that.size,_that.mandatory,_that.minVersion,_that.notes,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: stringOrEmpty)  String version, @JsonKey(fromJson: stringOrEmpty)  String file, @JsonKey(fromJson: stringOrEmpty)  String sha256, @JsonKey(fromJson: intFrom)  int size, @JsonKey(fromJson: boolTrue)  bool mandatory, @JsonKey(fromJson: stringOrNull)  String? minVersion, @JsonKey(fromJson: stringOrEmpty)  String notes, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _UpdateManifest() when $default != null:
return $default(_that.version,_that.file,_that.sha256,_that.size,_that.mandatory,_that.minVersion,_that.notes,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateManifest extends UpdateManifest {
  const _UpdateManifest({@JsonKey(fromJson: stringOrEmpty) this.version = '', @JsonKey(fromJson: stringOrEmpty) this.file = '', @JsonKey(fromJson: stringOrEmpty) this.sha256 = '', @JsonKey(fromJson: intFrom) this.size = 0, @JsonKey(fromJson: boolTrue) this.mandatory = false, @JsonKey(fromJson: stringOrNull) this.minVersion, @JsonKey(fromJson: stringOrEmpty) this.notes = '', @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.publishedAt}): super._();
  factory _UpdateManifest.fromJson(Map<String, dynamic> json) => _$UpdateManifestFromJson(json);

@override@JsonKey(fromJson: stringOrEmpty) final  String version;
@override@JsonKey(fromJson: stringOrEmpty) final  String file;
@override@JsonKey(fromJson: stringOrEmpty) final  String sha256;
@override@JsonKey(fromJson: intFrom) final  int size;
@override@JsonKey(fromJson: boolTrue) final  bool mandatory;
@override@JsonKey(fromJson: stringOrNull) final  String? minVersion;
@override@JsonKey(fromJson: stringOrEmpty) final  String notes;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? publishedAt;

/// Create a copy of UpdateManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateManifestCopyWith<_UpdateManifest> get copyWith => __$UpdateManifestCopyWithImpl<_UpdateManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateManifestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateManifest&&(identical(other.version, version) || other.version == version)&&(identical(other.file, file) || other.file == file)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.size, size) || other.size == size)&&(identical(other.mandatory, mandatory) || other.mandatory == mandatory)&&(identical(other.minVersion, minVersion) || other.minVersion == minVersion)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,version,file,sha256,size,mandatory,minVersion,notes,publishedAt);
}

@override
String toString() {
    return 'UpdateManifest(version: $version, file: $file, sha256: $sha256, size: $size, mandatory: $mandatory, minVersion: $minVersion, notes: $notes, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$UpdateManifestCopyWith<$Res> implements $UpdateManifestCopyWith<$Res> {
  factory _$UpdateManifestCopyWith(_UpdateManifest value, $Res Function(_UpdateManifest) _then) = __$UpdateManifestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: stringOrEmpty) String version,@JsonKey(fromJson: stringOrEmpty) String file,@JsonKey(fromJson: stringOrEmpty) String sha256,@JsonKey(fromJson: intFrom) int size,@JsonKey(fromJson: boolTrue) bool mandatory,@JsonKey(fromJson: stringOrNull) String? minVersion,@JsonKey(fromJson: stringOrEmpty) String notes,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? publishedAt
});




}
/// @nodoc
class __$UpdateManifestCopyWithImpl<$Res>
    implements _$UpdateManifestCopyWith<$Res> {
  __$UpdateManifestCopyWithImpl(this._self, this._then);

  final _UpdateManifest _self;
  final $Res Function(_UpdateManifest) _then;

/// Create a copy of UpdateManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? file = null,Object? sha256 = null,Object? size = null,Object? mandatory = null,Object? minVersion = freezed,Object? notes = null,Object? publishedAt = freezed,}) {
  return _then(_UpdateManifest(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mandatory: null == mandatory ? _self.mandatory : mandatory // ignore: cast_nullable_to_non_nullable
as bool,minVersion: freezed == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$DeviceRegistration {

 int get deviceId; String get deviceToken; String get name;@JsonKey(fromJson: intOrNull) int? get number;@JsonKey(fromJson: boolTrue) bool get approved;@JsonKey(fromJson: stringOrNull) String? get exitPasswordOffline;
/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceRegistrationCopyWith<DeviceRegistration> get copyWith => _$DeviceRegistrationCopyWithImpl<DeviceRegistration>(this as DeviceRegistration, _$identity);

  /// Serializes this DeviceRegistration to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeviceRegistration;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceRegistration&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.deviceToken, _this.deviceToken) || other.deviceToken == _this.deviceToken)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.approved, _this.approved) || other.approved == _this.approved)&&(identical(other.exitPasswordOffline, _this.exitPasswordOffline) || other.exitPasswordOffline == _this.exitPasswordOffline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceRegistration;
  return Object.hash(runtimeType,_this.deviceId,_this.deviceToken,_this.name,_this.number,_this.approved,_this.exitPasswordOffline);
}

@override
String toString() {
  final _this = this as DeviceRegistration;
  return 'DeviceRegistration(deviceId: ${_this.deviceId}, deviceToken: ${_this.deviceToken}, name: ${_this.name}, number: ${_this.number}, approved: ${_this.approved}, exitPasswordOffline: ${_this.exitPasswordOffline})';
}


}

/// @nodoc
abstract mixin class $DeviceRegistrationCopyWith<$Res>  {
  factory $DeviceRegistrationCopyWith(DeviceRegistration value, $Res Function(DeviceRegistration) _then) = _$DeviceRegistrationCopyWithImpl;
@useResult
$Res call({
 int deviceId, String deviceToken, String name,@JsonKey(fromJson: intOrNull) int? number,@JsonKey(fromJson: boolTrue) bool approved,@JsonKey(fromJson: stringOrNull) String? exitPasswordOffline
});




}
/// @nodoc
class _$DeviceRegistrationCopyWithImpl<$Res>
    implements $DeviceRegistrationCopyWith<$Res> {
  _$DeviceRegistrationCopyWithImpl(this._self, this._then);

  final DeviceRegistration _self;
  final $Res Function(DeviceRegistration) _then;

/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceToken = null,Object? name = null,Object? number = freezed,Object? approved = null,Object? exitPasswordOffline = freezed,}) {
  return _then(DeviceRegistration(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as int,deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,exitPasswordOffline: freezed == exitPasswordOffline ? _self.exitPasswordOffline : exitPasswordOffline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceRegistration].
extension DeviceRegistrationPatterns on DeviceRegistration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceRegistration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceRegistration value)  $default,){
final _that = this;
switch (_that) {
case _DeviceRegistration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceRegistration value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int deviceId,  String deviceToken,  String name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolTrue)  bool approved, @JsonKey(fromJson: stringOrNull)  String? exitPasswordOffline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
return $default(_that.deviceId,_that.deviceToken,_that.name,_that.number,_that.approved,_that.exitPasswordOffline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int deviceId,  String deviceToken,  String name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolTrue)  bool approved, @JsonKey(fromJson: stringOrNull)  String? exitPasswordOffline)  $default,) {final _that = this;
switch (_that) {
case _DeviceRegistration():
return $default(_that.deviceId,_that.deviceToken,_that.name,_that.number,_that.approved,_that.exitPasswordOffline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int deviceId,  String deviceToken,  String name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolTrue)  bool approved, @JsonKey(fromJson: stringOrNull)  String? exitPasswordOffline)?  $default,) {final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
return $default(_that.deviceId,_that.deviceToken,_that.name,_that.number,_that.approved,_that.exitPasswordOffline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceRegistration implements DeviceRegistration {
  const _DeviceRegistration({required this.deviceId, required this.deviceToken, required this.name, @JsonKey(fromJson: intOrNull) this.number, @JsonKey(fromJson: boolTrue) this.approved = false, @JsonKey(fromJson: stringOrNull) this.exitPasswordOffline});
  factory _DeviceRegistration.fromJson(Map<String, dynamic> json) => _$DeviceRegistrationFromJson(json);

@override final  int deviceId;
@override final  String deviceToken;
@override final  String name;
@override@JsonKey(fromJson: intOrNull) final  int? number;
@override@JsonKey(fromJson: boolTrue) final  bool approved;
@override@JsonKey(fromJson: stringOrNull) final  String? exitPasswordOffline;

/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceRegistrationCopyWith<_DeviceRegistration> get copyWith => __$DeviceRegistrationCopyWithImpl<_DeviceRegistration>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceRegistrationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceRegistration&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken)&&(identical(other.name, name) || other.name == name)&&(identical(other.number, number) || other.number == number)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.exitPasswordOffline, exitPasswordOffline) || other.exitPasswordOffline == exitPasswordOffline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,deviceId,deviceToken,name,number,approved,exitPasswordOffline);
}

@override
String toString() {
    return 'DeviceRegistration(deviceId: $deviceId, deviceToken: $deviceToken, name: $name, number: $number, approved: $approved, exitPasswordOffline: $exitPasswordOffline)';
}


}

/// @nodoc
abstract mixin class _$DeviceRegistrationCopyWith<$Res> implements $DeviceRegistrationCopyWith<$Res> {
  factory _$DeviceRegistrationCopyWith(_DeviceRegistration value, $Res Function(_DeviceRegistration) _then) = __$DeviceRegistrationCopyWithImpl;
@override @useResult
$Res call({
 int deviceId, String deviceToken, String name,@JsonKey(fromJson: intOrNull) int? number,@JsonKey(fromJson: boolTrue) bool approved,@JsonKey(fromJson: stringOrNull) String? exitPasswordOffline
});




}
/// @nodoc
class __$DeviceRegistrationCopyWithImpl<$Res>
    implements _$DeviceRegistrationCopyWith<$Res> {
  __$DeviceRegistrationCopyWithImpl(this._self, this._then);

  final _DeviceRegistration _self;
  final $Res Function(_DeviceRegistration) _then;

/// Create a copy of DeviceRegistration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceToken = null,Object? name = null,Object? number = freezed,Object? approved = null,Object? exitPasswordOffline = freezed,}) {
  return _then(_DeviceRegistration(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as int,deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,exitPasswordOffline: freezed == exitPasswordOffline ? _self.exitPasswordOffline : exitPasswordOffline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DeviceHeartbeat {

@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime; bool get unlock;@JsonKey(fromJson: stringOrNull) String? get name;@JsonKey(fromJson: intOrNull) int? get number;@JsonKey(fromJson: boolOrNull) bool? get approved;
/// Create a copy of DeviceHeartbeat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceHeartbeatCopyWith<DeviceHeartbeat> get copyWith => _$DeviceHeartbeatCopyWithImpl<DeviceHeartbeat>(this as DeviceHeartbeat, _$identity);

  /// Serializes this DeviceHeartbeat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeviceHeartbeat;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceHeartbeat&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.unlock, _this.unlock) || other.unlock == _this.unlock)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.approved, _this.approved) || other.approved == _this.approved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceHeartbeat;
  return Object.hash(runtimeType,_this.serverTime,_this.unlock,_this.name,_this.number,_this.approved);
}

@override
String toString() {
  final _this = this as DeviceHeartbeat;
  return 'DeviceHeartbeat(serverTime: ${_this.serverTime}, unlock: ${_this.unlock}, name: ${_this.name}, number: ${_this.number}, approved: ${_this.approved})';
}


}

/// @nodoc
abstract mixin class $DeviceHeartbeatCopyWith<$Res>  {
  factory $DeviceHeartbeatCopyWith(DeviceHeartbeat value, $Res Function(DeviceHeartbeat) _then) = _$DeviceHeartbeatCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime, bool unlock,@JsonKey(fromJson: stringOrNull) String? name,@JsonKey(fromJson: intOrNull) int? number,@JsonKey(fromJson: boolOrNull) bool? approved
});




}
/// @nodoc
class _$DeviceHeartbeatCopyWithImpl<$Res>
    implements $DeviceHeartbeatCopyWith<$Res> {
  _$DeviceHeartbeatCopyWithImpl(this._self, this._then);

  final DeviceHeartbeat _self;
  final $Res Function(DeviceHeartbeat) _then;

/// Create a copy of DeviceHeartbeat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverTime = freezed,Object? unlock = null,Object? name = freezed,Object? number = freezed,Object? approved = freezed,}) {
  return _then(DeviceHeartbeat(
serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,unlock: null == unlock ? _self.unlock : unlock // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,approved: freezed == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceHeartbeat].
extension DeviceHeartbeatPatterns on DeviceHeartbeat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceHeartbeat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceHeartbeat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceHeartbeat value)  $default,){
final _that = this;
switch (_that) {
case _DeviceHeartbeat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceHeartbeat value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceHeartbeat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool unlock, @JsonKey(fromJson: stringOrNull)  String? name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolOrNull)  bool? approved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceHeartbeat() when $default != null:
return $default(_that.serverTime,_that.unlock,_that.name,_that.number,_that.approved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool unlock, @JsonKey(fromJson: stringOrNull)  String? name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolOrNull)  bool? approved)  $default,) {final _that = this;
switch (_that) {
case _DeviceHeartbeat():
return $default(_that.serverTime,_that.unlock,_that.name,_that.number,_that.approved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool unlock, @JsonKey(fromJson: stringOrNull)  String? name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolOrNull)  bool? approved)?  $default,) {final _that = this;
switch (_that) {
case _DeviceHeartbeat() when $default != null:
return $default(_that.serverTime,_that.unlock,_that.name,_that.number,_that.approved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceHeartbeat implements DeviceHeartbeat {
  const _DeviceHeartbeat({@JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime, this.unlock = false, @JsonKey(fromJson: stringOrNull) this.name, @JsonKey(fromJson: intOrNull) this.number, @JsonKey(fromJson: boolOrNull) this.approved});
  factory _DeviceHeartbeat.fromJson(Map<String, dynamic> json) => _$DeviceHeartbeatFromJson(json);

@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;
@override@JsonKey() final  bool unlock;
@override@JsonKey(fromJson: stringOrNull) final  String? name;
@override@JsonKey(fromJson: intOrNull) final  int? number;
@override@JsonKey(fromJson: boolOrNull) final  bool? approved;

/// Create a copy of DeviceHeartbeat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceHeartbeatCopyWith<_DeviceHeartbeat> get copyWith => __$DeviceHeartbeatCopyWithImpl<_DeviceHeartbeat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceHeartbeatToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceHeartbeat&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.unlock, unlock) || other.unlock == unlock)&&(identical(other.name, name) || other.name == name)&&(identical(other.number, number) || other.number == number)&&(identical(other.approved, approved) || other.approved == approved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,serverTime,unlock,name,number,approved);
}

@override
String toString() {
    return 'DeviceHeartbeat(serverTime: $serverTime, unlock: $unlock, name: $name, number: $number, approved: $approved)';
}


}

/// @nodoc
abstract mixin class _$DeviceHeartbeatCopyWith<$Res> implements $DeviceHeartbeatCopyWith<$Res> {
  factory _$DeviceHeartbeatCopyWith(_DeviceHeartbeat value, $Res Function(_DeviceHeartbeat) _then) = __$DeviceHeartbeatCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime, bool unlock,@JsonKey(fromJson: stringOrNull) String? name,@JsonKey(fromJson: intOrNull) int? number,@JsonKey(fromJson: boolOrNull) bool? approved
});




}
/// @nodoc
class __$DeviceHeartbeatCopyWithImpl<$Res>
    implements _$DeviceHeartbeatCopyWith<$Res> {
  __$DeviceHeartbeatCopyWithImpl(this._self, this._then);

  final _DeviceHeartbeat _self;
  final $Res Function(_DeviceHeartbeat) _then;

/// Create a copy of DeviceHeartbeat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverTime = freezed,Object? unlock = null,Object? name = freezed,Object? number = freezed,Object? approved = freezed,}) {
  return _then(_DeviceHeartbeat(
serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,unlock: null == unlock ? _self.unlock : unlock // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,approved: freezed == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$DeviceConfig {

 String? get exitPasswordOffline; List<String> get bannedProcesses; int get heartbeatSeconds; int get violationBatchSeconds;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;@JsonKey(fromJson: stringOrNull) String? get name;@JsonKey(fromJson: intOrNull) int? get number;@JsonKey(fromJson: boolOrNull) bool? get approved;@JsonKey(fromJson: stringOrNull) String? get backgroundUrl;@JsonKey(fromJson: stringOrNull) String? get backgroundSha256;
/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceConfigCopyWith<DeviceConfig> get copyWith => _$DeviceConfigCopyWithImpl<DeviceConfig>(this as DeviceConfig, _$identity);

  /// Serializes this DeviceConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeviceConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceConfig&&(identical(other.exitPasswordOffline, _this.exitPasswordOffline) || other.exitPasswordOffline == _this.exitPasswordOffline)&&const DeepCollectionEquality().equals(other.bannedProcesses, _this.bannedProcesses)&&(identical(other.heartbeatSeconds, _this.heartbeatSeconds) || other.heartbeatSeconds == _this.heartbeatSeconds)&&(identical(other.violationBatchSeconds, _this.violationBatchSeconds) || other.violationBatchSeconds == _this.violationBatchSeconds)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.number, _this.number) || other.number == _this.number)&&(identical(other.approved, _this.approved) || other.approved == _this.approved)&&(identical(other.backgroundUrl, _this.backgroundUrl) || other.backgroundUrl == _this.backgroundUrl)&&(identical(other.backgroundSha256, _this.backgroundSha256) || other.backgroundSha256 == _this.backgroundSha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceConfig;
  return Object.hash(runtimeType,_this.exitPasswordOffline,const DeepCollectionEquality().hash(_this.bannedProcesses),_this.heartbeatSeconds,_this.violationBatchSeconds,_this.serverTime,_this.name,_this.number,_this.approved,_this.backgroundUrl,_this.backgroundSha256);
}

@override
String toString() {
  final _this = this as DeviceConfig;
  return 'DeviceConfig(exitPasswordOffline: ${_this.exitPasswordOffline}, bannedProcesses: ${_this.bannedProcesses}, heartbeatSeconds: ${_this.heartbeatSeconds}, violationBatchSeconds: ${_this.violationBatchSeconds}, serverTime: ${_this.serverTime}, name: ${_this.name}, number: ${_this.number}, approved: ${_this.approved}, backgroundUrl: ${_this.backgroundUrl}, backgroundSha256: ${_this.backgroundSha256})';
}


}

/// @nodoc
abstract mixin class $DeviceConfigCopyWith<$Res>  {
  factory $DeviceConfigCopyWith(DeviceConfig value, $Res Function(DeviceConfig) _then) = _$DeviceConfigCopyWithImpl;
@useResult
$Res call({
 String? exitPasswordOffline, List<String> bannedProcesses, int heartbeatSeconds, int violationBatchSeconds,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,@JsonKey(fromJson: stringOrNull) String? name,@JsonKey(fromJson: intOrNull) int? number,@JsonKey(fromJson: boolOrNull) bool? approved,@JsonKey(fromJson: stringOrNull) String? backgroundUrl,@JsonKey(fromJson: stringOrNull) String? backgroundSha256
});




}
/// @nodoc
class _$DeviceConfigCopyWithImpl<$Res>
    implements $DeviceConfigCopyWith<$Res> {
  _$DeviceConfigCopyWithImpl(this._self, this._then);

  final DeviceConfig _self;
  final $Res Function(DeviceConfig) _then;

/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exitPasswordOffline = freezed,Object? bannedProcesses = null,Object? heartbeatSeconds = null,Object? violationBatchSeconds = null,Object? serverTime = freezed,Object? name = freezed,Object? number = freezed,Object? approved = freezed,Object? backgroundUrl = freezed,Object? backgroundSha256 = freezed,}) {
  return _then(DeviceConfig(
exitPasswordOffline: freezed == exitPasswordOffline ? _self.exitPasswordOffline : exitPasswordOffline // ignore: cast_nullable_to_non_nullable
as String?,bannedProcesses: null == bannedProcesses ? _self.bannedProcesses : bannedProcesses // ignore: cast_nullable_to_non_nullable
as List<String>,heartbeatSeconds: null == heartbeatSeconds ? _self.heartbeatSeconds : heartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,violationBatchSeconds: null == violationBatchSeconds ? _self.violationBatchSeconds : violationBatchSeconds // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,approved: freezed == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool?,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,backgroundSha256: freezed == backgroundSha256 ? _self.backgroundSha256 : backgroundSha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceConfig].
extension DeviceConfigPatterns on DeviceConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceConfig value)  $default,){
final _that = this;
switch (_that) {
case _DeviceConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceConfig value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? exitPasswordOffline,  List<String> bannedProcesses,  int heartbeatSeconds,  int violationBatchSeconds, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime, @JsonKey(fromJson: stringOrNull)  String? name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolOrNull)  bool? approved, @JsonKey(fromJson: stringOrNull)  String? backgroundUrl, @JsonKey(fromJson: stringOrNull)  String? backgroundSha256)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that.exitPasswordOffline,_that.bannedProcesses,_that.heartbeatSeconds,_that.violationBatchSeconds,_that.serverTime,_that.name,_that.number,_that.approved,_that.backgroundUrl,_that.backgroundSha256);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? exitPasswordOffline,  List<String> bannedProcesses,  int heartbeatSeconds,  int violationBatchSeconds, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime, @JsonKey(fromJson: stringOrNull)  String? name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolOrNull)  bool? approved, @JsonKey(fromJson: stringOrNull)  String? backgroundUrl, @JsonKey(fromJson: stringOrNull)  String? backgroundSha256)  $default,) {final _that = this;
switch (_that) {
case _DeviceConfig():
return $default(_that.exitPasswordOffline,_that.bannedProcesses,_that.heartbeatSeconds,_that.violationBatchSeconds,_that.serverTime,_that.name,_that.number,_that.approved,_that.backgroundUrl,_that.backgroundSha256);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? exitPasswordOffline,  List<String> bannedProcesses,  int heartbeatSeconds,  int violationBatchSeconds, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime, @JsonKey(fromJson: stringOrNull)  String? name, @JsonKey(fromJson: intOrNull)  int? number, @JsonKey(fromJson: boolOrNull)  bool? approved, @JsonKey(fromJson: stringOrNull)  String? backgroundUrl, @JsonKey(fromJson: stringOrNull)  String? backgroundSha256)?  $default,) {final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that.exitPasswordOffline,_that.bannedProcesses,_that.heartbeatSeconds,_that.violationBatchSeconds,_that.serverTime,_that.name,_that.number,_that.approved,_that.backgroundUrl,_that.backgroundSha256);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceConfig implements DeviceConfig {
  const _DeviceConfig({this.exitPasswordOffline,  List<String> bannedProcesses = const <String>[], this.heartbeatSeconds = 20, this.violationBatchSeconds = 10, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime, @JsonKey(fromJson: stringOrNull) this.name, @JsonKey(fromJson: intOrNull) this.number, @JsonKey(fromJson: boolOrNull) this.approved, @JsonKey(fromJson: stringOrNull) this.backgroundUrl, @JsonKey(fromJson: stringOrNull) this.backgroundSha256}): _bannedProcesses = bannedProcesses;
  factory _DeviceConfig.fromJson(Map<String, dynamic> json) => _$DeviceConfigFromJson(json);

@override final  String? exitPasswordOffline;
 final  List<String> _bannedProcesses;
@override@JsonKey() List<String> get bannedProcesses {
  if (_bannedProcesses is EqualUnmodifiableListView) return _bannedProcesses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bannedProcesses);
}

@override@JsonKey() final  int heartbeatSeconds;
@override@JsonKey() final  int violationBatchSeconds;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;
@override@JsonKey(fromJson: stringOrNull) final  String? name;
@override@JsonKey(fromJson: intOrNull) final  int? number;
@override@JsonKey(fromJson: boolOrNull) final  bool? approved;
@override@JsonKey(fromJson: stringOrNull) final  String? backgroundUrl;
@override@JsonKey(fromJson: stringOrNull) final  String? backgroundSha256;

/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceConfigCopyWith<_DeviceConfig> get copyWith => __$DeviceConfigCopyWithImpl<_DeviceConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceConfig&&(identical(other.exitPasswordOffline, exitPasswordOffline) || other.exitPasswordOffline == exitPasswordOffline)&&const DeepCollectionEquality().equals(other.bannedProcesses, _bannedProcesses)&&(identical(other.heartbeatSeconds, heartbeatSeconds) || other.heartbeatSeconds == heartbeatSeconds)&&(identical(other.violationBatchSeconds, violationBatchSeconds) || other.violationBatchSeconds == violationBatchSeconds)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.name, name) || other.name == name)&&(identical(other.number, number) || other.number == number)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.backgroundUrl, backgroundUrl) || other.backgroundUrl == backgroundUrl)&&(identical(other.backgroundSha256, backgroundSha256) || other.backgroundSha256 == backgroundSha256));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,exitPasswordOffline,const DeepCollectionEquality().hash(_bannedProcesses),heartbeatSeconds,violationBatchSeconds,serverTime,name,number,approved,backgroundUrl,backgroundSha256);
}

@override
String toString() {
    return 'DeviceConfig(exitPasswordOffline: $exitPasswordOffline, bannedProcesses: $bannedProcesses, heartbeatSeconds: $heartbeatSeconds, violationBatchSeconds: $violationBatchSeconds, serverTime: $serverTime, name: $name, number: $number, approved: $approved, backgroundUrl: $backgroundUrl, backgroundSha256: $backgroundSha256)';
}


}

/// @nodoc
abstract mixin class _$DeviceConfigCopyWith<$Res> implements $DeviceConfigCopyWith<$Res> {
  factory _$DeviceConfigCopyWith(_DeviceConfig value, $Res Function(_DeviceConfig) _then) = __$DeviceConfigCopyWithImpl;
@override @useResult
$Res call({
 String? exitPasswordOffline, List<String> bannedProcesses, int heartbeatSeconds, int violationBatchSeconds,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime,@JsonKey(fromJson: stringOrNull) String? name,@JsonKey(fromJson: intOrNull) int? number,@JsonKey(fromJson: boolOrNull) bool? approved,@JsonKey(fromJson: stringOrNull) String? backgroundUrl,@JsonKey(fromJson: stringOrNull) String? backgroundSha256
});




}
/// @nodoc
class __$DeviceConfigCopyWithImpl<$Res>
    implements _$DeviceConfigCopyWith<$Res> {
  __$DeviceConfigCopyWithImpl(this._self, this._then);

  final _DeviceConfig _self;
  final $Res Function(_DeviceConfig) _then;

/// Create a copy of DeviceConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exitPasswordOffline = freezed,Object? bannedProcesses = null,Object? heartbeatSeconds = null,Object? violationBatchSeconds = null,Object? serverTime = freezed,Object? name = freezed,Object? number = freezed,Object? approved = freezed,Object? backgroundUrl = freezed,Object? backgroundSha256 = freezed,}) {
  return _then(_DeviceConfig(
exitPasswordOffline: freezed == exitPasswordOffline ? _self.exitPasswordOffline : exitPasswordOffline // ignore: cast_nullable_to_non_nullable
as String?,bannedProcesses: null == bannedProcesses ? _self._bannedProcesses : bannedProcesses // ignore: cast_nullable_to_non_nullable
as List<String>,heartbeatSeconds: null == heartbeatSeconds ? _self.heartbeatSeconds : heartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,violationBatchSeconds: null == violationBatchSeconds ? _self.violationBatchSeconds : violationBatchSeconds // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int?,approved: freezed == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool?,backgroundUrl: freezed == backgroundUrl ? _self.backgroundUrl : backgroundUrl // ignore: cast_nullable_to_non_nullable
as String?,backgroundSha256: freezed == backgroundSha256 ? _self.backgroundSha256 : backgroundSha256 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
