// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoPage {

/// 分P标识
 int get cid;/// 分P标题
 String get title;/// 时长
 Duration get duration;/// 分P序号 (1-based)
 int get pageIndex;
/// Create a copy of VideoPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoPageCopyWith<VideoPage> get copyWith => _$VideoPageCopyWithImpl<VideoPage>(this as VideoPage, _$identity);

  /// Serializes this VideoPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoPage&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cid,title,duration,pageIndex);

@override
String toString() {
  return 'VideoPage(cid: $cid, title: $title, duration: $duration, pageIndex: $pageIndex)';
}


}

/// @nodoc
abstract mixin class $VideoPageCopyWith<$Res>  {
  factory $VideoPageCopyWith(VideoPage value, $Res Function(VideoPage) _then) = _$VideoPageCopyWithImpl;
@useResult
$Res call({
 int cid, String title, Duration duration, int pageIndex
});




}
/// @nodoc
class _$VideoPageCopyWithImpl<$Res>
    implements $VideoPageCopyWith<$Res> {
  _$VideoPageCopyWithImpl(this._self, this._then);

  final VideoPage _self;
  final $Res Function(VideoPage) _then;

/// Create a copy of VideoPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cid = null,Object? title = null,Object? duration = null,Object? pageIndex = null,}) {
  return _then(VideoPage(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoPage].
extension VideoPagePatterns on VideoPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoPage value)  $default,){
final _that = this;
switch (_that) {
case _VideoPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoPage value)?  $default,){
final _that = this;
switch (_that) {
case _VideoPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cid,  String title,  Duration duration,  int pageIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoPage() when $default != null:
return $default(_that.cid,_that.title,_that.duration,_that.pageIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cid,  String title,  Duration duration,  int pageIndex)  $default,) {final _that = this;
switch (_that) {
case _VideoPage():
return $default(_that.cid,_that.title,_that.duration,_that.pageIndex);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cid,  String title,  Duration duration,  int pageIndex)?  $default,) {final _that = this;
switch (_that) {
case _VideoPage() when $default != null:
return $default(_that.cid,_that.title,_that.duration,_that.pageIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoPage implements VideoPage {
  const _VideoPage({required this.cid, required this.title, required this.duration, required this.pageIndex});
  factory _VideoPage.fromJson(Map<String, dynamic> json) => _$VideoPageFromJson(json);

/// 分P标识
@override final  int cid;
/// 分P标题
@override final  String title;
/// 时长
@override final  Duration duration;
/// 分P序号 (1-based)
@override final  int pageIndex;

/// Create a copy of VideoPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoPageCopyWith<_VideoPage> get copyWith => __$VideoPageCopyWithImpl<_VideoPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoPage&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.pageIndex, pageIndex) || other.pageIndex == pageIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cid,title,duration,pageIndex);

@override
String toString() {
  return 'VideoPage(cid: $cid, title: $title, duration: $duration, pageIndex: $pageIndex)';
}


}

/// @nodoc
abstract mixin class _$VideoPageCopyWith<$Res> implements $VideoPageCopyWith<$Res> {
  factory _$VideoPageCopyWith(_VideoPage value, $Res Function(_VideoPage) _then) = __$VideoPageCopyWithImpl;
@override @useResult
$Res call({
 int cid, String title, Duration duration, int pageIndex
});




}
/// @nodoc
class __$VideoPageCopyWithImpl<$Res>
    implements _$VideoPageCopyWith<$Res> {
  __$VideoPageCopyWithImpl(this._self, this._then);

  final _VideoPage _self;
  final $Res Function(_VideoPage) _then;

/// Create a copy of VideoPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cid = null,Object? title = null,Object? duration = null,Object? pageIndex = null,}) {
  return _then(_VideoPage(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,pageIndex: null == pageIndex ? _self.pageIndex : pageIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Video {

/// B 站 BV 号
 String get bvid;/// 视频标题
 String get title;/// UP 主名称
 String get uploader;/// UP 主 mid
 int get uploaderMid;/// 封面 URL
 String get cover;/// 分P列表
 List<VideoPage> get pages;/// 标签
 List<String> get tags;/// 播放量
 int? get viewCount;/// 发布时间 (Unix timestamp)
 int? get publishTime;
/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoCopyWith<Video> get copyWith => _$VideoCopyWithImpl<Video>(this as Video, _$identity);

  /// Serializes this Video to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Video&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.uploaderMid, uploaderMid) || other.uploaderMid == uploaderMid)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other.pages, pages)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.publishTime, publishTime) || other.publishTime == publishTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,title,uploader,uploaderMid,cover,const DeepCollectionEquality().hash(pages),const DeepCollectionEquality().hash(tags),viewCount,publishTime);

@override
String toString() {
  return 'Video(bvid: $bvid, title: $title, uploader: $uploader, uploaderMid: $uploaderMid, cover: $cover, pages: $pages, tags: $tags, viewCount: $viewCount, publishTime: $publishTime)';
}


}

/// @nodoc
abstract mixin class $VideoCopyWith<$Res>  {
  factory $VideoCopyWith(Video value, $Res Function(Video) _then) = _$VideoCopyWithImpl;
@useResult
$Res call({
 String bvid, String title, String uploader, int uploaderMid, String cover, List<VideoPage> pages, List<String> tags, int? viewCount, int? publishTime
});




}
/// @nodoc
class _$VideoCopyWithImpl<$Res>
    implements $VideoCopyWith<$Res> {
  _$VideoCopyWithImpl(this._self, this._then);

  final Video _self;
  final $Res Function(Video) _then;

/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bvid = null,Object? title = null,Object? uploader = null,Object? uploaderMid = null,Object? cover = null,Object? pages = null,Object? tags = null,Object? viewCount = freezed,Object? publishTime = freezed,}) {
  return _then(Video(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,uploader: null == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String,uploaderMid: null == uploaderMid ? _self.uploaderMid : uploaderMid // ignore: cast_nullable_to_non_nullable
as int,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as List<VideoPage>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,publishTime: freezed == publishTime ? _self.publishTime : publishTime // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Video].
extension VideoPatterns on Video {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Video value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Video() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Video value)  $default,){
final _that = this;
switch (_that) {
case _Video():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Video value)?  $default,){
final _that = this;
switch (_that) {
case _Video() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bvid,  String title,  String uploader,  int uploaderMid,  String cover,  List<VideoPage> pages,  List<String> tags,  int? viewCount,  int? publishTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Video() when $default != null:
return $default(_that.bvid,_that.title,_that.uploader,_that.uploaderMid,_that.cover,_that.pages,_that.tags,_that.viewCount,_that.publishTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bvid,  String title,  String uploader,  int uploaderMid,  String cover,  List<VideoPage> pages,  List<String> tags,  int? viewCount,  int? publishTime)  $default,) {final _that = this;
switch (_that) {
case _Video():
return $default(_that.bvid,_that.title,_that.uploader,_that.uploaderMid,_that.cover,_that.pages,_that.tags,_that.viewCount,_that.publishTime);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bvid,  String title,  String uploader,  int uploaderMid,  String cover,  List<VideoPage> pages,  List<String> tags,  int? viewCount,  int? publishTime)?  $default,) {final _that = this;
switch (_that) {
case _Video() when $default != null:
return $default(_that.bvid,_that.title,_that.uploader,_that.uploaderMid,_that.cover,_that.pages,_that.tags,_that.viewCount,_that.publishTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Video implements Video {
  const _Video({required this.bvid, required this.title, required this.uploader, required this.uploaderMid, required this.cover, required  List<VideoPage> pages,  List<String> tags = const [], this.viewCount, this.publishTime}): _pages = pages,_tags = tags;
  factory _Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

/// B 站 BV 号
@override final  String bvid;
/// 视频标题
@override final  String title;
/// UP 主名称
@override final  String uploader;
/// UP 主 mid
@override final  int uploaderMid;
/// 封面 URL
@override final  String cover;
/// 分P列表
 final  List<VideoPage> _pages;
/// 分P列表
@override List<VideoPage> get pages {
  if (_pages is EqualUnmodifiableListView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pages);
}

/// 标签
 final  List<String> _tags;
/// 标签
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// 播放量
@override final  int? viewCount;
/// 发布时间 (Unix timestamp)
@override final  int? publishTime;

/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoCopyWith<_Video> get copyWith => __$VideoCopyWithImpl<_Video>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Video&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.uploaderMid, uploaderMid) || other.uploaderMid == uploaderMid)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other._pages, _pages)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.publishTime, publishTime) || other.publishTime == publishTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,title,uploader,uploaderMid,cover,const DeepCollectionEquality().hash(_pages),const DeepCollectionEquality().hash(_tags),viewCount,publishTime);

@override
String toString() {
  return 'Video(bvid: $bvid, title: $title, uploader: $uploader, uploaderMid: $uploaderMid, cover: $cover, pages: $pages, tags: $tags, viewCount: $viewCount, publishTime: $publishTime)';
}


}

/// @nodoc
abstract mixin class _$VideoCopyWith<$Res> implements $VideoCopyWith<$Res> {
  factory _$VideoCopyWith(_Video value, $Res Function(_Video) _then) = __$VideoCopyWithImpl;
@override @useResult
$Res call({
 String bvid, String title, String uploader, int uploaderMid, String cover, List<VideoPage> pages, List<String> tags, int? viewCount, int? publishTime
});




}
/// @nodoc
class __$VideoCopyWithImpl<$Res>
    implements _$VideoCopyWith<$Res> {
  __$VideoCopyWithImpl(this._self, this._then);

  final _Video _self;
  final $Res Function(_Video) _then;

/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bvid = null,Object? title = null,Object? uploader = null,Object? uploaderMid = null,Object? cover = null,Object? pages = null,Object? tags = null,Object? viewCount = freezed,Object? publishTime = freezed,}) {
  return _then(_Video(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,uploader: null == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String,uploaderMid: null == uploaderMid ? _self.uploaderMid : uploaderMid // ignore: cast_nullable_to_non_nullable
as int,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as List<VideoPage>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,publishTime: freezed == publishTime ? _self.publishTime : publishTime // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
