import 'package:dio/dio.dart';

/// 令牌桶限流 (M2.1): 默认 5 req/s
class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor({
    this.tokensPerSecond = 5,
    this.maxBurst = 10,
    DateTime Function()? clock,
  })  : _tokens = maxBurst.toDouble(),
        _clock = clock ?? DateTime.now;

  final int tokensPerSecond;
  final int maxBurst;
  final DateTime Function() _clock;

  double _tokens;
  DateTime? _lastRefill;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skip_rate_limit'] == true) {
      return handler.next(options);
    }

    await _acquireToken();
    handler.next(options);
  }

  Future<void> _acquireToken() async {
    while (true) {
      _refill();
      if (_tokens >= 1.0) {
        _tokens -= 1.0;
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _refill() {
    final now = _clock();
    final last = _lastRefill;
    if (last == null) {
      _lastRefill = now;
      return;
    }

    final elapsed = now.difference(last).inMilliseconds / 1000.0;
    final added = elapsed * tokensPerSecond;
    _tokens = (_tokens + added).clamp(0, maxBurst.toDouble());
    _lastRefill = now;
  }
}
