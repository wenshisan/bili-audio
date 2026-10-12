import 'package:flutter_test/flutter_test.dart';
import 'package:talix_companion/services/api/api_client.dart';

void main() {
  group('ApiClient.isUnauthorized', () {
    test('HTTP 401 命中', () {
      expect(ApiClient.isUnauthorized(httpStatus: 401), isTrue);
    });

    test('业务码 401 命中 (HTTP 200 包装)', () {
      expect(
        ApiClient.isUnauthorized(httpStatus: 200, bizCode: 401),
        isTrue,
      );
    });

    test('token / session 类 i18n key 命中', () {
      for (final key in [
        'token.expired',
        'token.invalid',
        'token.invalidated.password.change',
        'login.expired',
        'session.expire',
        'unauthorized',
        'account.not.login',
      ]) {
        expect(
          ApiClient.isUnauthorized(httpStatus: 200, bizCode: 1, msg: key),
          isTrue,
          reason: '$key 应判定为未授权',
        );
      }
    });

    test('中文 / 英文原文文案命中', () {
      expect(
        ApiClient.isUnauthorized(msg: '账号未登录'),
        isTrue,
      );
      expect(
        ApiClient.isUnauthorized(msg: '登录已过期，请重新登录'),
        isTrue,
      );
      expect(
        ApiClient.isUnauthorized(
          msg: 'Token has been invalidated due to password change',
        ),
        isTrue,
      );
    });

    test('普通业务错误不误判', () {
      expect(
        ApiClient.isUnauthorized(
          httpStatus: 200,
          bizCode: 1,
          msg: 'password.not.match',
        ),
        isFalse,
      );
      expect(
        ApiClient.isUnauthorized(httpStatus: 500, msg: 'internal error'),
        isFalse,
      );
      expect(ApiClient.isUnauthorized(httpStatus: 200, bizCode: 0), isFalse);
      expect(ApiClient.isUnauthorized(msg: ''), isFalse);
      expect(ApiClient.isUnauthorized(), isFalse);
    });

    test('验证码过期等 expired 文案不误判为登录过期', () {
      expect(
        ApiClient.isUnauthorized(
          httpStatus: 200,
          bizCode: 1,
          msg: 'captcha.code.expired',
        ),
        isFalse,
      );
    });
  });

  group('ApiClient.isPreLoginPath', () {
    test('登录 / 注册 / 找回密码 / 验证码接口视为登录前', () {
      for (final p in [
        '/app-api/system/app/auth/email-login',
        '/app-api/system/app/auth/mobile-login',
        '/app-api/system/app/auth/sms-login',
        '/app-api/system/app/auth/register',
        '/app-api/system/app/auth/mobile-register',
        '/app-api/system/app/auth/forget-password',
        '/app-api/system/app/auth/reset-password',
        '/app-api/system/app/auth/send-sms-code',
        '/app-api/system/app/auth/logout',
        '/app-api/system/app/mail-send/pinpoint/check-register-email',
        '/app-api/system/app/mail-send/pinpoint/sendVerifyCode',
        '/app-api/system/app/mail-send/checkPinpointVerifyCode',
        '/app-api/system/app/mail-send/pinpoint/forget/pwd/sendVerifyCode',
      ]) {
        expect(ApiClient.isPreLoginPath(p), isTrue, reason: '$p 应为登录前接口');
      }
    });

    test('登录后业务接口不在白名单内', () {
      for (final p in [
        '/app-api/system/app/user/get',
        '/app-api/system/app/user/update-password',
        '/app-api/system/app/user/remove',
        '/app-api/sl/app/recording-device/list',
        '/app-api/system/app/auth/refresh-token',
      ]) {
        expect(ApiClient.isPreLoginPath(p), isFalse, reason: '$p 不应被跳过');
      }
    });
  });
}
