// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchResult {

 String get bvid; String get title; String get cleanTitle; int get duration; String get cover; String get author; int get play; String? get description; bool? get filtered;
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultCopyWith<SearchResult> get copyWith => _$SearchResultCopyWithImpl<SearchResult>(this as SearchResult, _$identity);

  /// Serializes this SearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResult&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.cleanTitle, cleanTitle) || other.cleanTitle == cleanTitle)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.author, author) || other.author == author)&&(identical(other.play, play) || other.play == play)&&(identical(other.description, description) || other.description == description)&&(identical(other.filtered, filtered) || other.filtered == filtered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,title,cleanTitle,duration,cover,author,play,description,filtered);

@override
String toString() {
  return 'SearchResult(bvid: $bvid, title: $title, cleanTitle: $cleanTitle, duration: $duration, cover: $cover, author: $author, play: $play, description: $description, filtered: $filtered)';
}


}

/// @nodoc
abstract mixin class $SearchResultCopyWith<$Res>  {
  factory $SearchResultCopyWith(SearchResult value, $Res Function(SearchResult) _then) = _$SearchResultCopyWithImpl;
@useResult
$Res call({
 String bvid, String title, String cleanTitle, int duration, String cover, String author, int play, String? description, bool? filtered
});




}
/// @nodoc
class _$SearchResultCopyWithImpl<$Res>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._self, this._then);

  final SearchResult _self;
  final $Res Function(SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bvid = null,Object? title = null,Object? cleanTitle = null,Object? duration = null,Object? cover = null,Object? author = null,Object? play = null,Object? description = freezed,Object? filtered = freezed,}) {
  return _then(SearchResult(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cleanTitle: null == cleanTitle ? _self.cleanTitle : cleanTitle // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,play: null == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,filtered: freezed == filtered ? _self.filtered : filtered // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResult].
extension SearchResultPatterns on SearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResult value)  $default,){
final _that = this;
switch (_that) {
case _SearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bvid,  String title,  String cleanTitle,  int duration,  String cover,  String author,  int play,  String? description,  bool? filtered)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.bvid,_that.title,_that.cleanTitle,_that.duration,_that.cover,_that.author,_that.play,_that.description,_that.filtered);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bvid,  String title,  String cleanTitle,  int duration,  String cover,  String author,  int play,  String? description,  bool? filtered)  $default,) {final _that = this;
switch (_that) {
case _SearchResult():
return $default(_that.bvid,_that.title,_that.cleanTitle,_that.duration,_that.cover,_that.author,_that.play,_that.description,_that.filtered);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bvid,  String title,  String cleanTitle,  int duration,  String cover,  String author,  int play,  String? description,  bool? filtered)?  $default,) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.bvid,_that.title,_that.cleanTitle,_that.duration,_that.cover,_that.author,_that.play,_that.description,_that.filtered);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResult implements SearchResult {
  const _SearchResult({required this.bvid, required this.title, required this.cleanTitle, required this.duration, required this.cover, required this.author, required this.play, this.description, this.filtered});
  factory _SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);

@override final  String bvid;
@override final  String title;
@override final  String cleanTitle;
@override final  int duration;
@override final  String cover;
@override final  String author;
@override final  int play;
@override final  String? description;
@override final  bool? filtered;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultCopyWith<_SearchResult> get copyWith => __$SearchResultCopyWithImpl<_SearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResult&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.cleanTitle, cleanTitle) || other.cleanTitle == cleanTitle)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.author, author) || other.author == author)&&(identical(other.play, play) || other.play == play)&&(identical(other.description, description) || other.description == description)&&(identical(other.filtered, filtered) || other.filtered == filtered));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bvid,title,cleanTitle,duration,cover,author,play,description,filtered);

@override
String toString() {
  return 'SearchResult(bvid: $bvid, title: $title, cleanTitle: $cleanTitle, duration: $duration, cover: $cover, author: $author, play: $play, description: $description, filtered: $filtered)';
}


}

