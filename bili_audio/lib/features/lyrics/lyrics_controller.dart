import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/lyrics/lyrics_manager.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/lyrics/lyrics_provider.dart';

/// 歌词管理器; bootstrap 中 override (M5)
final lyricsManagerProvider = Provider<LyricsManager>(
  (ref) => throw UnimplementedError('lyricsManagerProvider 必须 override'),
);

/// 当前曲目 key (bvid_cid), 切歌时变化
final currentTrackKeyProvider = Provider<String?>((ref) {
  final id = ref.watch(mediaItemProvider).value?.id;
  return id;
});

LyricsQuery queryFor(Track t) => LyricsQuery(
  bvid: t.bvid,
  cid: t.cid,
  title: t.displayTitle,
  artist: t.artist,
  duration: t.duration,
  rawTitle: t.title,
);

/// 当前曲目的歌词状态 (M5.5)
///
/// 切歌时自动重新查询; 偏移调整/手动选择后就地更新, 无需重新搜索。
class LyricsController extends AsyncNotifier<LyricsResult?> {
  @override
  Future<LyricsResult?> build() async {
    final key = ref.watch(currentTrackKeyProvider);
    if (key == null) return null;
    final track = ref.read(audioHandlerProvider).currentTrack;
    if (track == null) return null;
    return ref.read(lyricsManagerProvider).find(queryFor(track));
  }

  Track? get _track => ref.read(audioHandlerProvider).currentTrack;

  Future<void> adjustOffset(Duration delta) async {
    final t = _track;
    final current = state.value;
    if (t == null || current is! LyricsFound) return;
    await ref.read(lyricsManagerProvider).adjustOffset(t.bvid, t.cid, delta);
    state = AsyncData(
      LyricsFound(
        current.lyrics.copyWith(offset: current.lyrics.offset + delta),
        fromCache: true,
      ),
    );
  }

  Future<void> accept(LyricsCandidate c) async {
    final t = _track;
    if (t == null) return;
    final lyrics = await ref.read(lyricsManagerProvider).accept(queryFor(t), c);
    state = AsyncData(LyricsFound(lyrics, fromCache: true));
  }

  Future<void> markNone() async {
    final t = _track;
    if (t == null) return;
    await ref.read(lyricsManagerProvider).markNoLyrics(t.bvid, t.cid);
    state = const AsyncData(LyricsNone(markedByUser: true));
  }

  /// 清缓存后重新匹配 (编辑歌名后调用)
  Future<void> rematch() async {
    final t = _track;
    if (t == null) return;
    await ref.read(lyricsManagerProvider).invalidate(t.bvid, t.cid);
    ref.invalidateSelf();
  }
}

final lyricsControllerProvider =
    AsyncNotifierProvider<LyricsController, LyricsResult?>(
      LyricsController.new,
    );
