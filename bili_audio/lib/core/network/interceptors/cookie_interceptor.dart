import 'package:dio/dio.dart';

import '../buvid_manager.dart';
import '../../storage/secure_store.dart';

/// Cookie 拦截器 (M2.1): 注入登录 Cookie + buvid3/4
class CookieInterceptor extends Interceptor {
  CookieInterceptor(this._store, this._buvidManager);

  final SecureStore _store;
  final BuvidManager _buvidManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final parts = <String>[];

    // 登录 Cookie
    final cookies = await _store.readCookies();
    if (cookies != null && cookies.isNotEmpty) {
      parts.add(cookies);
    }

    // buvid (除非请求明确跳过)
    if (options.extra['skip_buvid'] != true) {
      final (b3, b4) = await _buvidManager.get();
      parts.add('buvid3=$b3; buvid4=$b4');
    }

    if (parts.isNotEmpty) {
      options.headers['Cookie'] = parts.join('; ');
    }

    handler.next(options);
  }
}
