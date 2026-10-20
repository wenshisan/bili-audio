// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Track {

/// B 站 BV 号
 String get bvid;/// 分P标识 (cid)
 int get cid;/// B 站原始标题 (视频标题或分P标题)
 String get title;/// 清洗后歌名 (由 TitleCleaner 处理)
 String? get cleanedName;/// 清洗后歌手 (由 TitleCleaner 处理)
 String? get artist;/// 时长
 Duration get duration;/// 封面 URL
 String? get cover;/// UP 主名称
 String? get uploader;/// 分P序号 (1-based)
 int? get pageIndex;/// 总分P数
 int? get totalPages;
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackCopyWith<Track> get copyWith => _$TrackCopyWithImpl<Track>(this as Track, _$identity);

  /// Serializes this Track to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Track&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.title, title) || other.title == title)&&(identical(other.cleanedName, cleanedName) || other.cleanedName == cleanedName)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,cid,title,cleanedName,artist,duration,cover,uploader,pageIndex,totalPages);

@override
String toString() {
  return 'Track(bvid: $bvid, cid: $cid, title: $title, cleanedName: $cleanedName, artist: $artist, duration: $duration, cover: $cover, uploader: $uploader, pageIndex: $pageIndex, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class $TrackCopyWith<$Res>  {
  factory $TrackCopyWith(Track value, $Res Function(Track) _then) = _$TrackCopyWithImpl;
@useResult
$Res call({
 String bvid, int cid, String title, String? cleanedName, String? artist, Duration duration, String? cover, String? uploader, int? pageIndex, int? totalPages
});




}
/// @nodoc
class _$TrackCopyWithImpl<$Res>
    implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._self, this._then);

  final Track _self;
  final $Res Function(Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bvid = null,Object? cid = null,Object? title = null,Object? cleanedName = freezed,Object? artist = freezed,Object? duration = null,Object? cover = freezed,Object? uploader = freezed,Object? pageIndex = freezed,Object? totalPages = freezed,}) {
  return _then(Track(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cleanedName: freezed == cleanedName ? _self.cleanedName : cleanedName // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String?,pageIndex: freezed == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int?,totalPages: freezed == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Track].
extension TrackPatterns on Track {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Track value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Track value)  $default,){
final _that = this;
switch (_that) {
case _Track():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Track value)?  $default,){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bvid,  int cid,  String title,  String? cleanedName,  String? artist,  Duration duration,  String? cover,  String? uploader,  int? pageIndex,  int? totalPages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.bvid,_that.cid,_that.title,_that.cleanedName,_that.artist,_that.duration,_that.cover,_that.uploader,_that.pageIndex,_that.totalPages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bvid,  int cid,  String title,  String? cleanedName,  String? artist,  Duration duration,  String? cover,  String? uploader,  int? pageIndex,  int? totalPages)  $default,) {final _that = this;
switch (_that) {
case _Track():
return $default(_that.bvid,_that.cid,_that.title,_that.cleanedName,_that.artist,_that.duration,_that.cover,_that.uploader,_that.pageIndex,_that.totalPages);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bvid,  int cid,  String title,  String? cleanedName,  String? artist,  Duration duration,  String? cover,  String? uploader,  int? pageIndex,  int? totalPages)?  $default,) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.bvid,_that.cid,_that.title,_that.cleanedName,_that.artist,_that.duration,_that.cover,_that.uploader,_that.pageIndex,_that.totalPages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Track extends Track {
  const _Track({required this.bvid, required this.cid, required this.title, this.cleanedName, this.artist, required this.duration, this.cover, this.uploader, this.pageIndex, this.totalPages}): super._();
  factory _Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

/// B 站 BV 号
@override final  String bvid;
/// 分P标识 (cid)
@override final  int cid;
/// B 站原始标题 (视频标题或分P标题)
@override final  String title;
/// 清洗后歌名 (由 TitleCleaner 处理)
@override final  String? cleanedName;
/// 清洗后歌手 (由 TitleCleaner 处理)
@override final  String? artist;
/// 时长
@override final  Duration duration;
/// 封面 URL
@override final  String? cover;
/// UP 主名称
@override final  String? uploader;
/// 分P序号 (1-based)
@override final  int? pageIndex;
/// 总分P数
@override final  int? totalPages;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackCopyWith<_Track> get copyWith => __$TrackCopyWithImpl<_Track>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Track&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.title, title) || other.title == title)&&(identical(other.cleanedName, cleanedName) || other.cleanedName == cleanedName)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,cid,title,cleanedName,artist,duration,cover,uploader,pageIndex,totalPages);

@override
String toString() {
  return 'Track(bvid: $bvid, cid: $cid, title: $title, cleanedName: $cleanedName, artist: $artist, duration: $duration, cover: $cover, uploader: $uploader, pageIndex: $pageIndex, totalPages: $totalPages)';
}


}

/// @nodoc
abstract mixin class _$TrackCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$TrackCopyWith(_Track value, $Res Function(_Track) _then) = __$TrackCopyWithImpl;
@override @useResult
$Res call({
 String bvid, int cid, String title, String? cleanedName, String? artist, Duration duration, String? cover, String? uploader, int? pageIndex, int? totalPages
});




}
/// @nodoc
class __$TrackCopyWithImpl<$Res>
    implements _$TrackCopyWith<$Res> {
  __$TrackCopyWithImpl(this._self, this._then);

  final _Track _self;
  final $Res Function(_Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bvid = null,Object? cid = null,Object? title = null,Object? cleanedName = freezed,Object? artist = freezed,Object? duration = null,Object? cover = freezed,Object? uploader = freezed,Object? pageIndex = freezed,Object? totalPages = freezed,}) {
  return _then(_Track(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cleanedName: freezed == cleanedName ? _self.cleanedName : cleanedName // ignore: cast_nullable_to_non_nullable
as String?,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,uploader: freezed == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String?,pageIndex: freezed == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int?,totalPages: freezed == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
