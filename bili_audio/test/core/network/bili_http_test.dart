import 'package:bili_audio/core/network/bili_http.dart';
import 'package:bili_audio/core/network/buvid_manager.dart';
import 'package:bili_audio/core/network/wbi_key_manager.dart';
import 'package:bili_audio/core/storage/secure_store.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late MemorySecureStore store;
  late int wbiFetches;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'));
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    store = MemorySecureStore();
    wbiFetches = 0;
    BiliHttp(
      dio: dio,
      store: store,
      buvidManager: BuvidManager(store, () async => ('B3', 'B4')),
      wbiKeyManager: WbiKeyManager(() async {
        wbiFetches++;
        return (
          'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png',
          'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png',
        );
      }),
    );
  });

  test('注入 Referer / UA / Cookie(buvid + 登录)', () async {
    await store.writeCookies('SESSDATA=abc');
    late RequestOptions captured;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      captured = o;
      h.next(o);
    }));
    adapter.onGet('/x/test', (s) => s.reply(200, {'code': 0, 'data': {}}));

    await dio.get<dynamic>('/x/test');

    expect(captured.headers['Referer'], 'https://www.bilibili.com');
    expect(captured.headers['User-Agent'], contains('Mozilla'));
    expect(captured.headers['Cookie'], 'SESSDATA=abc; buvid3=B3; buvid4=B4');
  });

  test('wbi: true 时追加 wts 与 w_rid', () async {
    late RequestOptions captured;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      captured = o;
      h.next(o);
    }));
    adapter.onGet('/x/wbi', (s) => s.reply(200, {'code': 0}));

    await dio.get<dynamic>(
      '/x/wbi',
      queryParameters: {'keyword': 'abc'},
      options: Options(extra: {'wbi': true}),
    );

    expect(captured.queryParameters.keys, containsAll(['wts', 'w_rid']));
    expect(wbiFetches, 1);
  });

  test('-352 时刷新 WBI key 并重试一次', () async {
    var calls = 0;
    dio.interceptors.insert(
      0,
      InterceptorsWrapper(onRequest: (o, h) {
        calls++;
        h.next(o);
      }),
    );
    adapter.onGet('/x/wbi', (s) => s.reply(200, {'code': -352}));

    await expectLater(
      dio.get<dynamic>('/x/wbi', options: Options(extra: {'wbi': true})),
      throwsA(isA<DioException>()
          .having((e) => e.error, 'error', isA<RiskControlError>())),
    );
    expect(calls, 2); // 原请求 + 一次重试
    expect(wbiFetches, 2); // key 被 invalidate 后重新获取
  });

  Future<AppError> errorOf(int code) async {
    adapter.onGet('/x/err', (s) => s.reply(200, {'code': code}));
    try {
      await dio.get<dynamic>('/x/err');
      fail('should throw');
    } on DioException catch (e) {
      return e.error! as AppError;
    }
  }

  test('业务码映射为 AppError', () async {
    expect(await errorOf(-101), isA<NeedLoginError>());
    expect(await errorOf(-412), isA<RiskControlError>());
    expect(await errorOf(-404), isA<NotFoundError>());
    expect(await errorOf(62002), isA<NotFoundError>());
    expect(await errorOf(87008), isA<CopyrightError>());
    expect(await errorOf(12345), isA<UnknownError>());
  });

  test('网络错误映射为 NetworkError', () async {
    adapter.onGet(
      '/x/net',
      (s) => s.throws(
        404,
        DioException.badResponse(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/x/net'),
          response: Response(
            requestOptions: RequestOptions(path: '/x/net'),
            statusCode: 404,
          ),
        ),
      ),
    );
    try {
      await dio.get<dynamic>('/x/net');
      fail('should throw');
    } on DioException catch (e) {
      expect(e.error, isA<NetworkError>());
    }
  });
}
