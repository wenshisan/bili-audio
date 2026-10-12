// One-off tool: 从已知的 secp256k1 私钥推导出对应的未压缩公钥 (65 字节, 04||X||Y),
// 写为 130 个 hex 字符,与后端 Secp256k1Crypto.getPublicKeyFromString 协议一致。
//
// 用法: dart run tool/derive_public_key.dart <privateKeyHex>
//
// 例:
//   dart run tool/derive_public_key.dart ad65f9394e457b80d13f09bdbed2a1cde5e1f7d27584f5d145287ec535e11bbc

import 'dart:typed_data';

import 'package:pointycastle/ecc/api.dart' as pc;
import 'package:pointycastle/ecc/curves/secp256k1.dart' as pc;

void main(List<String> args) {
  if (args.isEmpty) {
    print('usage: dart run tool/derive_public_key.dart <privateKeyHex>');
    return;
  }
  final privHex = args[0];
  if (privHex.length != 64) {
    print('ERROR: 私钥必须是 64 个 hex 字符 (32 字节)');
    return;
  }

  final d = BigInt.parse(privHex, radix: 16);
  final curve = pc.ECCurve_secp256k1();
  final G = curve.G;
  // Q = d * G
  final Q = G * d;
  final x = Q!.x!.toBigInteger()!;
  final y = Q.y!.toBigInteger()!;

  final out = Uint8List(65)..[0] = 0x04;
  _writeBigIntAt(x, out, 1, 32);
  _writeBigIntAt(y, out, 33, 32);
  final pubHex = _toHex(out);
  print('publicKey (raw 130 hex): $pubHex');
  print('privateKey              : $privHex');
  print('');
  print('请把 publicKey 替换到 assets/config/servers.json 对应 profile 的 "publicKey" 字段;');
  print('privateKey 保持不变 (已经正确,64 hex = 32 字节 = secp256k1 scalar)。');
}

void _writeBigIntAt(BigInt v, Uint8List dst, int offset, int size) {
  final bytes = _bigIntToFixedBytes(v, size);
  dst.setRange(offset, offset + size, bytes);
}

Uint8List _bigIntToFixedBytes(BigInt v, int size) {
  final hex = v.toRadixString(16);
  final padded = hex.length.isEven ? hex : '0$hex';
  final raw = Uint8List.fromList(_hexToBytes(padded));
  final out = Uint8List(size);
  if (raw.length <= size) {
    out.setRange(size - raw.length, size, raw);
  } else {
    out.setRange(0, size, raw.sublist(raw.length - size));
  }
  return out;
}

Uint8List _hexToBytes(String hex) {
  final len = hex.length ~/ 2;
  final out = Uint8List(len);
  for (var i = 0; i < len; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

String _toHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}
