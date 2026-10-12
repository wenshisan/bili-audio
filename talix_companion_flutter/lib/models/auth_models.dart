/// 与后端 CommonResult<T> 一致的统一返回结构
class ApiResult<T> {
  final int code;
  final T? data;
  final String? msg;

  const ApiResult({required this.code, this.data, this.msg});

  bool get isSuccess => code == 0;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? fromData,
  ) {
    return ApiResult<T>(
      code: _asInt(json['code']) ?? -1,
      data: json['data'] == null
          ? null
          : (fromData != null ? fromData(json['data']) : json['data'] as T),
      msg: json['msg'] as String?,
    );
  }
}

/// 登录响应
class AuthLoginResp {
  final int userId;
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresTime;

  const AuthLoginResp({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    this.expiresTime,
  });

  factory AuthLoginResp.fromJson(Map<String, dynamic> json) {
    return AuthLoginResp(
      userId: _asInt(json['userId']) ?? 0,
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: (json['refreshToken'] as String?) ?? '',
      expiresTime: _parseDate(json['expiresTime']),
    );
  }
}

/// 登录态刷新响应 (与登录同结构)
typedef RefreshTokenResp = AuthLoginResp;

/// 邮箱密码登录请求
class EmailLoginReq {
  final String email;
  final String password;
  final String deviceId;
  final int? deviceType; // 1=PC / 2=iOS / 3=Android / 4=Web, 传 null 由服务端推断
  final String? captchaVerification;

  const EmailLoginReq({
    required this.email,
    required this.password,
    required this.deviceId,
    this.deviceType,
    this.captchaVerification,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
        if (captchaVerification != null) 'captchaVerification': captchaVerification,
      };
}

/// 手机号密码登录请求
class MobileLoginReq {
  final String mobile;
  final String password;
  final String deviceId;
  final int? deviceType;
  final String? captchaVerification;

  const MobileLoginReq({
    required this.mobile,
    required this.password,
    required this.deviceId,
    this.deviceType,
    this.captchaVerification,
  });

  Map<String, dynamic> toJson() => {
        'mobile': mobile,
        'password': password,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
        if (captchaVerification != null) 'captchaVerification': captchaVerification,
      };
}

/// 短信验证码登录请求
class SmsLoginReq {
  final String mobile;
  final String code;
  final String uuid;
  final String deviceId;
  final int? deviceType;
  final String? captchaVerification;

  const SmsLoginReq({
    required this.mobile,
    required this.code,
    required this.uuid,
    required this.deviceId,
    this.deviceType,
    this.captchaVerification,
  });

  Map<String, dynamic> toJson() => {
        'mobile': mobile,
        'code': code,
        'uuid': uuid,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
        if (captchaVerification != null) 'captchaVerification': captchaVerification,
      };
}

/// 发送短信验证码请求
class SendSmsCodeReq {
  final String mobile;
  final String deviceId;
  final int? deviceType;
  final String? captchaVerification;

  const SendSmsCodeReq({
    required this.mobile,
    required this.deviceId,
    this.deviceType,
    this.captchaVerification,
  });

  Map<String, dynamic> toJson() => {
        'mobile': mobile,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
        if (captchaVerification != null) 'captchaVerification': captchaVerification,
      };
}

/// 邮箱注册请求
class EmailRegisterReq {
  final String email;
  final String password;
  final String deviceId;
  final int? deviceType;

  const EmailRegisterReq({
    required this.email,
    required this.password,
    required this.deviceId,
    this.deviceType,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
      };
}

/// 邮箱忘记密码请求
class EmailForgetPasswordReq {
  final String email;
  final String password;
  final String deviceId;
  final int? deviceType;

  const EmailForgetPasswordReq({
    required this.email,
    required this.password,
    required this.deviceId,
    this.deviceType,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
      };
}

/// 发送邮箱验证码请求
class EmailSendCodeReq {
  final String email;
  final String deviceId;
  final int? deviceType;
  final String? language;

  const EmailSendCodeReq({
    required this.email,
    required this.deviceId,
    this.deviceType,
    this.language,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
        if (language != null) 'language': language,
      };
}

/// 校验邮箱验证码请求
class EmailCheckCodeReq {
  final String email;
  final String uuid;
  final String code;
  final String deviceId;
  final int? deviceType;

  const EmailCheckCodeReq({
    required this.email,
    required this.uuid,
    required this.code,
    required this.deviceId,
    this.deviceType,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'uuid': uuid,
        'code': code,
        'deviceId': deviceId,
        if (deviceType != null) 'deviceType': deviceType,
      };
}

/// 用户个人资料 (登录后拉取)
class UserProfile {
  final int id;
  final String? nickname;
  final String? sn;
  final String? email;
  final String? mobile;
  final int? sex;
  final String? avatar;
  final String? loginIp;
  final DateTime? loginDate;
  final DateTime? createTime;
  final bool isTourist;

  const UserProfile({
    required this.id,
    this.nickname,
    this.sn,
    this.email,
    this.mobile,
    this.sex,
    this.avatar,
    this.loginIp,
    this.loginDate,
    this.createTime,
    this.isTourist = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _asInt(json['id']) ?? 0,
      nickname: json['nickname'] as String?,
      sn: json['sn'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      sex: _asInt(json['sex']),
      avatar: json['avatar'] as String?,
      loginIp: json['loginIp'] as String?,
      loginDate: _parseDate(json['loginDate']),
      createTime: _parseDate(json['createTime']),
      isTourist: (json['isTourist'] as bool?) ?? false,
    );
  }
}

/// 安全地将 dynamic 转为 int (兼容 String/num)
int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v);
  }
  if (v is num) {
    return DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000);
  }
  return null;
}
