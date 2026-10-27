import 'package:bili_audio/features/login/login_method.dart';
import 'package:bili_audio/features/login/login_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('手机默认网页登录，桌面默认扫码', () {
    expect(defaultLoginMethod(mobile: true), LoginMethod.web);
    expect(defaultLoginMethod(mobile: false), LoginMethod.qr);
    expect(loginPlatformIsMobile(), isFalse);
  });

  test('登录页只打开哔哩哔哩和验证码域名', () {
    expect(
      biliLoginNavigationAllowed('https://passport.bilibili.com/login'),
      isTrue,
    );
    expect(
      biliLoginNavigationAllowed('https://static.geetest.com/captcha.js'),
      isTrue,
    );
    expect(
      biliLoginNavigationAllowed('https://static.geevisit.com/v4.js'),
      isTrue,
    );
    expect(biliLoginNavigationAllowed('http://www.bilibili.com/'), isTrue);
    expect(biliLoginNavigationAllowed('about:blank'), isTrue);
    expect(biliLoginNavigationAllowed('https://evil.com/login'), isFalse);
    expect(
      biliLoginNavigationAllowed('https://bilibili.com.evil.com/'),
      isFalse,
    );
    expect(biliLoginNavigationAllowed('javascript:alert(1)'), isFalse);
  });
}
