// ============================================================
// 应用全局配置 (运行环境、API 基础地址、加密密钥)
//
// 历史: 早期是 static const 硬编码,后改为运行时从 [ServerConfigService] 解析
//       以支持"运行时切换服务器"功能 (me_profile 内的服务器切换入口)。
//
// 加密协议 (与后端 DecryptAspect + Secp256k1Crypto 一致):
//   1. 客户端用 secp256k1 公钥 (130 字符 hex, 04 || X || Y) 与 ECDH 派生共享密钥
//   2. SHA-256(sharedSecret) 作为 AES-256-CBC key,随机 16 字节 IV
//   3. 密文格式: ephemeralPub(130hex) + iv(32hex) + cipher(hex)
//   4. 请求头 Private-Key 必须携带对应的 secp256k1 私钥 (64 字符 hex = 32 字节 scalar),
//      后端用同一私钥做 ECDH 解密 @DecryptParams 标注的字段 (email/mobile/password/code 等)
//
// 切换服务器时机: 在 main() 启动序列中 [ServerConfigService.initialize] 完成
//                 之后, [AppEnv] 的所有 getter 都会从该服务读取活动 profile。
// ============================================================

import '../services/server_config_service.dart';
import 'server_profile.dart';

class AppEnv {
  AppEnv._();

  /// 后端 secp256k1 公钥 (130 字符 hex, 04 || X || Y 未压缩点)
  /// 来自活动 profile 的 [ServerProfile.publicKey]
  /// 与后端 Secp256k1Crypto.getPublicKeyFromString 协议一致
  static String get serverPublicKeyPem {
    final p = ServerConfigService.instance.active;
    if (p == null) {
      throw StateError('AppEnv 在 ServerConfigService.initialize() 完成前被访问');
    }
    return p.publicKey;
  }

  /// 后端 secp256k1 私钥 (64 字符 hex = 32 字节 scalar),由前端在 Private-Key header 中回传
  /// 来自活动 profile 的 [ServerProfile.privateKey]
  /// 与后端 Secp256k1Crypto.getPrivateKeyFromString 协议一致
  static String get serverPrivateKeyHex {
    final p = ServerConfigService.instance.active;
    if (p == null) {
      throw StateError('AppEnv 在 ServerConfigService.initialize() 完成前被访问');
    }
    return p.privateKey;
  }

  /// 后端服务基础地址 (Dio BaseOptions.baseUrl 源)
  static String get apiBaseUrl {
    final p = ServerConfigService.instance.active;
    if (p == null) {
      throw StateError('AppEnv 在 ServerConfigService.initialize() 完成前被访问');
    }
    return p.baseUrl;
  }

  /// 租户 ID (多租户场景, 来自活动 profile)
  static String get tenantId {
    final p = ServerConfigService.instance.active;
    if (p == null) {
      throw StateError('AppEnv 在 ServerConfigService.initialize() 完成前被访问');
    }
    return p.tenantId;
  }

  /// 默认语言 (i18n) — 当前固定 zh-CN,后续如需按活动服务器下发可改为 profile 字段
  static const String acceptLanguage = 'zh-CN';

  /// Private-Key 请求头名称 (与后端 DecryptAspect.PRIVATE_KEY_HEADER 保持一致)
  static const String privateKeyHeader = 'Private-Key';
}
