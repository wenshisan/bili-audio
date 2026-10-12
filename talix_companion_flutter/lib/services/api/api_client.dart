import 'package:dio/dio.dart';

import '../../config/env.dart';
import '../../utils/app_logger.dart';
import '../server_config_service.dart';
import '../storage/token_storage.dart';

/// 未授权事件的上下文 — 传给 [ApiClient.onUnauthorized] 供日志/文案使用
class UnauthorizedInfo {
  /// 触发未授权的请求路径
  final String path;
  final int? httpStatus;

  /// 业务码 (响应体 code 字段)
  final int? code;

  /// 后端原始 msg (可能是 i18n key, 如 `token.expired`)
  final String? msg;

  const UnauthorizedInfo({
    required this.path,
    this.httpStatus,
    this.code,
    this.msg,
  });

  @override
  String toString() =>
      'UnauthorizedInfo(path=$path, http=$httpStatus, code=$code, msg=$msg)';
}

/// 统一异常:业务错误 (code != 0) / HTTP 错误 / 网络错误
class ApiException implements Exception {
  final int? code;
  final String message;
  final int? httpStatus;

  const ApiException(this.message, {this.code, this.httpStatus});

  @override
  String toString() {
    if (code != null) return 'ApiException(code=$code, msg=$message)';
    if (httpStatus != null) return 'ApiException(http=$httpStatus, msg=$message)';
    return 'ApiException($message)';
  }
}

