// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'title_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TitleRuleConfig {

 int get version; List<TitleRule> get rules;
/// Create a copy of TitleRuleConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleRuleConfigCopyWith<TitleRuleConfig> get copyWith => _$TitleRuleConfigCopyWithImpl<TitleRuleConfig>(this as TitleRuleConfig, _$identity);

  /// Serializes this TitleRuleConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleRuleConfig&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.rules, rules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(rules));

@override
String toString() {
  return 'TitleRuleConfig(version: $version, rules: $rules)';
}


}

/// @nodoc
abstract mixin class $TitleRuleConfigCopyWith<$Res>  {
  factory $TitleRuleConfigCopyWith(TitleRuleConfig value, $Res Function(TitleRuleConfig) _then) = _$TitleRuleConfigCopyWithImpl;
@useResult
$Res call({
 int version, List<TitleRule> rules
});




}
/// @nodoc
class _$TitleRuleConfigCopyWithImpl<$Res>
    implements $TitleRuleConfigCopyWith<$Res> {
  _$TitleRuleConfigCopyWithImpl(this._self, this._then);

  final TitleRuleConfig _self;
  final $Res Function(TitleRuleConfig) _then;

/// Create a copy of TitleRuleConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? rules = null,}) {
  return _then(TitleRuleConfig(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<TitleRule>,
  ));
}

}


