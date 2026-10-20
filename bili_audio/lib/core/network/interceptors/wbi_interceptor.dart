import 'package:dio/dio.dart';

import '../wbi.dart';
import '../wbi_key_manager.dart';
import '../bili_error_mapper.dart';

/// WBI 签名拦截器 (M2.1)
///
/// 请求 extra 中设置 `wbi: true` 时触发签名; -352/-403 时刷新 key 并重试一次。
class WbiInterceptor extends Interceptor {
  WbiInterceptor(this._keyManager, this._dio, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final WbiKeyManager _keyManager;
  final Dio _dio;
  final DateTime Function() _clock;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['wbi'] != true) {
      return handler.next(options);
    }

    try {
      final mixinKey = await _keyManager.mixinKey();
      final wts = _clock().millisecondsSinceEpoch ~/ 1000;
      final signed = Wbi.sign(options.queryParameters, mixinKey, wts: wts);
      options.queryParameters = signed;
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'WBI sign failed: $e',
          type: DioExceptionType.unknown,
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
    final code = err.response?.data?['code'];
    if ((code == BiliCode.wbiInvalid || code == BiliCode.forbidden) &&
        err.requestOptions.extra['wbi_retry'] != true) {
      _keyManager.invalidate();
      err.requestOptions.extra['wbi_retry'] = true;

      try {
        final res = await _dio.fetch(err.requestOptions);
        return handler.resolve(res);
      } catch (e) {
        return handler.next(err);
      }
    }

    handler.next(err);
  }
}
