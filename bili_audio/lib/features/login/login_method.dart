import 'dart:io';

import 'package:flutter/foundation.dart';

enum LoginMethod { web, qr }

/// Android / iOS 走网页登录。桌面端仍用扫码。
bool loginPlatformIsMobile() {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// 手机和平板默认打开网页登录。
///
/// 同一台设备不方便扫描自己屏幕上的二维码。网页里可以用短信、密码等方式登录，
/// 再从页面读取登录凭证。
LoginMethod defaultLoginMethod({required bool mobile}) =>
    mobile ? LoginMethod.web : LoginMethod.qr;
