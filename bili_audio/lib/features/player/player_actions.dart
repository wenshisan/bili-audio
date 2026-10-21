import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/l10n.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/result.dart';
import '../../data/db/app_database.dart' as db;
import '../../domain/entities/app_error.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/queue/playback_queue.dart';

/// UI 共用的播放/歌单操作 (M6), 失败时返回 [Result.failure] 由页面提示
class PlayerActions {
  PlayerActions(this._ref);

  final Ref _ref;

  /// 解析视频分P; 搜索结果点击 / 长按菜单共用
  ///
  /// 传入 [cid] 时只返回这一 P。
  Future<Result<List<Track>>> tracksOf(String bvid, {int? cid}) async {
    final result = await _ref.read(videoRepositoryProvider).getTracks(bvid);
    if (cid == null) return result;
    final tracks = result.valueOrNull;
    if (tracks == null) return Result.failure(result.errorOrNull!);
    final match = tracks.where((t) => t.cid == cid).toList();
    if (match.isEmpty) return const Result.failure(AppError.notFound());
    return Result.success(match);
  }

  /// 播放视频。指定 [cid] 时只播放这一 P，否则多 P 连续入队。
  Future<Result<void>> playVideo(String bvid, {int? cid}) async {
    final result = await tracksOf(bvid, cid: cid);
    final tracks = result.valueOrNull;
    if (tracks == null) return Result.failure(result.errorOrNull!);
    await _ref.read(audioHandlerProvider).setTracks(tracks);
    return const Result.success(null);
  }

  /// 以 [tracks] 为队列, 从 [index] 开始播放 (歌单/历史)
  Future<void> playList(
    List<Track> tracks, {
    int index = 0,
    bool shuffle = false,
  }) async {
    final handler = ref(audioHandlerProvider);
    await handler.setTracks(tracks, startIndex: index);
    if (shuffle) {
      handler.setPlayMode(PlayMode.shuffle);
    }
  }

  Future<Result<void>> playNext(String bvid, {int? cid}) =>
      _enqueue(bvid, next: true, cid: cid);
  Future<Result<void>> addToQueue(String bvid, {int? cid}) =>
      _enqueue(bvid, next: false, cid: cid);

  Future<Result<void>> _enqueue(
    String bvid, {
    required bool next,
    int? cid,
  }) async {
    final result = await tracksOf(bvid, cid: cid);
    final tracks = result.valueOrNull;
    if (tracks == null) return Result.failure(result.errorOrNull!);
    final handler = ref(audioHandlerProvider);
    if (handler.currentTrack == null) {
      await handler.setTracks(tracks);
      return const Result.success(null);
    }
    // 下一首播放时保持分P顺序: 倒序插入
    for (final t in next ? tracks.reversed : tracks) {
      next ? handler.insertNext(t) : handler.append(t);
    }
    return const Result.success(null);
  }

  /// 加入歌单 (去重); 加入后的歌曲缓存受 pinned 保护
  Future<void> addToPlaylist(int playlistId, List<Track> tracks) async {
    final database = ref(databaseProvider);
    final quality = ref(playbackPrefsProvider).quality;
    for (final t in tracks) {
      await database.tracksDao.ensureTrack(_companion(t));
      await database.playlistsDao.addTrackToPlaylist(
        playlistId: playlistId,
        bvid: t.bvid,
        cid: t.cid,
      );
      await database.cacheDao.setPinned(t.cacheKey(quality), true);
    }
  }

  T ref<T>(Provider<T> p) => _ref.read(p);

  static db.TracksCompanion _companion(Track t) => db.TracksCompanion.insert(
    bvid: t.bvid,
    cid: t.cid,
    title: t.title,
    cleanedName: Value(t.cleanedName),
    artist: Value(t.artist),
    duration: t.duration.inSeconds,
    cover: Value(t.cover),
    uploader: Value(t.uploader),
    pageIndex: Value(t.pageIndex),
    totalPages: Value(t.totalPages),
  );
}

final playerActionsProvider = Provider(PlayerActions.new);

/// drift 行 → 领域实体
Track trackFromRow(db.Track row) => Track(
  bvid: row.bvid,
  cid: row.cid,
  title: row.title,
  cleanedName: row.cleanedName,
  artist: row.artist,
  duration: Duration(seconds: row.duration),
  cover: row.cover,
  uploader: row.uploader,
  pageIndex: row.pageIndex,
  totalPages: row.totalPages,
);

/// M7.3 辅助: 首次因未登录降级时弹窗提示 (非阻塞)
void promptLoginIfDowngraded(
  BuildContext context,
  WidgetRef ref,
  bool downgradedForGuest,
) async {
  if (!downgradedForGuest) return;
  final db = ref.read(databaseProvider);
  final shown = await db.settingsDao.get('login_prompt_shown');
  if (shown == 'true') return;
  await db.settingsDao.set('login_prompt_shown', 'true');
  if (!context.mounted) return;
  final l10n = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.loginPrompt),
      action: SnackBarAction(
        label: l10n.loginTitle,
        onPressed: () => context.push('/login'),
      ),
      duration: const Duration(seconds: 6),
    ),
  );
}
