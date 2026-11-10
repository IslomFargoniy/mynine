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
mixin _$AppVersionInfo {

 ReleaseInfo? get latest; String? get minVersion; bool get updateAvailable;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
/// Create a copy of AppVersionInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppVersionInfoCopyWith<AppVersionInfo> get copyWith => _$AppVersionInfoCopyWithImpl<AppVersionInfo>(this as AppVersionInfo, _$identity);

  /// Serializes this AppVersionInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppVersionInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppVersionInfo&&(identical(other.latest, _this.latest) || other.latest == _this.latest)&&(identical(other.minVersion, _this.minVersion) || other.minVersion == _this.minVersion)&&(identical(other.updateAvailable, _this.updateAvailable) || other.updateAvailable == _this.updateAvailable)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppVersionInfo;
  return Object.hash(runtimeType,_this.latest,_this.minVersion,_this.updateAvailable,_this.serverTime);
}

@override
String toString() {
  final _this = this as AppVersionInfo;
  return 'AppVersionInfo(latest: ${_this.latest}, minVersion: ${_this.minVersion}, updateAvailable: ${_this.updateAvailable}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $AppVersionInfoCopyWith<$Res>  {
  factory $AppVersionInfoCopyWith(AppVersionInfo value, $Res Function(AppVersionInfo) _then) = _$AppVersionInfoCopyWithImpl;
@useResult
$Res call({
 ReleaseInfo? latest, String? minVersion, bool updateAvailable,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});


$ReleaseInfoCopyWith<$Res>? get latest;

}
/// @nodoc
class _$AppVersionInfoCopyWithImpl<$Res>
    implements $AppVersionInfoCopyWith<$Res> {
  _$AppVersionInfoCopyWithImpl(this._self, this._then);

  final AppVersionInfo _self;
  final $Res Function(AppVersionInfo) _then;

/// Create a copy of AppVersionInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latest = freezed,Object? minVersion = freezed,Object? updateAvailable = null,Object? serverTime = freezed,}) {
  return _then(AppVersionInfo(
latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as ReleaseInfo?,minVersion: freezed == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String?,updateAvailable: null == updateAvailable ? _self.updateAvailable : updateAvailable // ignore: cast_nullable_to_non_nullable
as bool,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of AppVersionInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReleaseInfoCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $ReleaseInfoCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppVersionInfo].
extension AppVersionInfoPatterns on AppVersionInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppVersionInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppVersionInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppVersionInfo value)  $default,){
final _that = this;
switch (_that) {
case _AppVersionInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppVersionInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AppVersionInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReleaseInfo? latest,  String? minVersion,  bool updateAvailable, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppVersionInfo() when $default != null:
return $default(_that.latest,_that.minVersion,_that.updateAvailable,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReleaseInfo? latest,  String? minVersion,  bool updateAvailable, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _AppVersionInfo():
return $default(_that.latest,_that.minVersion,_that.updateAvailable,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReleaseInfo? latest,  String? minVersion,  bool updateAvailable, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _AppVersionInfo() when $default != null:
return $default(_that.latest,_that.minVersion,_that.updateAvailable,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppVersionInfo implements AppVersionInfo {
  const _AppVersionInfo({this.latest, this.minVersion, this.updateAvailable = false, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime});
  factory _AppVersionInfo.fromJson(Map<String, dynamic> json) => _$AppVersionInfoFromJson(json);

@override final  ReleaseInfo? latest;
@override final  String? minVersion;
@override@JsonKey() final  bool updateAvailable;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;

/// Create a copy of AppVersionInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppVersionInfoCopyWith<_AppVersionInfo> get copyWith => __$AppVersionInfoCopyWithImpl<_AppVersionInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppVersionInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppVersionInfo&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.minVersion, minVersion) || other.minVersion == minVersion)&&(identical(other.updateAvailable, updateAvailable) || other.updateAvailable == updateAvailable)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,latest,minVersion,updateAvailable,serverTime);
}

@override
String toString() {
    return 'AppVersionInfo(latest: $latest, minVersion: $minVersion, updateAvailable: $updateAvailable, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$AppVersionInfoCopyWith<$Res> implements $AppVersionInfoCopyWith<$Res> {
  factory _$AppVersionInfoCopyWith(_AppVersionInfo value, $Res Function(_AppVersionInfo) _then) = __$AppVersionInfoCopyWithImpl;
@override @useResult
$Res call({
 ReleaseInfo? latest, String? minVersion, bool updateAvailable,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
});


@override $ReleaseInfoCopyWith<$Res>? get latest;

}
/// @nodoc
class __$AppVersionInfoCopyWithImpl<$Res>
    implements _$AppVersionInfoCopyWith<$Res> {
  __$AppVersionInfoCopyWithImpl(this._self, this._then);

  final _AppVersionInfo _self;
  final $Res Function(_AppVersionInfo) _then;

/// Create a copy of AppVersionInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latest = freezed,Object? minVersion = freezed,Object? updateAvailable = null,Object? serverTime = freezed,}) {
  return _then(_AppVersionInfo(
latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as ReleaseInfo?,minVersion: freezed == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String?,updateAvailable: null == updateAvailable ? _self.updateAvailable : updateAvailable // ignore: cast_nullable_to_non_nullable
as bool,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of AppVersionInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReleaseInfoCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $ReleaseInfoCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}
}


/// @nodoc
mixin _$ReleaseInfo {

 String get version; String get notes; bool get mandatory; String get url; String get sha256; int get size;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get publishedAt;
/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseInfoCopyWith<ReleaseInfo> get copyWith => _$ReleaseInfoCopyWithImpl<ReleaseInfo>(this as ReleaseInfo, _$identity);

  /// Serializes this ReleaseInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReleaseInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseInfo&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.mandatory, _this.mandatory) || other.mandatory == _this.mandatory)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.publishedAt, _this.publishedAt) || other.publishedAt == _this.publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReleaseInfo;
  return Object.hash(runtimeType,_this.version,_this.notes,_this.mandatory,_this.url,_this.sha256,_this.size,_this.publishedAt);
}

@override
String toString() {
  final _this = this as ReleaseInfo;
  return 'ReleaseInfo(version: ${_this.version}, notes: ${_this.notes}, mandatory: ${_this.mandatory}, url: ${_this.url}, sha256: ${_this.sha256}, size: ${_this.size}, publishedAt: ${_this.publishedAt})';
}


}

/// @nodoc
abstract mixin class $ReleaseInfoCopyWith<$Res>  {
  factory $ReleaseInfoCopyWith(ReleaseInfo value, $Res Function(ReleaseInfo) _then) = _$ReleaseInfoCopyWithImpl;
@useResult
$Res call({
 String version, String notes, bool mandatory, String url, String sha256, int size,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? publishedAt
});




}
/// @nodoc
class _$ReleaseInfoCopyWithImpl<$Res>
    implements $ReleaseInfoCopyWith<$Res> {
  _$ReleaseInfoCopyWithImpl(this._self, this._then);

  final ReleaseInfo _self;
  final $Res Function(ReleaseInfo) _then;

/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? notes = null,Object? mandatory = null,Object? url = null,Object? sha256 = null,Object? size = null,Object? publishedAt = freezed,}) {
  return _then(ReleaseInfo(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,mandatory: null == mandatory ? _self.mandatory : mandatory // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReleaseInfo].
extension ReleaseInfoPatterns on ReleaseInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseInfo value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String notes,  bool mandatory,  String url,  String sha256,  int size, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
return $default(_that.version,_that.notes,_that.mandatory,_that.url,_that.sha256,_that.size,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String notes,  bool mandatory,  String url,  String sha256,  int size, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? publishedAt)  $default,) {final _that = this;
switch (_that) {
case _ReleaseInfo():
return $default(_that.version,_that.notes,_that.mandatory,_that.url,_that.sha256,_that.size,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String notes,  bool mandatory,  String url,  String sha256,  int size, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseInfo() when $default != null:
return $default(_that.version,_that.notes,_that.mandatory,_that.url,_that.sha256,_that.size,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReleaseInfo implements ReleaseInfo {
  const _ReleaseInfo({required this.version, this.notes = '', this.mandatory = false, required this.url, required this.sha256, this.size = 0, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.publishedAt});
  factory _ReleaseInfo.fromJson(Map<String, dynamic> json) => _$ReleaseInfoFromJson(json);

@override final  String version;
@override@JsonKey() final  String notes;
@override@JsonKey() final  bool mandatory;
@override final  String url;
@override final  String sha256;
@override@JsonKey() final  int size;
@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? publishedAt;

/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseInfoCopyWith<_ReleaseInfo> get copyWith => __$ReleaseInfoCopyWithImpl<_ReleaseInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReleaseInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseInfo&&(identical(other.version, version) || other.version == version)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.mandatory, mandatory) || other.mandatory == mandatory)&&(identical(other.url, url) || other.url == url)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.size, size) || other.size == size)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,version,notes,mandatory,url,sha256,size,publishedAt);
}

@override
String toString() {
    return 'ReleaseInfo(version: $version, notes: $notes, mandatory: $mandatory, url: $url, sha256: $sha256, size: $size, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$ReleaseInfoCopyWith<$Res> implements $ReleaseInfoCopyWith<$Res> {
  factory _$ReleaseInfoCopyWith(_ReleaseInfo value, $Res Function(_ReleaseInfo) _then) = __$ReleaseInfoCopyWithImpl;
@override @useResult
$Res call({
 String version, String notes, bool mandatory, String url, String sha256, int size,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? publishedAt
});




}
/// @nodoc
class __$ReleaseInfoCopyWithImpl<$Res>
    implements _$ReleaseInfoCopyWith<$Res> {
  __$ReleaseInfoCopyWithImpl(this._self, this._then);

  final _ReleaseInfo _self;
  final $Res Function(_ReleaseInfo) _then;

/// Create a copy of ReleaseInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? notes = null,Object? mandatory = null,Object? url = null,Object? sha256 = null,Object? size = null,Object? publishedAt = freezed,}) {
  return _then(_ReleaseInfo(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,mandatory: null == mandatory ? _self.mandatory : mandatory // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$DeviceRegistration {

 int get deviceId; String get deviceToken; String get name;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceRegistration&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.deviceToken, _this.deviceToken) || other.deviceToken == _this.deviceToken)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceRegistration;
  return Object.hash(runtimeType,_this.deviceId,_this.deviceToken,_this.name);
}

@override
String toString() {
  final _this = this as DeviceRegistration;
  return 'DeviceRegistration(deviceId: ${_this.deviceId}, deviceToken: ${_this.deviceToken}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $DeviceRegistrationCopyWith<$Res>  {
  factory $DeviceRegistrationCopyWith(DeviceRegistration value, $Res Function(DeviceRegistration) _then) = _$DeviceRegistrationCopyWithImpl;
@useResult
$Res call({
 int deviceId, String deviceToken, String name
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
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceToken = null,Object? name = null,}) {
  return _then(DeviceRegistration(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as int,deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int deviceId,  String deviceToken,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
return $default(_that.deviceId,_that.deviceToken,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int deviceId,  String deviceToken,  String name)  $default,) {final _that = this;
switch (_that) {
case _DeviceRegistration():
return $default(_that.deviceId,_that.deviceToken,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int deviceId,  String deviceToken,  String name)?  $default,) {final _that = this;
switch (_that) {
case _DeviceRegistration() when $default != null:
return $default(_that.deviceId,_that.deviceToken,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceRegistration implements DeviceRegistration {
  const _DeviceRegistration({required this.deviceId, required this.deviceToken, required this.name});
  factory _DeviceRegistration.fromJson(Map<String, dynamic> json) => _$DeviceRegistrationFromJson(json);

@override final  int deviceId;
@override final  String deviceToken;
@override final  String name;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceRegistration&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,deviceId,deviceToken,name);
}

@override
String toString() {
    return 'DeviceRegistration(deviceId: $deviceId, deviceToken: $deviceToken, name: $name)';
}


}

/// @nodoc
abstract mixin class _$DeviceRegistrationCopyWith<$Res> implements $DeviceRegistrationCopyWith<$Res> {
  factory _$DeviceRegistrationCopyWith(_DeviceRegistration value, $Res Function(_DeviceRegistration) _then) = __$DeviceRegistrationCopyWithImpl;
@override @useResult
$Res call({
 int deviceId, String deviceToken, String name
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
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceToken = null,Object? name = null,}) {
  return _then(_DeviceRegistration(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as int,deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DeviceHeartbeat {

@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime; bool get unlock;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceHeartbeat&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.unlock, _this.unlock) || other.unlock == _this.unlock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceHeartbeat;
  return Object.hash(runtimeType,_this.serverTime,_this.unlock);
}

@override
String toString() {
  final _this = this as DeviceHeartbeat;
  return 'DeviceHeartbeat(serverTime: ${_this.serverTime}, unlock: ${_this.unlock})';
}


}

/// @nodoc
abstract mixin class $DeviceHeartbeatCopyWith<$Res>  {
  factory $DeviceHeartbeatCopyWith(DeviceHeartbeat value, $Res Function(DeviceHeartbeat) _then) = _$DeviceHeartbeatCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime, bool unlock
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
@pragma('vm:prefer-inline') @override $Res call({Object? serverTime = freezed,Object? unlock = null,}) {
  return _then(DeviceHeartbeat(
serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,unlock: null == unlock ? _self.unlock : unlock // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool unlock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceHeartbeat() when $default != null:
return $default(_that.serverTime,_that.unlock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool unlock)  $default,) {final _that = this;
switch (_that) {
case _DeviceHeartbeat():
return $default(_that.serverTime,_that.unlock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime,  bool unlock)?  $default,) {final _that = this;
switch (_that) {
case _DeviceHeartbeat() when $default != null:
return $default(_that.serverTime,_that.unlock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceHeartbeat implements DeviceHeartbeat {
  const _DeviceHeartbeat({@JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime, this.unlock = false});
  factory _DeviceHeartbeat.fromJson(Map<String, dynamic> json) => _$DeviceHeartbeatFromJson(json);

@override@JsonKey(fromJson: dateOrNull, toJson: dateToJson) final  DateTime? serverTime;
@override@JsonKey() final  bool unlock;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceHeartbeat&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.unlock, unlock) || other.unlock == unlock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,serverTime,unlock);
}

@override
String toString() {
    return 'DeviceHeartbeat(serverTime: $serverTime, unlock: $unlock)';
}


}

/// @nodoc
abstract mixin class _$DeviceHeartbeatCopyWith<$Res> implements $DeviceHeartbeatCopyWith<$Res> {
  factory _$DeviceHeartbeatCopyWith(_DeviceHeartbeat value, $Res Function(_DeviceHeartbeat) _then) = __$DeviceHeartbeatCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime, bool unlock
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
@override @pragma('vm:prefer-inline') $Res call({Object? serverTime = freezed,Object? unlock = null,}) {
  return _then(_DeviceHeartbeat(
serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,unlock: null == unlock ? _self.unlock : unlock // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DeviceConfig {

 String? get exitPasswordOffline; List<String> get bannedProcesses; int get heartbeatSeconds; int get violationBatchSeconds;@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? get serverTime;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceConfig&&(identical(other.exitPasswordOffline, _this.exitPasswordOffline) || other.exitPasswordOffline == _this.exitPasswordOffline)&&const DeepCollectionEquality().equals(other.bannedProcesses, _this.bannedProcesses)&&(identical(other.heartbeatSeconds, _this.heartbeatSeconds) || other.heartbeatSeconds == _this.heartbeatSeconds)&&(identical(other.violationBatchSeconds, _this.violationBatchSeconds) || other.violationBatchSeconds == _this.violationBatchSeconds)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceConfig;
  return Object.hash(runtimeType,_this.exitPasswordOffline,const DeepCollectionEquality().hash(_this.bannedProcesses),_this.heartbeatSeconds,_this.violationBatchSeconds,_this.serverTime);
}

@override
String toString() {
  final _this = this as DeviceConfig;
  return 'DeviceConfig(exitPasswordOffline: ${_this.exitPasswordOffline}, bannedProcesses: ${_this.bannedProcesses}, heartbeatSeconds: ${_this.heartbeatSeconds}, violationBatchSeconds: ${_this.violationBatchSeconds}, serverTime: ${_this.serverTime})';
}


}

/// @nodoc
abstract mixin class $DeviceConfigCopyWith<$Res>  {
  factory $DeviceConfigCopyWith(DeviceConfig value, $Res Function(DeviceConfig) _then) = _$DeviceConfigCopyWithImpl;
@useResult
$Res call({
 String? exitPasswordOffline, List<String> bannedProcesses, int heartbeatSeconds, int violationBatchSeconds,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
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
@pragma('vm:prefer-inline') @override $Res call({Object? exitPasswordOffline = freezed,Object? bannedProcesses = null,Object? heartbeatSeconds = null,Object? violationBatchSeconds = null,Object? serverTime = freezed,}) {
  return _then(DeviceConfig(
exitPasswordOffline: freezed == exitPasswordOffline ? _self.exitPasswordOffline : exitPasswordOffline // ignore: cast_nullable_to_non_nullable
as String?,bannedProcesses: null == bannedProcesses ? _self.bannedProcesses : bannedProcesses // ignore: cast_nullable_to_non_nullable
as List<String>,heartbeatSeconds: null == heartbeatSeconds ? _self.heartbeatSeconds : heartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,violationBatchSeconds: null == violationBatchSeconds ? _self.violationBatchSeconds : violationBatchSeconds // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? exitPasswordOffline,  List<String> bannedProcesses,  int heartbeatSeconds,  int violationBatchSeconds, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that.exitPasswordOffline,_that.bannedProcesses,_that.heartbeatSeconds,_that.violationBatchSeconds,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? exitPasswordOffline,  List<String> bannedProcesses,  int heartbeatSeconds,  int violationBatchSeconds, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)  $default,) {final _that = this;
switch (_that) {
case _DeviceConfig():
return $default(_that.exitPasswordOffline,_that.bannedProcesses,_that.heartbeatSeconds,_that.violationBatchSeconds,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? exitPasswordOffline,  List<String> bannedProcesses,  int heartbeatSeconds,  int violationBatchSeconds, @JsonKey(fromJson: dateOrNull, toJson: dateToJson)  DateTime? serverTime)?  $default,) {final _that = this;
switch (_that) {
case _DeviceConfig() when $default != null:
return $default(_that.exitPasswordOffline,_that.bannedProcesses,_that.heartbeatSeconds,_that.violationBatchSeconds,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceConfig implements DeviceConfig {
  const _DeviceConfig({this.exitPasswordOffline,  List<String> bannedProcesses = const <String>[], this.heartbeatSeconds = 20, this.violationBatchSeconds = 10, @JsonKey(fromJson: dateOrNull, toJson: dateToJson) this.serverTime}): _bannedProcesses = bannedProcesses;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceConfig&&(identical(other.exitPasswordOffline, exitPasswordOffline) || other.exitPasswordOffline == exitPasswordOffline)&&const DeepCollectionEquality().equals(other.bannedProcesses, _bannedProcesses)&&(identical(other.heartbeatSeconds, heartbeatSeconds) || other.heartbeatSeconds == heartbeatSeconds)&&(identical(other.violationBatchSeconds, violationBatchSeconds) || other.violationBatchSeconds == violationBatchSeconds)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,exitPasswordOffline,const DeepCollectionEquality().hash(_bannedProcesses),heartbeatSeconds,violationBatchSeconds,serverTime);
}

@override
String toString() {
    return 'DeviceConfig(exitPasswordOffline: $exitPasswordOffline, bannedProcesses: $bannedProcesses, heartbeatSeconds: $heartbeatSeconds, violationBatchSeconds: $violationBatchSeconds, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$DeviceConfigCopyWith<$Res> implements $DeviceConfigCopyWith<$Res> {
  factory _$DeviceConfigCopyWith(_DeviceConfig value, $Res Function(_DeviceConfig) _then) = __$DeviceConfigCopyWithImpl;
@override @useResult
$Res call({
 String? exitPasswordOffline, List<String> bannedProcesses, int heartbeatSeconds, int violationBatchSeconds,@JsonKey(fromJson: dateOrNull, toJson: dateToJson) DateTime? serverTime
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
@override @pragma('vm:prefer-inline') $Res call({Object? exitPasswordOffline = freezed,Object? bannedProcesses = null,Object? heartbeatSeconds = null,Object? violationBatchSeconds = null,Object? serverTime = freezed,}) {
  return _then(_DeviceConfig(
exitPasswordOffline: freezed == exitPasswordOffline ? _self.exitPasswordOffline : exitPasswordOffline // ignore: cast_nullable_to_non_nullable
as String?,bannedProcesses: null == bannedProcesses ? _self._bannedProcesses : bannedProcesses // ignore: cast_nullable_to_non_nullable
as List<String>,heartbeatSeconds: null == heartbeatSeconds ? _self.heartbeatSeconds : heartbeatSeconds // ignore: cast_nullable_to_non_nullable
as int,violationBatchSeconds: null == violationBatchSeconds ? _self.violationBatchSeconds : violationBatchSeconds // ignore: cast_nullable_to_non_nullable
as int,serverTime: freezed == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
