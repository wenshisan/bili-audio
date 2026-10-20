// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stream_url.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreamUrl {

/// B 站 BV 号
 String get bvid;/// 分P标识
 int get cid;/// 音质档位
 AudioQuality get quality;/// 流地址 (HTTPS)
 String get url;/// 备用流地址列表 (按优先级排序)
 List<String> get backupUrls;/// 过期时间 (Unix timestamp)
 int get expiresAt;
/// Create a copy of StreamUrl
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreamUrlCopyWith<StreamUrl> get copyWith => _$StreamUrlCopyWithImpl<StreamUrl>(this as StreamUrl, _$identity);

  /// Serializes this StreamUrl to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreamUrl&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.backupUrls, backupUrls)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,cid,quality,url,const DeepCollectionEquality().hash(backupUrls),expiresAt);

@override
String toString() {
  return 'StreamUrl(bvid: $bvid, cid: $cid, quality: $quality, url: $url, backupUrls: $backupUrls, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $StreamUrlCopyWith<$Res>  {
  factory $StreamUrlCopyWith(StreamUrl value, $Res Function(StreamUrl) _then) = _$StreamUrlCopyWithImpl;
@useResult
$Res call({
 String bvid, int cid, AudioQuality quality, String url, List<String> backupUrls, int expiresAt
});




}
/// @nodoc
class _$StreamUrlCopyWithImpl<$Res>
    implements $StreamUrlCopyWith<$Res> {
  _$StreamUrlCopyWithImpl(this._self, this._then);

  final StreamUrl _self;
  final $Res Function(StreamUrl) _then;

/// Create a copy of StreamUrl
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bvid = null,Object? cid = null,Object? quality = null,Object? url = null,Object? backupUrls = null,Object? expiresAt = null,}) {
  return _then(StreamUrl(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as AudioQuality,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,backupUrls: null == backupUrls ? _self.backupUrls : backupUrls // ignore: cast_nullable_to_non_nullable
as List<String>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StreamUrl].
extension StreamUrlPatterns on StreamUrl {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreamUrl value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreamUrl() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreamUrl value)  $default,){
final _that = this;
switch (_that) {
case _StreamUrl():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreamUrl value)?  $default,){
final _that = this;
switch (_that) {
case _StreamUrl() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bvid,  int cid,  AudioQuality quality,  String url,  List<String> backupUrls,  int expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreamUrl() when $default != null:
return $default(_that.bvid,_that.cid,_that.quality,_that.url,_that.backupUrls,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bvid,  int cid,  AudioQuality quality,  String url,  List<String> backupUrls,  int expiresAt)  $default,) {final _that = this;
switch (_that) {
case _StreamUrl():
return $default(_that.bvid,_that.cid,_that.quality,_that.url,_that.backupUrls,_that.expiresAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bvid,  int cid,  AudioQuality quality,  String url,  List<String> backupUrls,  int expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _StreamUrl() when $default != null:
return $default(_that.bvid,_that.cid,_that.quality,_that.url,_that.backupUrls,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreamUrl extends StreamUrl {
  const _StreamUrl({required this.bvid, required this.cid, required this.quality, required this.url,  List<String> backupUrls = const [], required this.expiresAt}): _backupUrls = backupUrls,super._();
  factory _StreamUrl.fromJson(Map<String, dynamic> json) => _$StreamUrlFromJson(json);

/// B 站 BV 号
@override final  String bvid;
/// 分P标识
@override final  int cid;
/// 音质档位
@override final  AudioQuality quality;
/// 流地址 (HTTPS)
@override final  String url;
/// 备用流地址列表 (按优先级排序)
 final  List<String> _backupUrls;
/// 备用流地址列表 (按优先级排序)
@override@JsonKey() List<String> get backupUrls {
  if (_backupUrls is EqualUnmodifiableListView) return _backupUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backupUrls);
}

/// 过期时间 (Unix timestamp)
@override final  int expiresAt;

/// Create a copy of StreamUrl
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamUrlCopyWith<_StreamUrl> get copyWith => __$StreamUrlCopyWithImpl<_StreamUrl>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreamUrlToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamUrl&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other._backupUrls, _backupUrls)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,cid,quality,url,const DeepCollectionEquality().hash(_backupUrls),expiresAt);

@override
String toString() {
  return 'StreamUrl(bvid: $bvid, cid: $cid, quality: $quality, url: $url, backupUrls: $backupUrls, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$StreamUrlCopyWith<$Res> implements $StreamUrlCopyWith<$Res> {
  factory _$StreamUrlCopyWith(_StreamUrl value, $Res Function(_StreamUrl) _then) = __$StreamUrlCopyWithImpl;
@override @useResult
$Res call({
 String bvid, int cid, AudioQuality quality, String url, List<String> backupUrls, int expiresAt
});




}
/// @nodoc
class __$StreamUrlCopyWithImpl<$Res>
    implements _$StreamUrlCopyWith<$Res> {
  __$StreamUrlCopyWithImpl(this._self, this._then);

  final _StreamUrl _self;
  final $Res Function(_StreamUrl) _then;

/// Create a copy of StreamUrl
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bvid = null,Object? cid = null,Object? quality = null,Object? url = null,Object? backupUrls = null,Object? expiresAt = null,}) {
  return _then(_StreamUrl(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as AudioQuality,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,backupUrls: null == backupUrls ? _self._backupUrls : backupUrls // ignore: cast_nullable_to_non_nullable
as List<String>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