/// Adds pattern-matching-related methods to [TitleRuleConfig].
extension TitleRuleConfigPatterns on TitleRuleConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TitleRuleConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TitleRuleConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TitleRuleConfig value)  $default,){
final _that = this;
switch (_that) {
case _TitleRuleConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TitleRuleConfig value)?  $default,){
final _that = this;
switch (_that) {
case _TitleRuleConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  List<TitleRule> rules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TitleRuleConfig() when $default != null:
return $default(_that.version,_that.rules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  List<TitleRule> rules)  $default,) {final _that = this;
switch (_that) {
case _TitleRuleConfig():
return $default(_that.version,_that.rules);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  List<TitleRule> rules)?  $default,) {final _that = this;
switch (_that) {
case _TitleRuleConfig() when $default != null:
return $default(_that.version,_that.rules);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TitleRuleConfig implements TitleRuleConfig {
  const _TitleRuleConfig({required this.version, required  List<TitleRule> rules}): _rules = rules;
  factory _TitleRuleConfig.fromJson(Map<String, dynamic> json) => _$TitleRuleConfigFromJson(json);

@override final  int version;
 final  List<TitleRule> _rules;
@override List<TitleRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}


/// Create a copy of TitleRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TitleRuleConfigCopyWith<_TitleRuleConfig> get copyWith => __$TitleRuleConfigCopyWithImpl<_TitleRuleConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TitleRuleConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TitleRuleConfig&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._rules, _rules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(_rules));

@override
String toString() {
  return 'TitleRuleConfig(version: $version, rules: $rules)';
}


}

/// @nodoc
abstract mixin class _$TitleRuleConfigCopyWith<$Res> implements $TitleRuleConfigCopyWith<$Res> {
  factory _$TitleRuleConfigCopyWith(_TitleRuleConfig value, $Res Function(_TitleRuleConfig) _then) = __$TitleRuleConfigCopyWithImpl;
@override @useResult
$Res call({
 int version, List<TitleRule> rules
});




}
/// @nodoc
class __$TitleRuleConfigCopyWithImpl<$Res>
    implements _$TitleRuleConfigCopyWith<$Res> {
  __$TitleRuleConfigCopyWithImpl(this._self, this._then);

  final _TitleRuleConfig _self;
  final $Res Function(_TitleRuleConfig) _then;

/// Create a copy of TitleRuleConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? rules = null,}) {
  return _then(_TitleRuleConfig(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<TitleRule>,
  ));
}


}


/// @nodoc
mixin _$TitleRule {

 String get id; String get type; String get pattern; bool get enabled; String? get flag; String? get order; String? get group; int get priority;
/// Create a copy of TitleRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleRuleCopyWith<TitleRule> get copyWith => _$TitleRuleCopyWithImpl<TitleRule>(this as TitleRule, _$identity);

  /// Serializes this TitleRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleRule&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.flag, flag) || other.flag == flag)&&(identical(other.order, order) || other.order == order)&&(identical(other.group, group) || other.group == group)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,pattern,enabled,flag,order,group,priority);

@override
String toString() {
  return 'TitleRule(id: $id, type: $type, pattern: $pattern, enabled: $enabled, flag: $flag, order: $order, group: $group, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $TitleRuleCopyWith<$Res>  {
  factory $TitleRuleCopyWith(TitleRule value, $Res Function(TitleRule) _then) = _$TitleRuleCopyWithImpl;
@useResult
$Res call({
 String id, String type, String pattern, bool enabled, String? flag, String? order, String? group, int priority
});




}
/// @nodoc
class _$TitleRuleCopyWithImpl<$Res>
    implements $TitleRuleCopyWith<$Res> {
  _$TitleRuleCopyWithImpl(this._self, this._then);

  final TitleRule _self;
  final $Res Function(TitleRule) _then;

/// Create a copy of TitleRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? pattern = null,Object? enabled = null,Object? flag = freezed,Object? order = freezed,Object? group = freezed,Object? priority = null,}) {
  return _then(TitleRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TitleRule].
extension TitleRulePatterns on TitleRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TitleRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TitleRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TitleRule value)  $default,){
final _that = this;
switch (_that) {
case _TitleRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TitleRule value)?  $default,){
final _that = this;
switch (_that) {
case _TitleRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String pattern,  bool enabled,  String? flag,  String? order,  String? group,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TitleRule() when $default != null:
return $default(_that.id,_that.type,_that.pattern,_that.enabled,_that.flag,_that.order,_that.group,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String pattern,  bool enabled,  String? flag,  String? order,  String? group,  int priority)  $default,) {final _that = this;
switch (_that) {
case _TitleRule():
return $default(_that.id,_that.type,_that.pattern,_that.enabled,_that.flag,_that.order,_that.group,_that.priority);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String pattern,  bool enabled,  String? flag,  String? order,  String? group,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _TitleRule() when $default != null:
return $default(_that.id,_that.type,_that.pattern,_that.enabled,_that.flag,_that.order,_that.group,_that.priority);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TitleRule implements TitleRule {
  const _TitleRule({required this.id, required this.type, required this.pattern, this.enabled = true, this.flag, this.order, this.group, this.priority = 0});
  factory _TitleRule.fromJson(Map<String, dynamic> json) => _$TitleRuleFromJson(json);

@override final  String id;
@override final  String type;
@override final  String pattern;
@override@JsonKey() final  bool enabled;
@override final  String? flag;
@override final  String? order;
@override final  String? group;
@override@JsonKey() final  int priority;

/// Create a copy of TitleRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TitleRuleCopyWith<_TitleRule> get copyWith => __$TitleRuleCopyWithImpl<_TitleRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TitleRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TitleRule&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.flag, flag) || other.flag == flag)&&(identical(other.order, order) || other.order == order)&&(identical(other.group, group) || other.group == group)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,pattern,enabled,flag,order,group,priority);

@override
String toString() {
  return 'TitleRule(id: $id, type: $type, pattern: $pattern, enabled: $enabled, flag: $flag, order: $order, group: $group, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$TitleRuleCopyWith<$Res> implements $TitleRuleCopyWith<$Res> {
  factory _$TitleRuleCopyWith(_TitleRule value, $Res Function(_TitleRule) _then) = __$TitleRuleCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String pattern, bool enabled, String? flag, String? order, String? group, int priority
});




}
/// @nodoc
class __$TitleRuleCopyWithImpl<$Res>
    implements _$TitleRuleCopyWith<$Res> {
  __$TitleRuleCopyWithImpl(this._self, this._then);

  final _TitleRule _self;
  final $Res Function(_TitleRule) _then;

/// Create a copy of TitleRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? pattern = null,Object? enabled = null,Object? flag = freezed,Object? order = freezed,Object? group = freezed,Object? priority = null,}) {
  return _then(_TitleRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CleanedTitle {

 String get name; String? get artist; List<String> get artistCandidates; Set<String> get flags; List<String> get appliedRuleIds;
/// Create a copy of CleanedTitle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CleanedTitleCopyWith<CleanedTitle> get copyWith => _$CleanedTitleCopyWithImpl<CleanedTitle>(this as CleanedTitle, _$identity);

  /// Serializes this CleanedTitle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CleanedTitle&&(identical(other.name, name) || other.name == name)&&(identical(other.artist, artist) || other.artist == artist)&&const DeepCollectionEquality().equals(other.artistCandidates, artistCandidates)&&const DeepCollectionEquality().equals(other.flags, flags)&&const DeepCollectionEquality().equals(other.appliedRuleIds, appliedRuleIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,artist,const DeepCollectionEquality().hash(artistCandidates),const DeepCollectionEquality().hash(flags),const DeepCollectionEquality().hash(appliedRuleIds));

@override
String toString() {
  return 'CleanedTitle(name: $name, artist: $artist, artistCandidates: $artistCandidates, flags: $flags, appliedRuleIds: $appliedRuleIds)';
}


}

/// @nodoc
abstract mixin class $CleanedTitleCopyWith<$Res>  {
  factory $CleanedTitleCopyWith(CleanedTitle value, $Res Function(CleanedTitle) _then) = _$CleanedTitleCopyWithImpl;
@useResult
$Res call({
 String name, String? artist, List<String> artistCandidates, Set<String> flags, List<String> appliedRuleIds
});




}
/// @nodoc
class _$CleanedTitleCopyWithImpl<$Res>
    implements $CleanedTitleCopyWith<$Res> {
  _$CleanedTitleCopyWithImpl(this._self, this._then);

  final CleanedTitle _self;
  final $Res Function(CleanedTitle) _then;

/// Create a copy of CleanedTitle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? artist = freezed,Object? artistCandidates = null,Object? flags = null,Object? appliedRuleIds = null,}) {
  return _then(CleanedTitle(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,artistCandidates: null == artistCandidates ? _self.artistCandidates : artistCandidates // ignore: cast_nullable_to_non_nullable
as List<String>,flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as Set<String>,appliedRuleIds: null == appliedRuleIds ? _self.appliedRuleIds : appliedRuleIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CleanedTitle].
extension CleanedTitlePatterns on CleanedTitle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CleanedTitle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CleanedTitle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CleanedTitle value)  $default,){
final _that = this;
switch (_that) {
case _CleanedTitle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CleanedTitle value)?  $default,){
final _that = this;
switch (_that) {
case _CleanedTitle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? artist,  List<String> artistCandidates,  Set<String> flags,  List<String> appliedRuleIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CleanedTitle() when $default != null:
return $default(_that.name,_that.artist,_that.artistCandidates,_that.flags,_that.appliedRuleIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? artist,  List<String> artistCandidates,  Set<String> flags,  List<String> appliedRuleIds)  $default,) {final _that = this;
switch (_that) {
case _CleanedTitle():
return $default(_that.name,_that.artist,_that.artistCandidates,_that.flags,_that.appliedRuleIds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? artist,  List<String> artistCandidates,  Set<String> flags,  List<String> appliedRuleIds)?  $default,) {final _that = this;
switch (_that) {
case _CleanedTitle() when $default != null:
return $default(_that.name,_that.artist,_that.artistCandidates,_that.flags,_that.appliedRuleIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CleanedTitle implements CleanedTitle {
  const _CleanedTitle({required this.name, this.artist,  List<String> artistCandidates = const [],  Set<String> flags = const {},  List<String> appliedRuleIds = const []}): _artistCandidates = artistCandidates,_flags = flags,_appliedRuleIds = appliedRuleIds;
  factory _CleanedTitle.fromJson(Map<String, dynamic> json) => _$CleanedTitleFromJson(json);

@override final  String name;
@override final  String? artist;
 final  List<String> _artistCandidates;
@override@JsonKey() List<String> get artistCandidates {
  if (_artistCandidates is EqualUnmodifiableListView) return _artistCandidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artistCandidates);
}

 final  Set<String> _flags;
@override@JsonKey() Set<String> get flags {
  if (_flags is EqualUnmodifiableSetView) return _flags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_flags);
}

 final  List<String> _appliedRuleIds;
@override@JsonKey() List<String> get appliedRuleIds {
  if (_appliedRuleIds is EqualUnmodifiableListView) return _appliedRuleIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appliedRuleIds);
}


/// Create a copy of CleanedTitle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CleanedTitleCopyWith<_CleanedTitle> get copyWith => __$CleanedTitleCopyWithImpl<_CleanedTitle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CleanedTitleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CleanedTitle&&(identical(other.name, name) || other.name == name)&&(identical(other.artist, artist) || other.artist == artist)&&const DeepCollectionEquality().equals(other._artistCandidates, _artistCandidates)&&const DeepCollectionEquality().equals(other._flags, _flags)&&const DeepCollectionEquality().equals(other._appliedRuleIds, _appliedRuleIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,artist,const DeepCollectionEquality().hash(_artistCandidates),const DeepCollectionEquality().hash(_flags),const DeepCollectionEquality().hash(_appliedRuleIds));

@override
String toString() {
  return 'CleanedTitle(name: $name, artist: $artist, artistCandidates: $artistCandidates, flags: $flags, appliedRuleIds: $appliedRuleIds)';
}


}

/// @nodoc
abstract mixin class _$CleanedTitleCopyWith<$Res> implements $CleanedTitleCopyWith<$Res> {
  factory _$CleanedTitleCopyWith(_CleanedTitle value, $Res Function(_CleanedTitle) _then) = __$CleanedTitleCopyWithImpl;
@override @useResult
$Res call({
 String name, String? artist, List<String> artistCandidates, Set<String> flags, List<String> appliedRuleIds
});




}
/// @nodoc
class __$CleanedTitleCopyWithImpl<$Res>
    implements _$CleanedTitleCopyWith<$Res> {
  __$CleanedTitleCopyWithImpl(this._self, this._then);

  final _CleanedTitle _self;
  final $Res Function(_CleanedTitle) _then;

/// Create a copy of CleanedTitle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? artist = freezed,Object? artistCandidates = null,Object? flags = null,Object? appliedRuleIds = null,}) {
  return _then(_CleanedTitle(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: freezed == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String?,artistCandidates: null == artistCandidates ? _self._artistCandidates : artistCandidates // ignore: cast_nullable_to_non_nullable
as List<String>,flags: null == flags ? _self._flags : flags // ignore: cast_nullable_to_non_nullable
as Set<String>,appliedRuleIds: null == appliedRuleIds ? _self._appliedRuleIds : appliedRuleIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
