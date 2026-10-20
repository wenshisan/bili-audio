// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'play_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayHistory {

/// 自增主键 (数据库生成)
 int? get id;/// B 站 BV 号
 String get bvid;/// 分P标识
 int get cid;/// 播放时间 (Unix timestamp)
 int get playedAt;/// 播放进度 (毫秒)
 int get positionMs;/// 完成度 (0-1)
 double get completion;
/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayHistoryCopyWith<PlayHistory> get copyWith => _$PlayHistoryCopyWithImpl<PlayHistory>(this as PlayHistory, _$identity);

  /// Serializes this PlayHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.completion, completion) || other.completion == completion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bvid,cid,playedAt,positionMs,completion);

@override
String toString() {
  return 'PlayHistory(id: $id, bvid: $bvid, cid: $cid, playedAt: $playedAt, positionMs: $positionMs, completion: $completion)';
}


}

/// @nodoc
abstract mixin class $PlayHistoryCopyWith<$Res>  {
  factory $PlayHistoryCopyWith(PlayHistory value, $Res Function(PlayHistory) _then) = _$PlayHistoryCopyWithImpl;
@useResult
$Res call({
 int? id, String bvid, int cid, int playedAt, int positionMs, double completion
});




}
/// @nodoc
class _$PlayHistoryCopyWithImpl<$Res>
    implements $PlayHistoryCopyWith<$Res> {
  _$PlayHistoryCopyWithImpl(this._self, this._then);

  final PlayHistory _self;
  final $Res Function(PlayHistory) _then;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? bvid = null,Object? cid = null,Object? playedAt = null,Object? positionMs = null,Object? completion = null,}) {
  return _then(PlayHistory(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as int,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,completion: null == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayHistory].
extension PlayHistoryPatterns on PlayHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayHistory value)  $default,){
final _that = this;
switch (_that) {
case _PlayHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayHistory value)?  $default,){
final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String bvid,  int cid,  int playedAt,  int positionMs,  double completion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
return $default(_that.id,_that.bvid,_that.cid,_that.playedAt,_that.positionMs,_that.completion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String bvid,  int cid,  int playedAt,  int positionMs,  double completion)  $default,) {final _that = this;
switch (_that) {
case _PlayHistory():
return $default(_that.id,_that.bvid,_that.cid,_that.playedAt,_that.positionMs,_that.completion);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String bvid,  int cid,  int playedAt,  int positionMs,  double completion)?  $default,) {final _that = this;
switch (_that) {
case _PlayHistory() when $default != null:
return $default(_that.id,_that.bvid,_that.cid,_that.playedAt,_that.positionMs,_that.completion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayHistory implements PlayHistory {
  const _PlayHistory({this.id, required this.bvid, required this.cid, required this.playedAt, this.positionMs = 0, this.completion = 0.0});
  factory _PlayHistory.fromJson(Map<String, dynamic> json) => _$PlayHistoryFromJson(json);

/// 自增主键 (数据库生成)
@override final  int? id;
/// B 站 BV 号
@override final  String bvid;
/// 分P标识
@override final  int cid;
/// 播放时间 (Unix timestamp)
@override final  int playedAt;
/// 播放进度 (毫秒)
@override@JsonKey() final  int positionMs;
/// 完成度 (0-1)
@override@JsonKey() final  double completion;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayHistoryCopyWith<_PlayHistory> get copyWith => __$PlayHistoryCopyWithImpl<_PlayHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.playedAt, playedAt) || other.playedAt == playedAt)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.completion, completion) || other.completion == completion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bvid,cid,playedAt,positionMs,completion);

@override
String toString() {
  return 'PlayHistory(id: $id, bvid: $bvid, cid: $cid, playedAt: $playedAt, positionMs: $positionMs, completion: $completion)';
}


}

/// @nodoc
abstract mixin class _$PlayHistoryCopyWith<$Res> implements $PlayHistoryCopyWith<$Res> {
  factory _$PlayHistoryCopyWith(_PlayHistory value, $Res Function(_PlayHistory) _then) = __$PlayHistoryCopyWithImpl;
@override @useResult
$Res call({
 int? id, String bvid, int cid, int playedAt, int positionMs, double completion
});




}
/// @nodoc
class __$PlayHistoryCopyWithImpl<$Res>
    implements _$PlayHistoryCopyWith<$Res> {
  __$PlayHistoryCopyWithImpl(this._self, this._then);

  final _PlayHistory _self;
  final $Res Function(_PlayHistory) _then;

/// Create a copy of PlayHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? bvid = null,Object? cid = null,Object? playedAt = null,Object? positionMs = null,Object? completion = null,}) {
  return _then(_PlayHistory(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,playedAt: null == playedAt ? _self.playedAt : playedAt // ignore: cast_nullable_to_non_nullable
as int,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,completion: null == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
