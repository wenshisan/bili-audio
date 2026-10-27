import 'package:bili_audio/core/network/bili_http.dart';
import 'package:bili_audio/core/network/buvid_manager.dart';
import 'package:bili_audio/core/network/wbi_key_manager.dart';
import 'package:bili_audio/core/storage/secure_store.dart';
import 'package:bili_audio/data/bili/bili_login_api.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio passport;
  late DioAdapter passportAdapter;
  late Dio api;
  late DioAdapter apiAdapter;
  late MemorySecureStore store;
  late BiliLoginApi login;

  setUp(() {
    store = MemorySecureStore();
    passport = Dio(BaseOptions(baseUrl: 'https://passport.bilibili.com'));
    passportAdapter = DioAdapter(
      dio: passport,
      matcher: const UrlRequestMatcher(),
    );
    api = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'));
    apiAdapter = DioAdapter(dio: api, matcher: const UrlRequestMatcher());
    final http = BiliHttp(
      dio: api,
      store: store,
      buvidManager: BuvidManager(store, () async => ('B3', 'B4')),
      wbiKeyManager: WbiKeyManager(
        () async => ('https://x/a.png', 'https://x/b.png'),
      ),
    );
    login = BiliLoginApi(http, store, passport: passport);
  });

  void pollReturns(int code, {List<String> cookies = const []}) =>
      passportAdapter.onGet(
        '/x/passport-login/web/qrcode/poll',
        (s) => s.reply(
          200,
          {
            'code': 0,
            'data': {'code': code, 'message': ''},
          },
          headers: {
            'set-cookie': cookies,
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

  test('generate 返回 url 与 qrcode_key', () async {
    passportAdapter.onGet(
      '/x/passport-login/web/qrcode/generate',
      (s) => s.reply(200, {
        'code': 0,
        'data': {'url': 'https://passport/qr?k=abc', 'qrcode_key': 'abc'},
      }),
    );
    final (url, key) = (await login.generate()).valueOrNull!;
    expect(url, contains('abc'));
    expect(key, 'abc');
  });

  test('轮询状态码映射', () async {
    pollReturns(86101);
    expect((await login.poll('k')).valueOrNull, isA<QrWaiting>());
    pollReturns(86090);
    expect((await login.poll('k')).valueOrNull, isA<QrScanned>());
    pollReturns(86038);
    expect((await login.poll('k')).valueOrNull, isA<QrExpired>());
  });

  test('成功时只保存需要的 Cookie', () async {
    pollReturns(
      0,
      cookies: [
        'SESSDATA=sess%2C123; Path=/; Domain=bilibili.com; HttpOnly',
        'bili_jct=jct456; Path=/',
        'DedeUserID=789; Path=/',
        'unrelated=x; Path=/',
      ],
    );
    expect((await login.poll('k')).valueOrNull, isA<QrConfirmed>());
    final saved = await store.readCookies();
    expect(saved, contains('SESSDATA=sess%2C123'));
    expect(saved, contains('bili_jct=jct456'));
    expect(saved, contains('DedeUserID=789'));
    expect(saved, isNot(contains('unrelated')));
  });

  test('成功但缺少 SESSDATA 时报错且不保存', () async {
    pollReturns(0, cookies: ['bili_jct=x']);
    expect((await login.poll('k')).isFailure, true);
    expect(await store.readCookies(), isNull);
  });

  test('currentUser: 已登录返回用户; 未登录 -101 返回 NeedLogin', () async {
    apiAdapter.onGet(
      '/x/web-interface/nav',
      (s) => s.reply(200, {
        'code': 0,
        'data': {
          'mid': 42,
          'uname': '测试',
          'face': 'https://face',
          'level_info': {'current_level': 5},
          'vipStatus': 1,
        },
      }),
    );
    final user = (await login.currentUser()).valueOrNull!;
    expect(user.name, '测试');
    expect(user.level, 5);
    expect(user.vip, true);

    apiAdapter.onGet(
      '/x/web-interface/nav',
      (s) => s.reply(200, {'code': -101}),
    );
    expect((await login.currentUser()).errorOrNull, isA<NeedLoginError>());
  });

  test('parseCookieHeader 保留值中的等号', () {
    final parsed = BiliLoginApi.parseCookieHeader(
      'SESSDATA=abc=def; bili_jct=jct; unrelated=x',
    );
    expect(parsed['SESSDATA'], 'abc=def');
    expect(parsed['bili_jct'], 'jct');
    expect(parsed['unrelated'], 'x');
  });

  test('parseLoginInput 接受单独凭证和 Cookie 头', () {
    expect(BiliLoginApi.parseLoginInput('  token value  '), {
      'SESSDATA': 'token value',
    });
    expect(BiliLoginApi.parseLoginInput('"sess=data"'), {
      'SESSDATA': 'sess=data',
    });
    expect(
      BiliLoginApi.parseLoginInput(
        'Cookie: SESSDATA=sess; bili_jct=jct; foo=bar\nDedeUserID=7',
      ),
      {'SESSDATA': 'sess', 'bili_jct': 'jct', 'DedeUserID': '7'},
    );
    expect(BiliLoginApi.parseLoginInput('bili_jct=only'), isNull);
    expect(BiliLoginApi.parseLoginInput(''), isNull);
    expect(BiliLoginApi.parseLoginInput('a=b; c=d'), isNull);
  });

  test('applyCookies 只保存登录 Cookie', () async {
    final saved = await login.applyCookies({
      'SESSDATA': 'sess%2C123',
      'bili_jct': 'jct',
      'unrelated': 'x',
    });
    expect(saved.isSuccess, isTrue);
    final cookies = await store.readCookies();
    expect(cookies, contains('SESSDATA=sess%2C123'));
    expect(cookies, contains('bili_jct=jct'));
    expect(cookies, isNot(contains('unrelated')));
    expect((await login.applyCookies({'bili_jct': 'x'})).isFailure, isTrue);
    expect(await store.readCookies(), contains('SESSDATA=sess%2C123'));
  });

  test('logout 清除 Cookie, 保留 buvid', () async {
    await store.writeCookies('SESSDATA=x');
    await store.write('buvid3', 'b');
    await login.logout();
    expect(await store.readCookies(), isNull);
    expect(await store.read('buvid3'), 'b');
  });
}
