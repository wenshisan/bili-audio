import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// Result 类型 (M1.1)
///
/// 用于表示可能失败的操作结果，替代抛异常。
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Object error) = Failure<T>;

  const Result._();

  /// 是否成功
  bool get isSuccess => this is Success<T>;

  /// 是否失败
  bool get isFailure => this is Failure<T>;

  /// 获取成功值，失败时返回 null
  T? get valueOrNull => switch (this) {
        Success(value: final v) => v,
        Failure() => null,
      };

  /// 获取错误，成功时返回 null
  Object? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final e) => e,
      };

  /// 映射成功值
  Result<R> map<R>(R Function(T) transform) => switch (this) {
        Success(value: final v) => Result.success(transform(v)),
        Failure(error: final e) => Result.failure(e),
      };

  /// 异步映射成功值
  Future<Result<R>> mapAsync<R>(Future<R> Function(T) transform) async =>
      switch (this) {
        Success(value: final v) => Result.success(await transform(v)),
        Failure(error: final e) => Result.failure(e),
      };

  /// flatMap
  Result<R> flatMap<R>(Result<R> Function(T) transform) => switch (this) {
        Success(value: final v) => transform(v),
        Failure(error: final e) => Result.failure(e),
      };
}
