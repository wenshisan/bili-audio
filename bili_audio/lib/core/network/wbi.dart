import 'dart:convert';

import 'package:crypto/crypto.dart';

/// WBI 签名纯函数 (M2.1)
///
/// 算法参考 bilibili-API-collect: `img_key + sub_key` 按混淆表重排取前 32 位
/// 得到 mixin_key; 参数追加 `wts` 后按 key 排序、过滤 `!'()*`、URL 编码,
/// `w_rid = md5(query + mixin_key)`。
class Wbi {
  Wbi._();

  static const List<int> _mixinKeyEncTab = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35, //
    27, 43, 5, 49, 33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13, //
    37, 48, 7, 16, 24, 55, 40, 61, 26, 17, 0, 1, 60, 51, 30, 4, //
    22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36, 20, 34, 44, 52,
  ];

  static final RegExp _illegalChars = RegExp(r"[!'()*]");

  /// 从 `wbi_img.img_url` / `sub_url` 中提取文件名作为 key
  static String keyFromUrl(String url) {
    final name = Uri.parse(url).pathSegments.last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? name : name.substring(0, dot);
  }

  static String mixinKey(String imgKey, String subKey) {
    final orig = imgKey + subKey;
    final buf = StringBuffer();
    for (final i in _mixinKeyEncTab) {
      if (i < orig.length) buf.write(orig[i]);
    }
    final s = buf.toString();
    return s.length > 32 ? s.substring(0, 32) : s;
  }

  /// 返回签名后的参数 (含 `wts` 与 `w_rid`)
  static Map<String, String> sign(
    Map<String, dynamic> params,
    String mixinKey, {
    required int wts,
  }) {
    final cleaned = <String, String>{
      for (final e in params.entries)
        e.key: e.value.toString().replaceAll(_illegalChars, ''),
      'wts': wts.toString(),
    };
    final keys = cleaned.keys.toList()..sort();
    final query = keys
        .map((k) =>
            '${Uri.encodeComponent(k)}=${Uri.encodeComponent(cleaned[k]!)}')
        .join('&');
    final wRid = md5.convert(utf8.encode(query + mixinKey)).toString();
    return {...cleaned, 'w_rid': wRid};
  }
}
