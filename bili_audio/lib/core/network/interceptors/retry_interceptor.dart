import 'dart:math';
import 'package:dio/dio.dart';

/// 重试拦截器 (M2.1): 网络错误指数退避，最多 3 次
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxRetries = 3, Random? random})
      : _random = random ?? Random();

  final Dio _dio;
  final int maxRetries;
  final Random _random;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempt = err.requestOptions.extra['retry_attempt'] as int? ?? 0;
    if (attempt >= maxRetries) {
      return handler.next(err);
    }

    final delay = _backoffDelay(attempt);
    await Future.delayed(delay);

    err.requestOptions.extra['retry_attempt'] = attempt + 1;

    try {
      final res = await _dio.fetch(err.requestOptions);
      return handler.resolve(res);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }

  Duration _backoffDelay(int attempt) {
    final baseMs = 200 * (1 << attempt); // 200ms, 400ms, 800ms
    final jitter = _random.nextInt(100);
    return Duration(milliseconds: baseMs + jitter);
  }
}
