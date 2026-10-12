import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'app_logger.dart';
import 'root_navigator.dart';

/// 强制登出并跳到登录页 — 业务方 (改密/删号等) 收尾时调用
///
/// 步骤:
///   1) [AuthViewModel.forceLogout] — 清本地态 + notifyListeners (期望 AuthGate 切到 LoginScreen)
///   2) 兜底: 用 [rootNavigatorKey] pushAndRemoveUntil 强切到 LoginScreen
///
/// 第 2 步必须存在, 因为 Windows 桌面端在 _DesktopWindowShell 包裹下,
/// AuthGate 的 Consumer / addListener 都曾出现过 notifyListeners 触发不到 rebuild
/// 的情况 (用户改密后卡在原页面)。这里用 Navigator 直接覆盖整个栈, 保证无论
/// Provider 链路是否健康, 用户都能落到登录页。
Future<void> forceLogoutAndGoToLogin(AuthViewModel auth) async {
  AppLogger.i('forceLogoutAndGoToLogin: start', 'auth');
  try {
    await auth.forceLogout();
  } catch (e, st) {
    AppLogger.e('forceLogoutAndGoToLogin: forceLogout failed: $e', 'auth', e, st);
  }
  goToLoginScreen(reason: 'forceLogoutAndGoToLogin');
}

/// 正常登出并跳到登录页 — 用户主动点"退出登录"时调用
///
/// 与 [forceLogoutAndGoToLogin] 的区别: 这里走 [AuthViewModel.logout],
/// 会先请求后端 /auth/logout 让服务端作废 token, 再清本地态。
/// 后端失败不影响流程 (logout 内部已 try/catch), 本地态一定会被清掉,
/// 并且同样用 [goToLoginScreen] 兜底强切路由。
Future<void> logoutAndGoToLogin(AuthViewModel auth) async {
  AppLogger.i('logoutAndGoToLogin: start', 'auth');
  try {
    await auth.logout();
  } catch (e, st) {
    AppLogger.e('logoutAndGoToLogin: logout failed: $e', 'auth', e, st);
  }
  goToLoginScreen(reason: 'logoutAndGoToLogin');
}

/// 兜底强切: 用 [rootNavigatorKey] 把整个栈清空, push 一个全新的 LoginScreen
///
/// 即使 AuthGate 没能响应 notifyListeners, 用户也一定会落到登录页。
/// 已经在登录页时重复 push 也是安全的 (栈被清空, 只剩一个 LoginScreen)。
void goToLoginScreen({String reason = 'goToLoginScreen'}) {
  final nav = rootNavigatorKey.currentState;
  if (nav == null) {
    AppLogger.w(
      '$reason: rootNavigatorKey.currentState is null, cannot navigate',
      'auth',
    );
    return;
  }
  AppLogger.i('$reason: pushAndRemoveUntil → LoginScreen', 'auth');
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
