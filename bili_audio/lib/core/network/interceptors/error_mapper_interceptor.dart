import 'package:dio/dio.dart';

import '../bili_error_mapper.dart';
import '../../../domain/entities/app_error.dart';

/// 错误映射拦截器 (M2.1): 将 Dio 异常与 B 站业务码映射为 [AppError]
class ErrorMapperInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final code = response.data?['code'];
    if (code is int && code != BiliCode.ok) {
      final message = response.data?['message'] as String?;
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: mapBiliCode(code, message),
          type: DioExceptionType.badResponse,
        ),
        // 让 WbiInterceptor.onError 有机会刷新 key 重试
        true,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final error = err.error;
    if (error is AppError) {
      return handler.next(err);
    }

    final code = err.response?.data?['code'];
    if (code is int && code != BiliCode.ok) {
      final message = err.response?.data?['message'] as String?;
      return handler.reject(err.copyWith(error: mapBiliCode(code, message)));
    }

    final appError = _mapDioException(err);
    handler.reject(err.copyWith(error: appError));
  }

  AppError _mapDioException(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        AppError.network(message: '网络连接超时或失败', cause: err),
      DioExceptionType.badResponse => AppError.network(
          message: 'HTTP ${err.response?.statusCode ?? "error"}',
          cause: err,
        ),
      _ => AppError.unknown(message: err.message ?? 'Unknown', cause: err),
    };
  }
}