/// @nodoc
abstract mixin class _$SearchResultCopyWith<$Res> implements $SearchResultCopyWith<$Res> {
  factory _$SearchResultCopyWith(_SearchResult value, $Res Function(_SearchResult) _then) = __$SearchResultCopyWithImpl;
@override @useResult
$Res call({
 String bvid, String title, String cleanTitle, int duration, String cover, String author, int play, String? description, bool? filtered
});




}
/// @nodoc
class __$SearchResultCopyWithImpl<$Res>
    implements _$SearchResultCopyWith<$Res> {
  __$SearchResultCopyWithImpl(this._self, this._then);

  final _SearchResult _self;
  final $Res Function(_SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bvid = null,Object? title = null,Object? cleanTitle = null,Object? duration = null,Object? cover = null,Object? author = null,Object? play = null,Object? description = freezed,Object? filtered = freezed,}) {
  return _then(_SearchResult(
bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cleanTitle: null == cleanTitle ? _self.cleanTitle : cleanTitle // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,play: null == play ? _self.play : play // ignore: cast_nullable_to_non_nullable
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,filtered: freezed == filtered ? _self.filtered : filtered // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$SearchPage {

 List<SearchResult> get items; int get page; int get pageSize; int get total; bool get hasMore;
/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPageCopyWith<SearchPage> get copyWith => _$SearchPageCopyWithImpl<SearchPage>(this as SearchPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,pageSize,total,hasMore);

@override
String toString() {
  return 'SearchPage(items: $items, page: $page, pageSize: $pageSize, total: $total, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $SearchPageCopyWith<$Res>  {
  factory $SearchPageCopyWith(SearchPage value, $Res Function(SearchPage) _then) = _$SearchPageCopyWithImpl;
@useResult
$Res call({
 List<SearchResult> items, int page, int pageSize, int total, bool hasMore
});




}
/// @nodoc
class _$SearchPageCopyWithImpl<$Res>
    implements $SearchPageCopyWith<$Res> {
  _$SearchPageCopyWithImpl(this._self, this._then);

  final SearchPage _self;
  final $Res Function(SearchPage) _then;

/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,Object? hasMore = null,}) {
  return _then(SearchPage(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SearchResult>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchPage].
extension SearchPagePatterns on SearchPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchPage value)  $default,){
final _that = this;
switch (_that) {
case _SearchPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchPage value)?  $default,){
final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchResult> items,  int page,  int pageSize,  int total,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchResult> items,  int page,  int pageSize,  int total,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _SearchPage():
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.hasMore);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchResult> items,  int page,  int pageSize,  int total,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _SearchPage() when $default != null:
return $default(_that.items,_that.page,_that.pageSize,_that.total,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc


class _SearchPage implements SearchPage {
  const _SearchPage({required  List<SearchResult> items, required this.page, required this.pageSize, required this.total, required this.hasMore}): _items = items;
  

 final  List<SearchResult> _items;
@override List<SearchResult> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int page;
@override final  int pageSize;
@override final  int total;
@override final  bool hasMore;

/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchPageCopyWith<_SearchPage> get copyWith => __$SearchPageCopyWithImpl<_SearchPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,pageSize,total,hasMore);

@override
String toString() {
  return 'SearchPage(items: $items, page: $page, pageSize: $pageSize, total: $total, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$SearchPageCopyWith<$Res> implements $SearchPageCopyWith<$Res> {
  factory _$SearchPageCopyWith(_SearchPage value, $Res Function(_SearchPage) _then) = __$SearchPageCopyWithImpl;
@override @useResult
$Res call({
 List<SearchResult> items, int page, int pageSize, int total, bool hasMore
});




}
/// @nodoc
class __$SearchPageCopyWithImpl<$Res>
    implements _$SearchPageCopyWith<$Res> {
  __$SearchPageCopyWithImpl(this._self, this._then);

  final _SearchPage _self;
  final $Res Function(_SearchPage) _then;

/// Create a copy of SearchPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? pageSize = null,Object? total = null,Object? hasMore = null,}) {
  return _then(_SearchPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SearchResult>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
