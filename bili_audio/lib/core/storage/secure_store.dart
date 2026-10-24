import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 敏感数据存储 (M0.3)
///
/// 只暴露 Cookie 与设备标识的读写, 便于在测试中替换为 [MemorySecureStore]。
abstract class SecureStore {
  Future<String?> readCookies();
  Future<void> writeCookies(String cookies);
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> clear();
}

class FlutterSecureStore implements SecureStore {
  // macOS 发行包是 ad-hoc 签名, 没有 Keychain Sharing。
  // Data Protection Keychain 会报 -34018 (缺少 entitlement),
  // 传统钥匙串在沙盒内读写不需要该 entitlement。
  FlutterSecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  static const _cookiesKey = 'bili_cookies';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readCookies() => _storage.read(key: _cookiesKey);

  @override
  Future<void> writeCookies(String cookies) =>
      _storage.write(key: _cookiesKey, value: cookies);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// 清除登录 Cookie (保留设备标识 buvid)
  @override
  Future<void> clear() => _storage.delete(key: _cookiesKey);
}

class MemorySecureStore implements SecureStore {
  final Map<String, String> data = {};
  static const _cookiesKey = 'bili_cookies';

  @override
  Future<String?> readCookies() async => data[_cookiesKey];

  @override
  Future<void> writeCookies(String cookies) async =>
      data[_cookiesKey] = cookies;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> clear() async => data.remove(_cookiesKey);
}
