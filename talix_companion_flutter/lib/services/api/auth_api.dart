import '../../models/auth_models.dart';
import '../../utils/device_type.dart';
import '../crypto/field_encryption.dart';
import 'base_api_service.dart';

/// 登录注册相关 API 封装
///
/// 仅包含项目需要的核心流程,游客登录按需未引入。
/// 所有涉及 @DecryptParams 标注的 email/mobile/password/code 字段,
/// 都通过 [FieldEncryption.encryptField] 加密后再发往后端。
///
/// 所有方法都上报 deviceType 字段 (1=PC / 2=iOS / 3=Android / 4=Web),
/// 默认为 [DeviceType.current]。如果调用方想覆盖 (例如调试时伪装平台),
/// 显式传 deviceType 参数即可。
class AuthApi extends BaseApiService {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'auth-api';

  // ============== 邮箱相关 ==============

  /// POST /system/app/auth/email-login
  /// @DecryptParams({"email","password"})
  Future<AuthLoginResp> emailLogin({
    required String email,
    required String password,
    required String deviceId,
    int? deviceType,
  }) async {
    return post<AuthLoginResp>(
      '/system/app/auth/email-login',
      data: {
        'email': FieldEncryption.encryptField(email),
        'password': FieldEncryption.encryptField(password),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
      fromData: (raw) => AuthLoginResp.fromJson(asMap(raw)),
    );
  }

  /// POST /system/app/auth/register
  /// @DecryptParams({"email","password"})
  Future<void> emailRegister({
    required String email,
    required String password,
    required String deviceId,
    int? deviceType,
  }) async {
    await post(
      '/system/app/auth/register',
      data: {
        'email': FieldEncryption.encryptField(email),
        'password': FieldEncryption.encryptField(password),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
    );
  }

  /// POST /system/app/auth/forget-password
  /// @DecryptParams({"email","password"})
  Future<void> emailForgetPassword({
    required String email,
    required String password,
    required String deviceId,
    int? deviceType,
  }) async {
    await post(
      '/system/app/auth/forget-password',
      data: {
        'email': FieldEncryption.encryptField(email),
        'password': FieldEncryption.encryptField(password),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
    );
  }

  // ============== 手机号相关 ==============

  /// POST /system/app/auth/send-sms-code
  /// @DecryptParams({"mobile"})
  /// 返回短信验证码 uuid (登录时回传)
  Future<String> sendSmsCode({
    required String mobile,
    required String deviceId,
    int? deviceType,
  }) async {
    return post<String>(
      '/system/app/auth/send-sms-code',
      data: {
        'mobile': FieldEncryption.encryptField(mobile),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
      fromData: (raw) => raw as String,
    );
  }

  /// POST /system/app/auth/sms-login
  /// @DecryptParams({"mobile"})
  Future<AuthLoginResp> smsLogin({
    required String mobile,
    required String code,
    required String uuid,
    required String deviceId,
    int? deviceType,
  }) async {
    return post<AuthLoginResp>(
      '/system/app/auth/sms-login',
      data: {
        'mobile': FieldEncryption.encryptField(mobile),
        'code': code,
        'uuid': uuid,
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
      fromData: (raw) => AuthLoginResp.fromJson(asMap(raw)),
    );
  }

  /// POST /system/app/auth/mobile-register
  /// @DecryptParams({"mobile","password"})
  Future<void> mobileRegister({
    required String mobile,
    required String password,
    required String deviceId,
    int? deviceType,
  }) async {
    await post(
      '/system/app/auth/mobile-register',
      data: {
        'mobile': FieldEncryption.encryptField(mobile),
        'password': FieldEncryption.encryptField(password),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
    );
  }

  /// POST /system/app/auth/mobile-login
  /// @DecryptParams({"mobile","password"})
  Future<AuthLoginResp> mobileLogin({
    required String mobile,
    required String password,
    required String deviceId,
    int? deviceType,
  }) async {
    return post<AuthLoginResp>(
      '/system/app/auth/mobile-login',
      data: {
        'mobile': FieldEncryption.encryptField(mobile),
        'password': FieldEncryption.encryptField(password),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
      fromData: (raw) => AuthLoginResp.fromJson(asMap(raw)),
    );
  }

  /// POST /system/app/auth/reset-password
  /// @DecryptParams({"mobile","password"})
  Future<void> resetPassword({
    required String mobile,
    required String password,
    required String code,
    int? deviceType,
  }) async {
    await post(
      '/system/app/auth/reset-password',
      data: {
        'mobile': FieldEncryption.encryptField(mobile),
        'password': FieldEncryption.encryptField(password),
        'code': code,
        if (deviceType != null) 'deviceType': deviceType,
      },
    );
  }

  // ============== 邮箱验证码 ==============

  /// POST /system/app/mail-send/pinpoint/check-register-email
  /// @DecryptParams("email")
  Future<void> checkEmailForRegister({
    required String email,
    required String deviceId,
    int? deviceType,
  }) async {
    await post(
      '/system/app/mail-send/pinpoint/check-register-email',
      data: {
        'email': FieldEncryption.encryptField(email),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
    );
  }

  /// POST /system/app/mail-send/pinpoint/sendVerifyCode
  /// @DecryptParams("email")
  Future<String> sendEmailCodeForRegister({
    required String email,
    required String deviceId,
    String? language,
    int? deviceType,
  }) async {
    return post<String>(
      '/system/app/mail-send/pinpoint/sendVerifyCode',
      data: {
        'email': FieldEncryption.encryptField(email),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
        if (language != null) 'language': language,
      },
      fromData: (raw) => raw as String,
    );
  }

  /// POST /system/app/mail-send/checkPinpointVerifyCode
  /// @DecryptParams("email")
  Future<void> checkEmailCode({
    required String email,
    required String uuid,
    required String code,
    required String deviceId,
    int? deviceType,
  }) async {
    await post(
      '/system/app/mail-send/checkPinpointVerifyCode',
      data: {
        'email': FieldEncryption.encryptField(email),
        'uuid': uuid,
        'code': code,
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
    );
  }

  /// POST /system/app/mail-send/pinpoint/check-forget-password-email
  Future<void> checkEmailForForget({
    required String email,
    required String deviceId,
    int? deviceType,
  }) async {
    await post(
      '/system/app/mail-send/pinpoint/check-forget-password-email',
      data: {
        'email': FieldEncryption.encryptField(email),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
    );
  }

  /// POST /system/app/mail-send/pinpoint/forget/pwd/sendVerifyCode
  Future<String> sendEmailCodeForForget({
    required String email,
    required String deviceId,
    String? language,
    int? deviceType,
  }) async {
    return post<String>(
      '/system/app/mail-send/pinpoint/forget/pwd/sendVerifyCode',
      data: {
        'email': FieldEncryption.encryptField(email),
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
        if (language != null) 'language': language,
      },
      fromData: (raw) => raw as String,
    );
  }

  /// POST /system/app/mail-send/forget/pwd/checkPinpointVerifyCode
  Future<void> checkForgetEmailCode({
    required String email,
    required String uuid,
    required String code,
    required String deviceId,
    int? deviceType,
  }) async {
    await post(
      '/system/app/mail-send/forget/pwd/checkPinpointVerifyCode',
      data: {
        'email': FieldEncryption.encryptField(email),
        'uuid': uuid,
        'code': code,
        'deviceId': deviceId,
        'deviceType': deviceType ?? DeviceType.current,
      },
    );
  }

  // ============== Token / 登出 ==============

  /// POST /system/app/auth/refresh-token?refreshToken=xxx
  Future<AuthLoginResp> refreshToken(String refreshToken) async {
    return post<AuthLoginResp>(
      '/system/app/auth/refresh-token',
      query: {'refreshToken': refreshToken},
      fromData: (raw) => AuthLoginResp.fromJson(asMap(raw)),
    );
  }

  /// POST /system/app/auth/logout
  Future<void> logout() async {
    await post('/system/app/auth/logout');
  }

  // ============== 用户资料 ==============

  /// GET /system/app/user/get
  Future<UserProfile> getUserProfile() async {
    return get<UserProfile>(
      '/system/app/user/get',
      fromData: (raw) => UserProfile.fromJson(asMap(raw)),
    );
  }

  /// PUT /system/app/user/updateNickName
  Future<void> updateNickName(String nickname) async {
    await put(
      '/system/app/user/updateNickName',
      data: {'nickname': nickname},
    );
  }

  /// PUT /system/app/user/update-password
  /// @DecryptParams({"newPassword", "oldPassword"})
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await put(
      '/system/app/user/update-password',
      data: {
        'oldPassword': FieldEncryption.encryptField(oldPassword),
        'newPassword': FieldEncryption.encryptField(newPassword),
      },
    );
  }

  /// DELETE /system/app/user/remove
  Future<void> deleteAccount() async {
    await delete('/system/app/user/remove');
  }
}
