import 'dart:math' show min;

import '../../core/utils/result.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/entities/video.dart';
import '../../domain/title/title_cleaner.dart';
import '../bili/bili_search_api.dart';
import '../bili/bili_stream_api.dart';
import '../bili/models/search_result.dart';
import 'repositories.dart';
import 'stream_url_manager.dart';

export 'bili_video_repository.dart';

/// 基于 B 站接口的搜索仓储 (M2.6)
class BiliSearchRepository implements SearchRepository {
  BiliSearchRepository(this._api, this._cleaner, {this.pageList});

  final BiliSearchApi _api;
  final TitleCleaner _cleaner;

  /// 拉取分P。未提供时只按搜索卡片时长丢掉超过 15 分钟的结果。
  final Future<Result<List<VideoPage>>> Function(String bvid)? pageList;

  static const maxDuration = 900;
  static const _concurrency = 4;

  /// `P1` / `p 2` / `1` 这类无信息量的分P标题
  static final _placeholderPart = RegExp(r'^\s*[Pp]?\s*\d+\s*$');

  @override
  Future<Result<SearchHitPage>> search(String keyword, {int page = 1}) async {
    final result = await _api.searchVideo(keyword: keyword, page: page);
    return result.mapAsync((p) async {
      final groups = await _expandAll(p.items);
      return (
        items: [for (final group in groups) ...group],
        page: p.page,
        total: p.total,
        hasMore: p.hasMore,
      );
    });
  }

  Future<List<List<SearchHit>>> _expandAll(List<SearchResult> items) async {
    if (items.isEmpty) return const [];
    final out = List<List<SearchHit>?>.filled(items.length, null);
    var cursor = 0;

    Future<void> worker() async {
      while (true) {
        final index = cursor++;
        if (index >= items.length) return;
        out[index] = await _expand(items[index]);
      }
    }

    final workers = min(_concurrency, items.length);
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    return [for (final group in out) group!];
  }

  /// 单 P 且超过 15 分钟则丢弃；多 P 则每个不超过 15 分钟的分P单独成一条。
  Future<List<SearchHit>> _expand(SearchResult item) async {
    final load = pageList;
    List<VideoPage>? pages;
    if (load != null) {
      try {
        pages = (await load(item.bvid)).valueOrNull;
      } catch (_) {
        pages = null;
      }
    }
    if (pages == null || pages.isEmpty) {
      if (item.duration > maxDuration) return const [];
      return [_hit(item)];
    }

    final playable = [
      for (final page in pages)
        if (page.duration.inSeconds <= maxDuration) page,
    ];
    if (playable.isEmpty) return const [];

    if (pages.length == 1) {
      final page = playable.single;
      return [
        _hit(
          item.copyWith(
            duration: page.duration.inSeconds,
            cid: page.cid,
            pageIndex: page.pageIndex,
            totalPages: 1,
            filtered: false,
          ),
        ),
      ];
    }

    return [
      for (final page in playable)
        _hit(
          item.copyWith(
            duration: page.duration.inSeconds,
            cid: page.cid,
            pageIndex: page.pageIndex,
            totalPages: pages.length,
            filtered: false,
          ),
          rawTitle: _placeholderPart.hasMatch(page.title)
              ? item.cleanTitle
              : page.title,
        ),
    ];
  }

  SearchHit _hit(SearchResult result, {String? rawTitle}) {
    final title = rawTitle ?? result.cleanTitle;
    final shown = rawTitle == null
        ? result
        : result.copyWith(title: title, cleanTitle: title);
    return (result: shown, cleaned: _cleaner.clean(title));
  }
}

/// 基于 [StreamUrlManager] 的流地址仓储 (M2.6)
class BiliStreamRepository implements StreamRepository {
  BiliStreamRepository(this._manager);

  final StreamUrlManager _manager;

  @override
  Future<Result<StreamSelection>> resolve(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) => _manager.getStreamUrl(
    bvid: track.bvid,
    cid: track.cid,
    quality: quality,
    loggedIn: loggedIn,
  );

  @override
  Future<Result<StreamSelection>> refresh(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) => _manager.refresh(
    bvid: track.bvid,
    cid: track.cid,
    quality: quality,
    loggedIn: loggedIn,
  );
}
