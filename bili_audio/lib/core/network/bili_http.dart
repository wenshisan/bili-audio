import 'package:dio/dio.dart';

import 'wbi_key_manager.dart';
import 'buvid_manager.dart';
import 'risk_control_guard.dart';
import '../storage/secure_store.dart';
import 'interceptors/header_interceptor.dart';
import 'interceptors/cookie_interceptor.dart';
import 'interceptors/wbi_interceptor.dart';
import 'interceptors/rate_limit_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/risk_control_interceptor.dart';
import 'interceptors/error_mapper_interceptor.dart';
import 'interceptors/http_log_interceptor.dart';

/// Bilibili HTTP 客户端 (M2.1, M2.7)
///
/// 拦截器链: Header → Cookie → Wbi → RateLimit → Retry → RiskControl → ErrorMapper
class BiliHttp {
  BiliHttp({
    required SecureStore store,
    required BuvidManager buvidManager,
    required WbiKeyManager wbiKeyManager,
    RiskControlGuard? riskGuard,
    Dio? dio,
  }) : riskGuard = riskGuard ?? RiskControlGuard(),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: 'https://api.bilibili.com',
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 30),
               headers: {'Accept': 'application/json'},
             ),
           ) {
    _dio.interceptors.addAll([
      HeaderInterceptor(),
      CookieInterceptor(store, buvidManager),
      WbiInterceptor(wbiKeyManager, _dio),
      RateLimitInterceptor(),
      RetryInterceptor(_dio),
      RiskControlInterceptor(this.riskGuard, _dio),
      ErrorMapperInterceptor(),
      HttpLogInterceptor(),
    ]);
  }

  final Dio _dio;
  final RiskControlGuard riskGuard;

  Dio get dio => _dio;
}
