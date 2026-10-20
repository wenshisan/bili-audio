import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// 应用错误类型 (M1.1)
///
/// 用于统一错误处理和用户提示。
@freezed
sealed class AppError with _$AppError {
  /// 网络错误
  const factory AppError.network({
    required String message,
    Object? cause,
  }) = NetworkError;

  /// 需要登录
  const factory AppError.needLogin() = NeedLoginError;

  /// 风控 (-412)
  const factory AppError.riskControl({
    String? message,
  }) = RiskControlError;

  /// 版权限制
  const factory AppError.copyright() = CopyrightError;

  /// 未找到
  const factory AppError.notFound() = NotFoundError;

  /// 未知错误
  const factory AppError.unknown({
    required String message,
    Object? cause,
    StackTrace? stackTrace,
  }) = UnknownError;
}
