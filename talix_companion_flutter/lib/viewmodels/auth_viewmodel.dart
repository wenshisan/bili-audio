import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_api.dart';
import '../services/server_config_service.dart';
import '../services/storage/token_storage.dart';
import '../utils/app_logger.dart';
import '../utils/safe_change_notifier.dart';

// ============================================================
// 全局登录状态 (MVVM)
//
// 状态: isLoggedIn / userProfile / isBusy (登录中...)
// 持久化: token & userId 存到 TokenStorage (SharedPreferences),
//         启动时自动从本地恢复登录态
// 业务方:
//   - LoginScreen 邮箱密码登录 → loginByEmail
//   - LoginScreen 短信验证码登录 → loginBySms (如有)
//   - me_profile_screen 退出登录 → logout
//   - MainFrame 启动时根据 isLoggedIn 决定显示登录页还是主页
//
// 继承 SafeChangeNotifier: bootstrap() / loginByEmail / loginBySms 都是
// await 链,启动期或登出流程中如发生网络异常,finally 块的 notifyListeners()
// 由基类守护,避免 "used after disposed" 闪退。
// ============================================================
class AuthViewModel extends SafeChangeNotifier {
  bool _isLoggedIn = false;
  UserProfile? _userProfile;
  bool _isBusy = false;
  String? _lastError;

  bool get isLoggedIn => _isLoggedIn;
  UserProfile? get userProfile => _userProfile;
  bool get isBusy => _isBusy;
  String? get lastError => _lastError;

  final AuthApi _api = AuthApi.instance;
  final TokenStorage _storage = TokenStorage.instance;

  AuthViewModel() {
    // 监听服务器切换: 不调后端 logout (旧服务器可能已不可达),
    // 仅清空内存态 + 通知 listeners, AuthGate 会自动从 MainFrame 切回 LoginScreen。
    // 注意: TokenStorage 的清空由 ApiClient 的监听器负责, 这里只同步 UI 状态。
    ServerConfigService.instance.addListener(_onServerConfigChanged);
  }

  void _onServerConfigChanged() {
    if (!_isLoggedIn && _userProfile == null) return;
    _userProfile = null;
    _isLoggedIn = false;
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    ServerConfigService.instance.removeListener(_onServerConfigChanged);
    super.dispose();
  }

  /// 启动时调用: 读本地 token, 若存在则标记已登录 (同时异步拉取用户资料)
  Future<void> bootstrap() async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _isLoggedIn = true;
      notifyListeners();
      // 静默拉取资料,失败不退出登录
      try {
        await refreshProfile();
      } catch (e) {
        // 401 时由后续业务请求触发刷新流程
        AppLogger.w('bootstrap getUserProfile failed: $e', 'auth');
      }
    }
  }

  /// 邮箱密码登录
  Future<bool> loginByEmail({
    required String email,
    required String password,
  }) async {
    AppLogger.i(
      'loginByEmail: email=$email pwLen=${password.length}',
      'auth',
    );
    return _runAuthFlow(() async {
      final deviceId = await _storage.getOrCreateDeviceId();
      final resp = await _api.emailLogin(
        email: email,
        password: password,
        deviceId: deviceId,
      );
      await _persistTokens(resp);
    });
  }

  /// 手机号密码登录
  Future<bool> loginByMobile({
    required String mobile,
    required String password,
  }) async {
    AppLogger.i(
      'loginByMobile: mobile=$mobile pwLen=${password.length}',
      'auth',
    );
    return _runAuthFlow(() async {
      final deviceId = await _storage.getOrCreateDeviceId();
      final resp = await _api.mobileLogin(
        mobile: mobile,
        password: password,
        deviceId: deviceId,
      );
      await _persistTokens(resp);
    });
  }

  /// 短信验证码登录
  Future<bool> loginBySms({
    required String mobile,
    required String code,
    required String uuid,
  }) async {
    AppLogger.i(
      'loginBySms: mobile=$mobile codeLen=${code.length}',
      'auth',
    );
    return _runAuthFlow(() async {
      final deviceId = await _storage.getOrCreateDeviceId();
      final resp = await _api.smsLogin(
        mobile: mobile,
        code: code,
        uuid: uuid,
        deviceId: deviceId,
      );
      await _persistTokens(resp);
    });
  }

  /// 拉取用户资料
  Future<void> refreshProfile() async {
    _userProfile = await _api.getUserProfile();
    notifyListeners();
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (e) {
      // 即使后端登出失败,本地也要清空
      AppLogger.w('logout api failed: $e', 'auth');
    }
    await _storage.clear();
    _userProfile = null;
    _isLoggedIn = false;
    _lastError = null;
    notifyListeners();
  }

  /// 强制登出:跳过 /auth/logout 调用,直接清本地态 + 通知 AuthGate 跳转登录页
  ///
  /// 适用场景: 后端已经明确把当前 token 标记为失效 (例如改密成功、账号被删除),
  /// 此时再调 /auth/logout 必然 401,既浪费时间又容易触发拦截器副作用。
  /// 与 [logout] 的区别仅在第一步: 本方法不同步等待后端响应。
  Future<void> forceLogout() async {
    AppLogger.i('forceLogout: skipping /auth/logout, clearing local state', 'auth');
    debugPrint('[auth] forceLogout: clearing TokenStorage and flipping isLoggedIn=false');
    try {
      await _storage.clear();
      debugPrint('[auth] forceLogout: TokenStorage cleared');
    } catch (e, st) {
      AppLogger.e('forceLogout: _storage.clear failed', 'auth', e, st);
      // 即使清 storage 失败, 也要继续把内存态翻成未登录, 否则用户会卡死
    }
    _userProfile = null;
    _isLoggedIn = false;
    _lastError = null;
    debugPrint('[auth] forceLogout: notifyListeners() (expect AuthGate → LoginScreen)');
    notifyListeners();
  }

  /// 测试用: 强制标记登录 / 登出 (不调后端, 仅供开发自测)
  void debugForceState(bool loggedIn) {
    _isLoggedIn = loggedIn;
    notifyListeners();
  }

  // ============== helpers ==============

  Future<bool> _runAuthFlow(Future<void> Function() action) async {
    if (_isBusy) {
      AppLogger.w('auth flow skipped: already busy', 'auth');
      return false;
    }
    _setBusy(true);
    _lastError = null;
    try {
      await action();
      _isLoggedIn = true;
      AppLogger.i('login success', 'auth');
      // 登录后异步拉取资料 (失败也不影响登录态)
      try {
        await refreshProfile();
      } catch (e) {
        AppLogger.w('post-login refreshProfile failed: $e', 'auth');
      }
      return true;
    } on ApiException catch (e) {
      _lastError = e.message;
      AppLogger.w(
        'login failed (api): code=${e.code} http=${e.httpStatus} msg=${e.message}',
        'auth',
      );
      return false;
    } catch (e, st) {
      _lastError = e.toString();
      AppLogger.e('login failed (unknown)', 'auth', e, st);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _persistTokens(AuthLoginResp resp) async {
    await _storage.setAccessToken(resp.accessToken);
    await _storage.setRefreshToken(resp.refreshToken);
    if (resp.userId > 0) {
      await _storage.setUserId(resp.userId);
    }
  }

  void _setBusy(bool v) {
    _isBusy = v;
    notifyListeners();
  }
}
