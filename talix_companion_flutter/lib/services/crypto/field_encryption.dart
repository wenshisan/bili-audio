import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/api.dart' as pc;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart' as pc;
import 'package:pointycastle/ecc/curves/secp256k1.dart' as pc;
import 'package:pointycastle/key_generators/api.dart' as pc;
import 'package:pointycastle/key_generators/ec_key_generator.dart' as pc;
import 'package:pointycastle/random/fortuna_random.dart';

import '../../config/env.dart';
import '../../utils/app_logger.dart';

/// 敏感字段加密工具
///
/// 对齐后端 `cn.iocoder.power.framework.common.util.Secp256k1Crypto.decrypt` 与
/// `cn.iocoder.power.framework.web.aop.DecryptAspect` 的协议。
///
/// 协议:
///   1. 客户端生成临时 secp256k1 密钥对
///   2. 与服务端公钥做 ECDH → 共享密钥 (取 X 坐标)
///   3. encryptionKey = SHA-256(共享密钥)
///   4. 随机 IV (16 字节)
///   5. AES/CBC/PKCS7Padding 加密明文
///   6. 输出字符串 = ephemeralPublicKey(65B→130hex) + iv(16B→32hex) + ciphertext(hex)
///
/// 此外,DecryptAspect 要求请求中携带 `Private-Key: <server私钥HEX>` 头。
/// (见 [AppEnv.serverPrivateKeyHex])
///
/// 兼容 pointycastle 3.9.x:
///   - import 路径从 2.x 的 `key_agreement/key_generators` 收敛到
///     `ecc/key_generators + impl.dart` 统一再导出
///   - PaddedBlockCipher / BlockCipher / Padding 改用 registry 工厂
///   - ECDHBasicAgreement.calculateAgreement(ECPublicKey) 取代旧 computeAgreement
///   - ECPublicKey(Q, params) 构造需要传入 domain parameters
class FieldEncryption {
  FieldEncryption._();

  static final pc.ECDomainParameters _curve = pc.ECCurve_secp256k1();
  static final pc.ECKeyGenerator _keyGen = pc.ECKeyGenerator();

  /// 解析 secp256k1 公钥 → 未压缩点 (65 字节, 04 || X || Y)
  ///
  /// 接受两种输入格式(自动识别):
  ///   1. **未压缩 hex 字符串**(首选,与后端 Secp256k1Crypto.getPublicKeyFromString 一致)
  ///      长度 130 个 hex 字符,以 `04` 开头,直接 hex 解码即可。
  ///   2. **X.509 SubjectPublicKeyInfo (Base64 DER)**: 解析 BIT STRING 中的 65 字节点。
  ///      注意:后端 DecryptAspect 不接受 X.509 格式,这里仅作兼容保留。
  static Uint8List _parseServerPublicKey(String input) {
    final s = input.trim();
    if (s.isEmpty) {
      throw const FormatException('公钥字符串为空');
    }

    // 1) 优先尝试 hex 解码(130 字符 = 65 字节,首字符 '0','4' 起始)
    if (s.length == 130 && !s.contains(' ') && !s.contains('+') && !s.contains('/')) {
      try {
        final bytes = _hexToBytes(s);
        if (bytes[0] == 0x04 && bytes.length == 65) {
          return bytes;
        }
      } catch (_) {
        // 继续尝试 X.509
      }
    }

    // 2) 兜底: 尝试按 X.509 Base64 解析(历史兼容)
    try {
      final der = base64Decode(s);
      for (var i = 0; i < der.length - 67; i++) {
        if (der[i] == 0x03 && der[i + 1] == 0x42 && der[i + 2] == 0x00 && der[i + 3] == 0x04) {
          return Uint8List.fromList(der.sublist(i + 3, i + 3 + 65));
        }
      }
    } catch (_) {
      // 忽略,继续往下抛
    }

    throw FormatException(
      '无法解析 secp256k1 公钥: 期望 130 字符 hex (04 || X || Y) 或 X.509 Base64 DER,'
      '实际输入前 32 字符: ${s.length > 32 ? s.substring(0, 32) : s}',
    );
  }

