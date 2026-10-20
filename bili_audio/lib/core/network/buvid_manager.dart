import 'dart:math';

import '../storage/secure_store.dart';

/// 调用 `/x/frontend/finger/spi` 的回调, 返回 (b_3, b_4)
typedef BuvidFetcher = Future<(String, String)> Function();

/// buvid3 / buvid4 设备标识 (M2.1)
///
/// 优先读持久化值; 否则请求接口; 接口失败时本地随机生成兜底。
class BuvidManager {
  BuvidManager(this._store, this._fetch, {Random? random})
      : _random = random ?? Random.secure();

  static const _k3 = 'buvid3';
  static const _k4 = 'buvid4';

  final SecureStore _store;
  final BuvidFetcher _fetch;
  final Random _random;

  (String, String)? _cached;
  Future<(String, String)>? _inflight;

  Future<(String, String)> get() {
    final c = _cached;
    if (c != null) return Future.value(c);
    return _inflight ??= _load().whenComplete(() => _inflight = null);
  }

  Future<(String, String)> _load() async {
    final s3 = await _store.read(_k3);
    final s4 = await _store.read(_k4);
    if (s3 != null && s4 != null) return _cached = (s3, s4);

    (String, String) ids;
    try {
      ids = await _fetch();
    } catch (_) {
      ids = (_generateBuvid3(), _generateBuvid4());
    }
    await _store.write(_k3, ids.$1);
    await _store.write(_k4, ids.$2);
    return _cached = ids;
  }

  String _hex(int n) => List.generate(
        n,
        (_) => _random.nextInt(16).toRadixString(16),
      ).join().toUpperCase();

  /// 形如 `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXXXXXXinfoc`
  String _generateBuvid3() =>
      '${_hex(8)}-${_hex(4)}-${_hex(4)}-${_hex(4)}-${_hex(12)}${_hex(5)}infoc';

  String _generateBuvid4() =>
      '${_hex(8)}-${_hex(4)}-${_hex(4)}-${_hex(4)}-${_hex(12)}${_hex(5)}-'
      '${DateTime.now().millisecondsSinceEpoch ~/ 1000}-${_hex(8)}';
}
