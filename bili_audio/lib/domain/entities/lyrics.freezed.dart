// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lyrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LyricLine {

/// 时间戳
 Duration get timestamp;/// 歌词文本
 String get text;/// 翻译 (可选)
 String? get translation;
/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricLineCopyWith<LyricLine> get copyWith => _$LyricLineCopyWithImpl<LyricLine>(this as LyricLine, _$identity);

  /// Serializes this LyricLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LyricLine&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.text, text) || other.text == text)&&(identical(other.translation, translation) || other.translation == translation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,text,translation);

@override
String toString() {
  return 'LyricLine(timestamp: $timestamp, text: $text, translation: $translation)';
}


}

/// @nodoc
abstract mixin class $LyricLineCopyWith<$Res>  {
  factory $LyricLineCopyWith(LyricLine value, $Res Function(LyricLine) _then) = _$LyricLineCopyWithImpl;
@useResult
$Res call({
 Duration timestamp, String text, String? translation
});




}
/// @nodoc
class _$LyricLineCopyWithImpl<$Res>
    implements $LyricLineCopyWith<$Res> {
  _$LyricLineCopyWithImpl(this._self, this._then);

  final LyricLine _self;
  final $Res Function(LyricLine) _then;

/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? text = null,Object? translation = freezed,}) {
  return _then(LyricLine(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as Duration,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,translation: freezed == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LyricLine].
extension LyricLinePatterns on LyricLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LyricLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LyricLine value)  $default,){
final _that = this;
switch (_that) {
case _LyricLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LyricLine value)?  $default,){
final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration timestamp,  String text,  String? translation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
return $default(_that.timestamp,_that.text,_that.translation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration timestamp,  String text,  String? translation)  $default,) {final _that = this;
switch (_that) {
case _LyricLine():
return $default(_that.timestamp,_that.text,_that.translation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration timestamp,  String text,  String? translation)?  $default,) {final _that = this;
switch (_that) {
case _LyricLine() when $default != null:
return $default(_that.timestamp,_that.text,_that.translation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LyricLine implements LyricLine {
  const _LyricLine({required this.timestamp, required this.text, this.translation});
  factory _LyricLine.fromJson(Map<String, dynamic> json) => _$LyricLineFromJson(json);

/// 时间戳
@override final  Duration timestamp;
/// 歌词文本
@override final  String text;
/// 翻译 (可选)
@override final  String? translation;

/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricLineCopyWith<_LyricLine> get copyWith => __$LyricLineCopyWithImpl<_LyricLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LyricLine&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.text, text) || other.text == text)&&(identical(other.translation, translation) || other.translation == translation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,text,translation);

@override
String toString() {
  return 'LyricLine(timestamp: $timestamp, text: $text, translation: $translation)';
}


}

/// @nodoc
abstract mixin class _$LyricLineCopyWith<$Res> implements $LyricLineCopyWith<$Res> {
  factory _$LyricLineCopyWith(_LyricLine value, $Res Function(_LyricLine) _then) = __$LyricLineCopyWithImpl;
@override @useResult
$Res call({
 Duration timestamp, String text, String? translation
});




}
/// @nodoc
class __$LyricLineCopyWithImpl<$Res>
    implements _$LyricLineCopyWith<$Res> {
  __$LyricLineCopyWithImpl(this._self, this._then);

  final _LyricLine _self;
  final $Res Function(_LyricLine) _then;

/// Create a copy of LyricLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? text = null,Object? translation = freezed,}) {
  return _then(_LyricLine(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as Duration,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,translation: freezed == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Lyrics {

/// 歌词行列表 (按 timestamp 升序)
 List<LyricLine> get lines;/// 用户校准偏移 (默认 0)
 Duration get offset;/// 歌词来源 (lrclib / bilibili_cc / local)
 String? get source;/// 匹配得分 (0-1)
 double? get matchScore;
/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LyricsCopyWith<Lyrics> get copyWith => _$LyricsCopyWithImpl<Lyrics>(this as Lyrics, _$identity);

  /// Serializes this Lyrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lyrics&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.source, source) || other.source == source)&&(identical(other.matchScore, matchScore) || other.matchScore == matchScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(lines),offset,source,matchScore);

@override
String toString() {
  return 'Lyrics(lines: $lines, offset: $offset, source: $source, matchScore: $matchScore)';
}


}

/// @nodoc
abstract mixin class $LyricsCopyWith<$Res>  {
  factory $LyricsCopyWith(Lyrics value, $Res Function(Lyrics) _then) = _$LyricsCopyWithImpl;
@useResult
$Res call({
 List<LyricLine> lines, Duration offset, String? source, double? matchScore
});




}
/// @nodoc
class _$LyricsCopyWithImpl<$Res>
    implements $LyricsCopyWith<$Res> {
  _$LyricsCopyWithImpl(this._self, this._then);

  final Lyrics _self;
  final $Res Function(Lyrics) _then;

/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lines = null,Object? offset = null,Object? source = freezed,Object? matchScore = freezed,}) {
  return _then(Lyrics(
lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<LyricLine>,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as Duration,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,matchScore: freezed == matchScore ? _self.matchScore : matchScore // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Lyrics].
extension LyricsPatterns on Lyrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lyrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lyrics value)  $default,){
final _that = this;
switch (_that) {
case _Lyrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lyrics value)?  $default,){
final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LyricLine> lines,  Duration offset,  String? source,  double? matchScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
return $default(_that.lines,_that.offset,_that.source,_that.matchScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LyricLine> lines,  Duration offset,  String? source,  double? matchScore)  $default,) {final _that = this;
switch (_that) {
case _Lyrics():
return $default(_that.lines,_that.offset,_that.source,_that.matchScore);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LyricLine> lines,  Duration offset,  String? source,  double? matchScore)?  $default,) {final _that = this;
switch (_that) {
case _Lyrics() when $default != null:
return $default(_that.lines,_that.offset,_that.source,_that.matchScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lyrics implements Lyrics {
  const _Lyrics({required  List<LyricLine> lines, this.offset = Duration.zero, this.source, this.matchScore}): _lines = lines;
  factory _Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);

/// 歌词行列表 (按 timestamp 升序)
 final  List<LyricLine> _lines;
/// 歌词行列表 (按 timestamp 升序)
@override List<LyricLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

/// 用户校准偏移 (默认 0)
@override@JsonKey() final  Duration offset;
/// 歌词来源 (lrclib / bilibili_cc / local)
@override final  String? source;
/// 匹配得分 (0-1)
@override final  double? matchScore;

/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LyricsCopyWith<_Lyrics> get copyWith => __$LyricsCopyWithImpl<_Lyrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LyricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lyrics&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.source, source) || other.source == source)&&(identical(other.matchScore, matchScore) || other.matchScore == matchScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_lines),offset,source,matchScore);

@override
String toString() {
  return 'Lyrics(lines: $lines, offset: $offset, source: $source, matchScore: $matchScore)';
}


}

/// @nodoc
abstract mixin class _$LyricsCopyWith<$Res> implements $LyricsCopyWith<$Res> {
  factory _$LyricsCopyWith(_Lyrics value, $Res Function(_Lyrics) _then) = __$LyricsCopyWithImpl;
@override @useResult
$Res call({
 List<LyricLine> lines, Duration offset, String? source, double? matchScore
});




}
/// @nodoc
class __$LyricsCopyWithImpl<$Res>
    implements _$LyricsCopyWith<$Res> {
  __$LyricsCopyWithImpl(this._self, this._then);

  final _Lyrics _self;
  final $Res Function(_Lyrics) _then;

/// Create a copy of Lyrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lines = null,Object? offset = null,Object? source = freezed,Object? matchScore = freezed,}) {
  return _then(_Lyrics(
lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<LyricLine>,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as Duration,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,matchScore: freezed == matchScore ? _self.matchScore : matchScore // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
