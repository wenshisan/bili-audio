import 'package:flutter/material.dart';

import '../services/api/api_client.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_toast.dart';
import 'app_logger.dart';
import 'force_logout.dart';
import 'root_navigator.dart';

/// 全局会话失效处理 — 任何接口返回"未登录 / 登录过期"时清态并跳登录页
///
/// 检测在 [ApiClient] 的拦截器里做 (services 层, 不依赖 UI);
/// 这里只负责"收到通知后干什么":
///   1. [AuthViewModel.forceLogout] 清 token + 内存态 (不再调 /auth/logout, 反正必然 401)
///   2. [goToLoginScreen] 用 rootNavigatorKey 清栈强切 LoginScreen
///   3. Toast 提示"登录已过期，请重新登录"
///
/// 在 [installSessionExpiryHandler] 里注册, main() 启动时调用一次即可。
class SessionExpiry {
  SessionExpiry._();

  /// 正在处理中 — 防止并发请求同时 401 时重复跳转 / 弹多个 toast
  static bool _handling = false;

  /// 处理一次未授权事件
  static Future<void> handle(AuthViewModel auth, UnauthorizedInfo info) async {
    if (_handling) {
      AppLogger.d('SessionExpiry: 已在处理中, 忽略 $info', 'auth');
      return;
    }
    // 已经是未登录态说明刚刚才踢过 (或本来就在登录页), 不重复打扰
    if (!auth.isLoggedIn) {
      AppLogger.d('SessionExpiry: 当前已是未登录态, 忽略 $info', 'auth');
      return;
    }
    _handling = true;
    AppLogger.w('SessionExpiry: 会话失效, 强制回登录页 — $info', 'auth');
    try {
      // 先弹 toast: AppToast 用 rootOverlay, 路由切换后仍可见
      _showExpiredToast(info.msg);
      await auth.forceLogout();
      goToLoginScreen(reason: 'SessionExpiry');
    } finally {
      _handling = false;
    }
  }

  static void _showExpiredToast(String? msg) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      AppLogger.w('SessionExpiry: 无 context, 跳过 toast', 'auth');
      return;
    }
    // 后端 msg 若是已知 i18n key, 用 translateError 得到更准确的中文
    // (例如改密导致失效会提示"由于密码已修改…"); 否则用通用文案。
    final translated = (msg == null || msg.isEmpty)
        ? null
        : AppToast.translateError(msg);
    final text = (translated == null || translated == msg)
        ? '登录已过期，请重新登录'
        : translated;
    AppToast.show(ctx, text);
  }
}

/// 把会话失效处理挂到 [ApiClient.onUnauthorized] 上
///
/// [auth] 传全局唯一的 AuthViewModel 实例 (main() 里 Provider 创建的那个)。
void installSessionExpiryHandler(AuthViewModel auth) {
  ApiClient.onUnauthorized = (info) {
    // 拦截器回调在 Dio 的响应处理链里, 可能处于 build/绘制阶段;
    // 用 addPostFrameCallback 推到帧末再动路由, 避免 setState during build。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SessionExpiry.handle(auth, info);
    });
  };
  AppLogger.i('installSessionExpiryHandler: ApiClient.onUnauthorized 已注册', 'auth');
}
