import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/album/album_manager.dart';
import '../../domain/album/album_provider.dart';
import '../../domain/entities/audio_track.dart';
import '../lyrics/lyrics_controller.dart';

/// 专辑资料管理器。未注入时播放页继续用 B 站封面。
final albumManagerProvider = Provider<AlbumManager?>((ref) => null);

AlbumQuery albumQueryFor(Track t) => AlbumQuery(
  bvid: t.bvid,
  cid: t.cid,
  title: t.displayTitle,
  artist: t.artist,
  duration: t.duration,
  rawTitle: t.title,
);

/// 当前曲目的官方专辑图、年份和介绍。切歌时重新查询。
class AlbumController extends AsyncNotifier<AlbumResult?> {
  @override
  Future<AlbumResult?> build() async {
    final key = ref.watch(currentTrackKeyProvider);
    final manager = ref.watch(albumManagerProvider);
    if (key == null || manager == null) return null;
    final track = ref.read(audioHandlerProvider).currentTrack;
    if (track == null) return null;
    return manager.find(albumQueryFor(track));
  }

  /// 歌名改过之后清掉缓存，按新歌名再匹配。
  Future<void> rematch() async {
    final track = ref.read(audioHandlerProvider).currentTrack;
    final manager = ref.read(albumManagerProvider);
    if (track == null || manager == null) return;
    await manager.invalidate(track.bvid, track.cid);
    ref.invalidateSelf();
  }
}

final albumControllerProvider =
    AsyncNotifierProvider<AlbumController, AlbumResult?>(AlbumController.new);
