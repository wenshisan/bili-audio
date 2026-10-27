import 'package:dio/dio.dart';

import '../../core/network/bili_http.dart';
import '../../core/storage/secure_store.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';

/// 扫码状态 (M7.1)
sealed class QrStatus {
  const QrStatus();
}

/// 86101: 未扫描
class QrWaiting extends QrStatus {
  const QrWaiting();
}

/// 86090: 已扫描, 等待手机确认
class QrScanned extends QrStatus {
  const QrScanned();
}

/// 86038: 二维码已过期
class QrExpired extends QrStatus {
  const QrExpired();
}

/// 0: 登录成功, Cookie 已写入 [SecureStore]
class QrConfirmed extends QrStatus {
  const QrConfirmed();
}

/// 登录用户信息
class BiliUser {
  const BiliUser({
    required this.mid,
    required this.name,
    required this.face,
    required this.level,
    required this.vip,
  });

  final int mid;
  final String name;
  final String face;
  final int level;

  /// 大会员 (可用 Hi-Res / Dolby)
  final bool vip;
}

/// Web 登录 (M7.1, D1)
///
/// 扫码和网页登录都只持久化
/// `SESSDATA` / `bili_jct` / `DedeUserID` / `DedeUserID__ckMd5` / `sid`。
class BiliLoginApi {
  BiliLoginApi(this._http, this._store, {Dio? passport})
    : _passport =
          passport ??
          Dio(
            BaseOptions(
              baseUrl: 'https://passport.bilibili.com',
              headers: {
                'Referer': 'https://www.bilibili.com',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
            ),
          );

  final BiliHttp _http;
  final SecureStore _store;
  final Dio _passport;

  static const keptCookies = {
    'SESSDATA',
    'bili_jct',
    'DedeUserID',
    'DedeUserID__ckMd5',
    'sid',
  };

  /// 生成二维码: 返回 (待编码为二维码的 url, qrcode_key)
  Future<Result<(String url, String key)>> generate() async {
    try {
      final res = await _passport.get<Map<String, dynamic>>(
        '/x/passport-login/web/qrcode/generate',
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      if (res.data?['code'] != 0 || data == null) {
        return Result.failure(
          AppError.unknown(message: 'qrcode/generate: ${res.data?['message']}'),
        );
      }
      return Result.success((
        data['url'] as String,
        data['qrcode_key'] as String,
      ));
    } on DioException catch (e) {
      return Result.failure(AppError.network(message: '生成二维码失败', cause: e));
    }
  }

  /// 轮询扫码状态; 成功时从 Set-Cookie 提取并保存 Cookie
  Future<Result<QrStatus>> poll(String key) async {
    try {
      final res = await _passport.get<Map<String, dynamic>>(
        '/x/passport-login/web/qrcode/poll',
        queryParameters: {'qrcode_key': key},
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      final code = data?['code'] as int?;
      switch (code) {
        case 86101:
          return const Result.success(QrWaiting());
        case 86090:
          return const Result.success(QrScanned());
        case 86038:
          return const Result.success(QrExpired());
        case 0:
          final cookies = extractCookies(
            res.headers[HttpHeaders.setCookie] ?? [],
          );
          final saved = await applyCookies(cookies);
          if (saved.isFailure) return Result.failure(saved.errorOrNull!);
          return const Result.success(QrConfirmed());
        default:
          return Result.failure(
            AppError.unknown(
              message: 'qrcode/poll code=$code ${data?['message'] ?? ''}',
            ),
          );
      }
    } on DioException catch (e) {
      return Result.failure(AppError.network(message: '轮询失败', cause: e));
    }
  }

  /// 已登录用户信息; 未登录返回 [NeedLoginError]
  Future<Result<BiliUser>> currentUser() async {
    try {
      final res = await _http.dio.get<Map<String, dynamic>>(
        '/x/web-interface/nav',
      );
      final d = res.data!['data'] as Map<String, dynamic>;
      return Result.success(
        BiliUser(
          mid: d['mid'] as int? ?? 0,
          name: d['uname'] as String? ?? '',
          face: d['face'] as String? ?? '',
          level:
              (d['level_info'] as Map<String, dynamic>?)?['current_level']
                  as int? ??
              0,
          vip: (d['vipStatus'] as int? ?? 0) == 1,
        ),
      );
    } on DioException catch (e) {
      final err = e.error;
      return Result.failure(
        err is AppError ? err : AppError.network(message: 'nav', cause: e),
      );
    }
  }

  Future<void> logout() => _store.clear();

  /// 写入登录 Cookie。没有 `SESSDATA` 时不落盘。
  Future<Result<void>> applyCookies(Map<String, String> raw) async {
    final cookies = parseLoginCookies(raw);
    if (cookies == null) {
      return const Result.failure(AppError.unknown(message: '登录响应缺少 SESSDATA'));
    }
    await _store.writeCookies(
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
    );
    return const Result.success(null);
  }

  /// 从 Cookie 请求头里拆出全部名称和值。值里的 `=` 会保留。
  static Map<String, String> parseCookieHeader(String header) {
    final out = <String, String>{};
    for (final part in header.split(RegExp(r'[;\n]'))) {
      final pair = part.trim();
      if (pair.isEmpty) continue;
      final i = pair.indexOf('=');
      if (i <= 0) continue;
      final name = pair.substring(0, i).trim();
      final value = pair.substring(i + 1).trim();
      if (name.isEmpty || value.isEmpty) continue;
      out[name] = value;
    }
    return out;
  }

  /// 只留下登录需要的 Cookie。没有 `SESSDATA` 时返回 null。
  static Map<String, String>? parseLoginCookies(Map<String, String> raw) {
    final out = <String, String>{};
    for (final name in keptCookies) {
      final value = raw[name]?.trim();
      if (value != null && value.isNotEmpty) out[name] = value;
    }
    if ((out['SESSDATA'] ?? '').isEmpty) return null;
    return out;
  }

  /// 解析粘贴的登录凭证。
  ///
  /// 可以是单独的 `SESSDATA`，也可以是包含它的 Cookie 头。
  static Map<String, String>? parseLoginInput(String raw) {
    final text = _unwrapLoginInput(raw);
    if (text == null) return null;
    final pairs = parseCookieHeader(text);
    final login = parseLoginCookies(pairs);
    if (login != null) return login;
    final lookedLikeHeader =
        pairs.keys.any(keptCookies.contains) ||
        text.contains(';') ||
        text.contains('\n') ||
        keptCookies.any((name) => text.contains('$name='));
    if (lookedLikeHeader) return null;
    return {'SESSDATA': text};
  }

  static String? _unwrapLoginInput(String raw) {
    var text = raw.trim();
    if (text.length >= 7 && text.toLowerCase().startsWith('cookie:')) {
      text = text.substring(text.indexOf(':') + 1).trim();
    }
    if (text.length >= 2) {
      final quote = text[0];
      if ((quote == '"' || quote == "'") && text.endsWith(quote)) {
        text = text.substring(1, text.length - 1).trim();
      }
    }
    if (text.isEmpty) return null;
    return text;
  }

  /// 从 Set-Cookie 头中提取需要保留的 Cookie
  static Map<String, String> extractCookies(List<String> setCookies) {
    final out = <String, String>{};
    for (final header in setCookies) {
      final pair = header.split(';').first;
      final i = pair.indexOf('=');
      if (i <= 0) continue;
      final name = pair.substring(0, i).trim();
      if (keptCookies.contains(name)) out[name] = pair.substring(i + 1).trim();
    }
    return out;
  }
}

abstract final class HttpHeaders {
  static const setCookie = 'set-cookie';
}
