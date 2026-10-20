import 'package:dio/dio.dart';

/// 请求头拦截器 (M2.1): User-Agent / Referer / Origin
class HeaderInterceptor extends Interceptor {
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const _referer = 'https://www.bilibili.com';
  static const _origin = 'https://www.bilibili.com';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['User-Agent'] ??= _ua;
    options.headers['Referer'] ??= _referer;
    options.headers['Origin'] ??= _origin;
    handler.next(options);
  }
}
