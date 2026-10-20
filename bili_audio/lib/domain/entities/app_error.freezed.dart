// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppError {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppError()';
}


}

/// @nodoc
class $AppErrorCopyWith<$Res>  {
$AppErrorCopyWith(AppError _, $Res Function(AppError) __);
}


/// Adds pattern-matching-related methods to [AppError].
extension AppErrorPatterns on AppError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkError value)?  network,TResult Function( NeedLoginError value)?  needLogin,TResult Function( RiskControlError value)?  riskControl,TResult Function( CopyrightError value)?  copyright,TResult Function( NotFoundError value)?  notFound,TResult Function( UnknownError value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network(_that);case NeedLoginError() when needLogin != null:
return needLogin(_that);case RiskControlError() when riskControl != null:
return riskControl(_that);case CopyrightError() when copyright != null:
return copyright(_that);case NotFoundError() when notFound != null:
return notFound(_that);case UnknownError() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkError value)  network,required TResult Function( NeedLoginError value)  needLogin,required TResult Function( RiskControlError value)  riskControl,required TResult Function( CopyrightError value)  copyright,required TResult Function( NotFoundError value)  notFound,required TResult Function( UnknownError value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkError():
return network(_that);case NeedLoginError():
return needLogin(_that);case RiskControlError():
return riskControl(_that);case CopyrightError():
return copyright(_that);case NotFoundError():
return notFound(_that);case UnknownError():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkError value)?  network,TResult? Function( NeedLoginError value)?  needLogin,TResult? Function( RiskControlError value)?  riskControl,TResult? Function( CopyrightError value)?  copyright,TResult? Function( NotFoundError value)?  notFound,TResult? Function( UnknownError value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network(_that);case NeedLoginError() when needLogin != null:
return needLogin(_that);case RiskControlError() when riskControl != null:
return riskControl(_that);case CopyrightError() when copyright != null:
return copyright(_that);case NotFoundError() when notFound != null:
return notFound(_that);case UnknownError() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message,  Object? cause)?  network,TResult Function()?  needLogin,TResult Function( String? message)?  riskControl,TResult Function()?  copyright,TResult Function()?  notFound,TResult Function( String message,  Object? cause,  StackTrace? stackTrace)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network(_that.message,_that.cause);case NeedLoginError() when needLogin != null:
return needLogin();case RiskControlError() when riskControl != null:
return riskControl(_that.message);case CopyrightError() when copyright != null:
return copyright();case NotFoundError() when notFound != null:
return notFound();case UnknownError() when unknown != null:
return unknown(_that.message,_that.cause,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message,  Object? cause)  network,required TResult Function()  needLogin,required TResult Function( String? message)  riskControl,required TResult Function()  copyright,required TResult Function()  notFound,required TResult Function( String message,  Object? cause,  StackTrace? stackTrace)  unknown,}) {final _that = this;
switch (_that) {
case NetworkError():
return network(_that.message,_that.cause);case NeedLoginError():
return needLogin();case RiskControlError():
return riskControl(_that.message);case CopyrightError():
return copyright();case NotFoundError():
return notFound();case UnknownError():
return unknown(_that.message,_that.cause,_that.stackTrace);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message,  Object? cause)?  network,TResult? Function()?  needLogin,TResult? Function( String? message)?  riskControl,TResult? Function()?  copyright,TResult? Function()?  notFound,TResult? Function( String message,  Object? cause,  StackTrace? stackTrace)?  unknown,}) {final _that = this;
switch (_that) {
case NetworkError() when network != null:
return network(_that.message,_that.cause);case NeedLoginError() when needLogin != null:
return needLogin();case RiskControlError() when riskControl != null:
return riskControl(_that.message);case CopyrightError() when copyright != null:
return copyright();case NotFoundError() when notFound != null:
return notFound();case UnknownError() when unknown != null:
return unknown(_that.message,_that.cause,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class NetworkError implements AppError {
  const NetworkError({required this.message, this.cause});
  

 final  String message;
 final  Object? cause;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkErrorCopyWith<NetworkError> get copyWith => _$NetworkErrorCopyWithImpl<NetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkError&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause));

@override
String toString() {
  return 'AppError.network(message: $message, cause: $cause)';
}


}

/// @nodoc
abstract mixin class $NetworkErrorCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $NetworkErrorCopyWith(NetworkError value, $Res Function(NetworkError) _then) = _$NetworkErrorCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause
});




}
/// @nodoc
class _$NetworkErrorCopyWithImpl<$Res>
    implements $NetworkErrorCopyWith<$Res> {
  _$NetworkErrorCopyWithImpl(this._self, this._then);

  final NetworkError _self;
  final $Res Function(NetworkError) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(NetworkError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: freezed == cause ? _self.cause : cause ,
  ));
}


}

/// @nodoc


class NeedLoginError implements AppError {
  const NeedLoginError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeedLoginError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppError.needLogin()';
}


}




/// @nodoc


class RiskControlError implements AppError {
  const RiskControlError({this.message});
  

 final  String? message;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RiskControlErrorCopyWith<RiskControlError> get copyWith => _$RiskControlErrorCopyWithImpl<RiskControlError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RiskControlError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppError.riskControl(message: $message)';
}


}

/// @nodoc
abstract mixin class $RiskControlErrorCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $RiskControlErrorCopyWith(RiskControlError value, $Res Function(RiskControlError) _then) = _$RiskControlErrorCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$RiskControlErrorCopyWithImpl<$Res>
    implements $RiskControlErrorCopyWith<$Res> {
  _$RiskControlErrorCopyWithImpl(this._self, this._then);

  final RiskControlError _self;
  final $Res Function(RiskControlError) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(RiskControlError(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CopyrightError implements AppError {
  const CopyrightError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CopyrightError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppError.copyright()';
}


}




/// @nodoc


class NotFoundError implements AppError {
  const NotFoundError();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotFoundError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppError.notFound()';
}


}




/// @nodoc


class UnknownError implements AppError {
  const UnknownError({required this.message, this.cause, this.stackTrace});
  

 final  String message;
 final  Object? cause;
 final  StackTrace? stackTrace;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownErrorCopyWith<UnknownError> get copyWith => _$UnknownErrorCopyWithImpl<UnknownError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownError&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.cause, cause)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(cause),stackTrace);

@override
String toString() {
  return 'AppError.unknown(message: $message, cause: $cause, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $UnknownErrorCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory $UnknownErrorCopyWith(UnknownError value, $Res Function(UnknownError) _then) = _$UnknownErrorCopyWithImpl;
@useResult
$Res call({
 String message, Object? cause, StackTrace? stackTrace
});




}
/// @nodoc
class _$UnknownErrorCopyWithImpl<$Res>
    implements $UnknownErrorCopyWith<$Res> {
  _$UnknownErrorCopyWithImpl(this._self, this._then);

  final UnknownError _self;
  final $Res Function(UnknownError) _then;

/// Create a copy of AppError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,Object? stackTrace = freezed,}) {
  return _then(UnknownError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: freezed == cause ? _self.cause : cause ,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}


}

// dart format on
