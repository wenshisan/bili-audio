import 'package:dio/dio.dart';

import '../../../domain/entities/app_error.dart';
import '../../logging/app_logger.dart';
import '../bili_error_mapper.dart';
import '../risk_control_guard.dart';

/// 风控拦截器 (M2.7)
///
/// - 请求 extra `risk_guarded: true` 时, 冷却期内直接拒绝
/// - 收到 -412 时计数; 对 `risk_retry: true` 的请求退避 [backoff] 后重试一次
class RiskControlInterceptor extends Interceptor {
  RiskControlInterceptor(
    this._guard,
    this._dio, {
    this.backoff = const Duration(seconds: 2),
  });

  final RiskControlGuard _guard;
  final Dio _dio;
  final Duration backoff;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['risk_guarded'] == true && _guard.inCooldown) {
      AppLogger.w(
        'cooldown reject ${options.path} '
        'remaining=${_guard.remaining.inSeconds}s',
        tag: 'risk',
      );
      return handler.reject(
        DioException(
          requestOptions: options,
          error: AppError.riskControl(
            message: '请求过于频繁, 请 ${_guard.remaining.inSeconds} 秒后再试',
          ),
        ),
      );
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 读取业务错误码 (在 ErrorMapper 之前)
    final code = err.response?.data is Map
        ? (err.response!.data as Map)['code'] as int?
        : null;

    if (code != BiliCode.riskControl) return handler.next(err);

    final options = err.requestOptions;
    _guard.recordHit(options.path);

    final canRetry =
        options.extra['risk_retry'] == true &&
        options.extra['risk_retried'] != true &&
        !_guard.inCooldown;

    AppLogger.w(
      'hit ${options.path} code=$code retry=$canRetry '
      'cooldown=${_guard.inCooldown}',
      tag: 'risk',
    );

    if (!canRetry) return handler.next(err);

    await Future<void>.delayed(backoff);
    options.extra['risk_retried'] = true;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
