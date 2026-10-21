import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

/// 记录 B 站请求的路径、脱敏查询参数、耗时和响应摘要。
///
/// 不记录 Cookie / SESSDATA，也不展开播放地址。
class HttpLogInterceptor extends Interceptor {
  static const _startedKey = 'log_started_us';
  static const _errorLoggedKey = 'log_error_done';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedKey] = DateTime.now().microsecondsSinceEpoch;
    final query = formatQuery(options.queryParameters);
    AppLogger.d(
      '→ ${options.method} ${options.path}${query.isEmpty ? '' : '?$query'}',
      tag: 'http',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final code = response.data is Map ? response.data['code'] : null;
    if (code is! int || code == 0) {
      AppLogger.d(
        _line(response.requestOptions, response.statusCode, response.data),
        tag: 'http',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    if (options.extra[_errorLoggedKey] == true) {
      handler.next(err);
      return;
    }
    options.extra[_errorLoggedKey] = true;
    final response = err.response;
    AppLogger.e(
      _line(options, response?.statusCode, response?.data, err.type),
      tag: 'http',
      error: err.error ?? err.message,
    );
    handler.next(err);
  }

  String _line(
    RequestOptions options,
    int? status,
    Object? body, [
    DioExceptionType? type,
  ]) {
    final started = options.extra[_startedKey];
    final ms = started is int
        ? (DateTime.now().microsecondsSinceEpoch - started) ~/ 1000
        : -1;
    final kind = type == null ? '' : ' ${type.name}';
    return '← ${options.method} ${options.path} '
        'status=${status ?? '-'} ${ms}ms$kind ${summarizeBody(body)}';
  }
}
