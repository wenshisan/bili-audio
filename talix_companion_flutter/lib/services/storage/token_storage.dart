import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Token 持久化存储 (基于 SharedPreferences)
///
/// 保存:
/// - accessToken:  登录后获取的 JWT
/// - refreshToken: 用于刷新 accessToken
/// - userId:       当前登录用户 ID
/// - deviceId:     设备唯一标识 (APP 启动时生成,终身不变)
///
/// 桌面端 SharedPreferences 实际落到 JSON 文件
/// %APPDATA%\com.talix.companion\... (Windows) / ~/Library/Containers/... (macOS)
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _kAccessToken = 'auth.access_token';
  static const _kRefreshToken = 'auth.refresh_token';
  static const _kUserId = 'auth.user_id';
  static const _kDeviceId = 'device.id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ============== access token ==============

  Future<String?> getAccessToken() async {
    final p = await _ensure();
    return p.getString(_kAccessToken);
  }

  Future<void> setAccessToken(String token) async {
    final p = await _ensure();
    await p.setString(_kAccessToken, token);
  }

  // ============== refresh token ==============

  Future<String?> getRefreshToken() async {
    final p = await _ensure();
    return p.getString(_kRefreshToken);
  }

  Future<void> setRefreshToken(String token) async {
    final p = await _ensure();
    await p.setString(_kRefreshToken, token);
  }

  // ============== user id ==============

  Future<int?> getUserId() async {
    final p = await _ensure();
    return p.getInt(_kUserId);
  }

  Future<void> setUserId(int id) async {
    final p = await _ensure();
    await p.setInt(_kUserId, id);
  }

  // ============== device id (终身不变) ==============

  /// 读取本机设备 ID;不存在则生成一个并落盘
  Future<String> getOrCreateDeviceId() async {
    final p = await _ensure();
    var id = p.getString(_kDeviceId);
    if (id == null || id.isEmpty) {
      // 形如 "talix-172xxxx-yyyy" 的可读 ID
      final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final rand = (DateTime.now().microsecondsSinceEpoch & 0xFFFF).toRadixString(36);
      id = 'talix-$ts-$rand';
      await p.setString(_kDeviceId, id);
    }
    return id;
  }

  // ============== 全部登录态 ==============

  Future<void> clear() async {
    final p = await _ensure();
    await p.remove(_kAccessToken);
    await p.remove(_kRefreshToken);
    await p.remove(_kUserId);
    // deviceId 保留,设备标识终身不变
  }
}
