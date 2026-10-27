import 'package:flutter/services.dart';

import '../../data/bili/bili_login_api.dart';

/// 从本机网页容器读取登录 Cookie。凭证不离开这台设备。
abstract class LoginCookieSource {
  Future<Map<String, String>> read();
  Future<void> clear();
}

class PlatformLoginCookieSource implements LoginCookieSource {
  const PlatformLoginCookieSource();

  static const channel = MethodChannel('bili_audio/login_cookies');

  @override
  Future<Map<String, String>> read() async {
    final header = await channel.invokeMethod<String>('read');
    return BiliLoginApi.parseCookieHeader(header ?? '');
  }

  @override
  Future<void> clear() async {
    await channel.invokeMethod<void>('clear');
  }
}
