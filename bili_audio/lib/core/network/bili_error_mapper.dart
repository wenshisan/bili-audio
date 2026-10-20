import '../../domain/entities/app_error.dart';

/// B 站业务错误码 (M2.1)
abstract final class BiliCode {
  static const int ok = 0;
  static const int needLogin = -101;
  static const int forbidden = -403;
  static const int notFound = -404;
  static const int riskControl = -412;
  static const int wbiInvalid = -352;
  static const int videoNotFound = 62002;
  static const int copyright = 87008;
}

/// 将 B 站响应中的 `code` 映射为 [AppError]
AppError mapBiliCode(int code, [String? message]) {
  switch (code) {
    case BiliCode.needLogin:
    case BiliCode.forbidden:
      return const AppError.needLogin();
    case BiliCode.riskControl:
    case BiliCode.wbiInvalid:
      return AppError.riskControl(message: message);
    case BiliCode.notFound:
    case BiliCode.videoNotFound:
      return const AppError.notFound();
    case BiliCode.copyright:
      return const AppError.copyright();
    default:
      return AppError.unknown(message: 'bili code $code: ${message ?? ''}');
  }
}
