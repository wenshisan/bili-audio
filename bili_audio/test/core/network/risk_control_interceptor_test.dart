import 'dart:convert';
import 'dart:typed_data';

import 'package:bili_audio/core/network/interceptors/error_mapper_interceptor.dart';
import 'package:bili_audio/core/network/interceptors/risk_control_interceptor.dart';
import 'package:bili_audio/core/network/risk_control_guard.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 按顺序返回预设业务码的适配器, 并记录请求次数
class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this.codes);

  final List<int> codes;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final code = codes[calls.clamp(0, codes.length - 1)];
    calls++;
    return ResponseBody.fromString(
      jsonEncode({'code': code, 'data': {'ok': code == 0}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late RiskControlGuard guard;

  Dio build(_QueueAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'))
      ..httpClientAdapter = adapter;
    // 与 BiliHttp 一致: RiskControl 在 ErrorMapper 之前
    dio.interceptors.addAll([
      RiskControlInterceptor(guard, dio, backoff: Duration.zero),
      ErrorMapperInterceptor(),
    ]);
    return dio;
  }

  void enterCooldown() {
    for (var i = 0; i < 3; i++) {
      guard.recordHit('/x');
    }
  }

  setUp(() => guard = RiskControlGuard(threshold: 3));

  test('冷却期内 risk_guarded 请求直接拒绝, 不发请求', () async {
    final adapter = _QueueAdapter([0]);
    final dio = build(adapter);
    enterCooldown();

    await expectLater(
      dio.get<dynamic>('/s', options: Options(extra: {'risk_guarded': true})),
      throwsA(isA<DioException>()
          .having((e) => e.error, 'error', isA<RiskControlError>())),
    );
    expect(adapter.calls, 0);
  });

  test('冷却期内非 guarded 请求照常放行', () async {
    final adapter = _QueueAdapter([0]);
    enterCooldown();
    final res = await build(adapter).get<dynamic>('/v');
    expect(res.statusCode, 200);
  });

  test('-412 计数, 未达阈值不进入冷却', () async {
    final dio = build(_QueueAdapter([-412]));
    await expectLater(dio.get<dynamic>('/s'), throwsA(isA<DioException>()));
    expect(guard.inCooldown, false);
  });

  test('risk_retry: -412 后退避重试一次并成功', () async {
    final adapter = _QueueAdapter([-412, 0]);
    final res = await build(adapter)
        .get<dynamic>('/s', options: Options(extra: {'risk_retry': true}));
    expect(adapter.calls, 2);
    expect(res.data['data']['ok'], true);
  });

  test('risk_retry: 重试仍失败则返回 RiskControl, 只重试一次', () async {
    final adapter = _QueueAdapter([-412, -412, -412]);
    await expectLater(
      build(adapter)
          .get<dynamic>('/s', options: Options(extra: {'risk_retry': true})),
      throwsA(isA<DioException>()
          .having((e) => e.error, 'error', isA<RiskControlError>())),
    );
    expect(adapter.calls, 2);
  });

  test('连续 -412 达到阈值后进入冷却, 后续 guarded 请求不再发出', () async {
    final adapter = _QueueAdapter([-412]);
    final dio = build(adapter);
    for (var i = 0; i < 3; i++) {
      await expectLater(dio.get<dynamic>('/s'), throwsA(isA<DioException>()));
    }
    expect(guard.inCooldown, true);

    final before = adapter.calls;
    await expectLater(
      dio.get<dynamic>('/s', options: Options(extra: {'risk_guarded': true})),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, before);
  });
}