  /// 加密一个明文字段 → 传给后端的密文字串
  ///
  /// [plaintext] 原始明文 (email / mobile / password / code / 等)
  /// 返回 130 + 32 + N 个 hex 字符的密文
  static String encryptField(String plaintext) {
    final stopwatch = Stopwatch()..start();
    final rand = Random.secure();
    AppLogger.d('encryptField: plaintextLen=${plaintext.length}', 'crypto');

    // 1) 生成临时 secp256k1 密钥对
    final seedSrc = Uint8List(32);
    for (var i = 0; i < seedSrc.length; i++) {
      seedSrc[i] = rand.nextInt(256);
    }
    final rng = FortunaRandom()..seed(pc.KeyParameter(seedSrc));

    _keyGen
        .init(pc.ParametersWithRandom(
          pc.ECKeyGeneratorParameters(_curve),
          rng,
        ));
    final keyPair = _keyGen.generateKeyPair();
    final priv = keyPair.privateKey as pc.ECPrivateKey;
    final pub = keyPair.publicKey as pc.ECPublicKey;

    // 序列化为 65 字节未压缩点 (04 || X || Y)
    final x = pub.Q!.x!.toBigInteger()!;
    final y = pub.Q!.y!.toBigInteger()!;
    final ephemeralPub = Uint8List(65)
      ..[0] = 0x04;
    _fillBigIntegerAt(x, ephemeralPub, 1, 32);
    _fillBigIntegerAt(y, ephemeralPub, 33, 32);
    final ephemeralPubHex = _toHex(ephemeralPub);
    AppLogger.d('encryptField: ephemeralPub=${ephemeralPubHex.substring(0, 16)}…', 'crypto');

    // 2) 解析服务端公钥 (支持 hex 130 字符 / X.509 Base64 两种格式)
    final serverPubRaw = _parseServerPublicKey(AppEnv.serverPublicKeyPem);
    AppLogger.d('encryptField: serverPub parsed, len=${serverPubRaw.length}', 'crypto');
    final serverPubPoint = _curve.curve.decodePoint(serverPubRaw);
    final serverPub = pc.ECPublicKey(serverPubPoint, _curve);

    // 3) ECDH → sharedSecret (3.x: ECDHBasicAgreement.init(privateKey) + calculateAgreement(publicKey))
    final agreement = pc.ECDHBasicAgreement()..init(priv);
    final sharedSecret = agreement.calculateAgreement(serverPub);
    final sharedBytes = _bigIntToFixedBytes(BigInt.parse(sharedSecret.toString()), 32);
    AppLogger.d('encryptField: ECDH sharedSecretLen=${sharedBytes.length}', 'crypto');

    // 4) encryptionKey = SHA-256(sharedSecret)
    final sha = SHA256Digest()
      ..update(sharedBytes, 0, sharedBytes.length);
    final encKey = Uint8List(sha.digestSize);
    sha.doFinal(encKey, 0);

    // 5) 随机 IV
    final iv = Uint8List(16);
    for (var i = 0; i < iv.length; i++) {
      iv[i] = rand.nextInt(256);
    }
    final ivHex = _toHex(iv);

    // 6) AES/CBC/PKCS7Padding 加密
    //    pointycastle 3.x 改用 registry 工厂: PaddedBlockCipher('AES/CBC/PKCS7')
    //    init 需要 PaddedBlockCipherParameters(底层 cipher params, padding params)
    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        true,
        pc.PaddedBlockCipherParameters<
            pc.ParametersWithIV<pc.KeyParameter>, pc.KeyParameter?>(
          pc.ParametersWithIV<pc.KeyParameter>(pc.KeyParameter(encKey), iv),
          null,
        ),
      );
    final input = Uint8List.fromList(utf8.encode(plaintext));
    final output = cipher.process(input);
    final cipherHex = _toHex(output);

    stopwatch.stop();
    AppLogger.d(
      'encryptField: done, ciphertextLen=${cipherHex.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
      'crypto',
    );
    return ephemeralPubHex + ivHex + cipherHex;
  }

  // ===== helpers =====

  static void _fillBigIntegerAt(BigInt v, Uint8List dst, int offset, int size) {
    final bytes = _bigIntToFixedBytes(v, size);
    dst.setRange(offset, offset + size, bytes);
  }

  static Uint8List _bigIntToFixedBytes(BigInt v, int size) {
    // BigInt → 固定长度大端字节数组 (高位缺位补 0)
    final hex = v.toRadixString(16);
    final padded = hex.length.isEven ? hex : '0$hex';
    final raw = Uint8List.fromList(_hexToBytes(padded));
    final out = Uint8List(size);
    if (raw.length <= size) {
      out.setRange(size - raw.length, size, raw);
    } else {
      // 截断 (取低位 size 字节)
      out.setRange(0, size, raw.sublist(raw.length - size));
    }
    return out;
  }

  static Uint8List _hexToBytes(String hex) {
    final len = hex.length ~/ 2;
    final out = Uint8List(len);
    for (var i = 0; i < len; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static String _toHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