/// Dio 单例 (含全局拦截器)
///
/// 在构造时即订阅 [ServerConfigService], 当 [ServerConfigService.active] 变化时:
///   1. 同步更新 [Dio.options.baseUrl], 后续请求自动走新 baseUrl
///   2. 清空本地 [TokenStorage] (旧服务器签发的 token 在新服务器上不再可信,
///      强制用户重新登录更安全 — AuthViewModel 也会同步收到 isLoggedIn=false 并自动回 LoginScreen)
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  /// 全局未授权回调 — 任何接口返回"未登录 / 登录过期"时触发。
  ///
  /// 由 UI 层 (utils/session_expiry.dart 的 installSessionExpiryHandler) 注册,
  /// 内部负责清登录态 + 跳 LoginScreen。这里只做检测, 不 import 任何 UI/VM,
  /// 保持 services 层不反向依赖上层。
  static void Function(UnauthorizedInfo info)? onUnauthorized;

  /// 暴露给 main() / 任何想手动同步 baseUrl 的代码。
  /// 通常无需调用 — [ServerConfigService.setActive] 后会被自动回调。
  void syncBaseUrlFromConfig() {
    final newBase = AppEnv.apiBaseUrl;
    if (_dio.options.baseUrl != newBase) {
      _dio.options.baseUrl = newBase;
    }
  }

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json; charset=UTF-8',
        // 不自动抛错, 由拦截器统一处理
        validateStatus: (s) => s != null && s < 600,
      ),
    );

    // 公共 Header 拦截器: 注入 tenant / language / Private-Key / Authorization
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['tenant-id'] = AppEnv.tenantId;
        options.headers['Accept-Language'] = AppEnv.acceptLanguage;
        // DecryptAspect 要求所有涉及 @DecryptParams 的接口都带 Private-Key
        options.headers[AppEnv.privateKeyHeader] = AppEnv.serverPrivateKeyHex;
        // 携带 accessToken (若有)
        final token = await TokenStorage.instance.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = token;
        }
        handler.next(options);
      },
    ));

    // 未授权拦截器: 无论走 BaseApiService 还是直接用 dio (如 FormData 上传),
    // 只要响应里带"未登录 / 登录过期"信号, 就通知全局回调跳登录页。
    // 注意 validateStatus 放通了 <600, 所以 401 会走 onResponse 而非 onError;
    // 但网络层异常 (DioException 带 response) 仍可能走 onError, 两边都查。
    dio.interceptors.add(InterceptorsWrapper(
      onResponse: (resp, handler) {
        _checkUnauthorized(resp.requestOptions, resp.statusCode, resp.data);
        handler.next(resp);
      },
      onError: (e, handler) {
        _checkUnauthorized(
          e.requestOptions,
          e.response?.statusCode,
          e.response?.data,
        );
        handler.next(e);
      },
    ));

    // 监听服务器切换: 同步 baseUrl + 清空旧 token 强制重新登录
    ServerConfigService.instance.addListener(_onServerConfigChanged);

    return dio;
  }

  /// 判定一次响应是否代表"未登录 / 登录过期", 命中则触发 [onUnauthorized]
  void _checkUnauthorized(
    RequestOptions options,
    int? httpStatus,
    dynamic body,
  ) {
    final path = options.path;
    // 登录前就会调用的接口 (登录/注册/找回密码/发验证码) 天然可能返回 401 或
    // 各种 token 错误, 不能因此把用户从登录页"再踢一次", 直接跳过。
    if (isPreLoginPath(path)) return;

    int? bizCode;
    String? msg;
    if (body is Map) {
      bizCode = (body['code'] as num?)?.toInt();
      msg = body['msg'] as String?;
    }

    if (!isUnauthorized(httpStatus: httpStatus, bizCode: bizCode, msg: msg)) {
      return;
    }

    AppLogger.w(
      '未授权: path=$path http=$httpStatus code=$bizCode msg=$msg → 触发登出跳转',
      'api',
    );
    final cb = onUnauthorized;
    if (cb == null) {
      AppLogger.w('未授权: onUnauthorized 未注册, 无法跳转登录页', 'api');
      return;
    }
    cb(UnauthorizedInfo(path: path, httpStatus: httpStatus, code: bizCode, msg: msg));
  }

  /// 登录前接口 — 这些接口的 401 / token 错误不触发全局跳转
  ///
  /// 用户在登录页时本来就没有有效 token, 这些接口返回 401 属正常情况,
  /// 若也触发跳转会把用户从"忘记密码"等子流程里踢回登录首页。
  /// 路径与 [AuthApi] 中的常量一一对应 (用 contains 匹配, 忽略 /app-api 前缀)。
  static bool isPreLoginPath(String path) {
    const preLogin = [
      // 登录 / 注册 / 找回密码
      '/auth/email-login',
      '/auth/mobile-login',
      '/auth/sms-login',
      '/auth/register',
      '/auth/mobile-register',
      '/auth/forget-password',
      '/auth/reset-password',
      '/auth/send-sms-code',
      // 邮箱验证码 (注册 / 找回密码流程, 均在登录前)
      '/mail-send/',
      // 登出本身失败无需再跳 (调用方 logoutAndGoToLogin 已在做跳转)
      '/auth/logout',
    ];
    return preLogin.any(path.contains);
  }

  /// 未登录 / 登录过期判定 (静态, 便于单测与其他层复用)
  ///
  /// 命中任一条件即视为会话失效:
  ///   - HTTP 401
  ///   - 业务码 401 (yudao 框架 UNAUTHORIZED)
  ///   - msg 命中 token/session 类 i18n key 或中文文案
  static bool isUnauthorized({
    int? httpStatus,
    int? bizCode,
    String? msg,
  }) {
    if (httpStatus == 401) return true;
    if (bizCode == 401) return true;
    final m = msg?.trim();
    if (m == null || m.isEmpty) return false;
    const keys = {
      'token.expired',
      'token.invalid',
      'token.invalidated.password.change',
      'login.expired',
      'session.expire',
      'session.expired',
      'unauthorized',
      'account.not.login',
    };
    if (keys.contains(m)) return true;
    // 后端也可能直接返回中文/英文文案而非 i18n key
    return m.contains('未登录') ||
        m.contains('登录已过期') ||
        m.contains('登录状态无效') ||
        m.contains('账号未登录') ||
        m.contains('Token has been invalidated');
  }

  void _onServerConfigChanged() {
    syncBaseUrlFromConfig();
    // 切服务器后旧 token 在新服务器上不再有效, 清空以保证安全
    //  (不抛错, 不 await — 监听回调同步语义)
    TokenStorage.instance.clear();
  }
}
