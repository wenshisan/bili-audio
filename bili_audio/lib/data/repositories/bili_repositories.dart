import '../../core/utils/result.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/title/title_cleaner.dart';
import '../bili/bili_search_api.dart';
import '../bili/bili_stream_api.dart';
import 'repositories.dart';
import 'stream_url_manager.dart';

export 'bili_video_repository.dart';

/// 基于 B 站接口的搜索仓储 (M2.6)
class BiliSearchRepository implements SearchRepository {
  BiliSearchRepository(this._api, this._cleaner);

  final BiliSearchApi _api;
  final TitleCleaner _cleaner;

  @override
  Future<Result<SearchHitPage>> search(String keyword, {int page = 1}) async {
    final result = await _api.searchVideo(keyword: keyword, page: page);
    return result.map((p) => (
          items: [
            for (final r in p.items)
              (result: r, cleaned: _cleaner.clean(r.cleanTitle)),
          ],
          page: p.page,
          total: p.total,
          hasMore: p.hasMore,
        ));
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
  }) =>
      _manager.getStreamUrl(
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
  }) =>
      _manager.refresh(
        bvid: track.bvid,
        cid: track.cid,
        quality: quality,
        loggedIn: loggedIn,
      );
}
