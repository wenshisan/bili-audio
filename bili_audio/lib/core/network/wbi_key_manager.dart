import 'wbi.dart';

/// 拉取 `wbi_img` 的回调, 返回 (img_url, sub_url)
typedef WbiImgFetcher = Future<(String, String)> Function();

/// WBI mixin_key 缓存 (M2.1)
///
/// key 缓存 24h; 并发调用合并为一次请求; 签名失败时由调用方 [invalidate]。
class WbiKeyManager {
  WbiKeyManager(
    this._fetch, {
    DateTime Function()? clock,
    this.ttl = const Duration(hours: 24),
  }) : _clock = clock ?? DateTime.now;

  final WbiImgFetcher _fetch;
  final DateTime Function() _clock;
  final Duration ttl;

  String? _mixinKey;
  DateTime? _fetchedAt;
  Future<String>? _inflight;

  Future<String> mixinKey() {
    final key = _mixinKey;
    final at = _fetchedAt;
    if (key != null && at != null && _clock().difference(at) < ttl) {
      return Future.value(key);
    }
    return _inflight ??= _refresh().whenComplete(() => _inflight = null);
  }

  Future<String> _refresh() async {
    final (imgUrl, subUrl) = await _fetch();
    final key = Wbi.mixinKey(Wbi.keyFromUrl(imgUrl), Wbi.keyFromUrl(subUrl));
    _mixinKey = key;
    _fetchedAt = _clock();
    return key;
  }

  void invalidate() {
    _mixinKey = null;
    _fetchedAt = null;
  }
}
