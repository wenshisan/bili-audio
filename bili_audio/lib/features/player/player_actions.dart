import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/cover_url.dart';
import '../../core/utils/result.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/repositories.dart';
import '../../domain/entities/app_error.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/queue/playback_queue.dart';

/// UI 共用的播放/歌单操作 (M6), 失败时返回 [Result.failure] 由页面提示
class PlayerActions {
  PlayerActions(this._ref);

  final Ref _ref;
  var _queueFillGeneration = 0;

  /// 补齐缺 cid 的结果时同时请求的视频数。
  static const _lookupConcurrency = 4;

  /// 和发现、搜索列表一样，超过 15 分钟的分 P 不进队列。
  static const _maxQueuedSeconds = 15 * 60;

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
    if (tracks == null) {
      AppLogger.w(
        'play $bvid cid=$cid failed: ${result.errorOrNull}',
        tag: 'player',
      );
      return Result.failure(result.errorOrNull!);
    }
    AppLogger.i(
      'play $bvid cid=$cid tracks=${tracks.length} '
      '[${tracks.map((t) => '${t.pageIndex ?? 1}:${t.title}').join(' | ')}]',
      tag: 'player',
    );
    await _ref.read(audioHandlerProvider).setTracks(tracks);
    return const Result.success(null);
  }

  /// 用已加载的搜索/推荐结果当队列，从 [index] 开始。
  ///
  /// 有 cid 的行直接入队。没有 cid 的行去拉视频分 P，超过 15 分钟的分 P 不放进去。
  /// 先开播点中的那一首，再把其余缺 cid 的补进同一条队列，不把当前这首重新加载。
  Future<Result<void>> playSearchResults(
    List<SearchHit> hits,
    int index,
  ) async {
    if (index < 0 || index >= hits.length) {
      return const Result.failure(AppError.notFound());
    }
    final generation = ++_queueFillGeneration;
    final groups = List<List<Track>?>.filled(hits.length, null);
    final missing = <int>[];
    for (var i = 0; i < hits.length; i++) {
      final local = trackFromSearchHit(hits[i]);
      if (local != null) {
        groups[i] = [local];
      } else if (hits[i].result.duration > 0) {
        missing.add(i);
      }
    }

    final startHit = await _prepareStart(
      hits,
      groups,
      missing,
      index,
      generation,
    );
    if (generation != _queueFillGeneration) return const Result.success(null);
    if (startHit == null) return const Result.failure(AppError.notFound());

    await _applyStartEdits(groups, startHit, hits[startHit]);
    if (generation != _queueFillGeneration) return const Result.success(null);

    final initial = _assembleQueue(groups, startHit);
    if (initial.tracks.isEmpty) {
      return const Result.failure(AppError.notFound());
    }
    final track = initial.tracks[initial.start];
    AppLogger.i(
      'play search ${track.bvid} cid=${track.cid} '
      'at=${initial.start}/${initial.tracks.length} "${track.title}"',
      tag: 'player',
    );
    final handler = ref(audioHandlerProvider);
    await handler.setTracks(initial.tracks, startIndex: initial.start);
    if (missing.isEmpty || generation != _queueFillGeneration) {
      return const Result.success(null);
    }
    await _lookupMissing(hits, groups, missing, startHit, generation);
    return const Result.success(null);
  }

  /// 点中的那一行还不能播时，先解析它；解析失败再按列表顺序找下一行能播的。
  Future<int?> _prepareStart(
    List<SearchHit> hits,
    List<List<Track>?> groups,
    List<int> missing,
    int index,
    int generation,
  ) async {
    if (_hasTracks(groups[index])) return index;
    if (missing.contains(index)) {
      groups[index] = await _lookupHit(hits[index]);
      if (generation != _queueFillGeneration) return null;
      missing.remove(index);
      if (_hasTracks(groups[index])) return index;
    }
    final ready = _firstFilled(groups, index);
    if (ready != null || missing.isEmpty) return ready;

    final order = [...missing]
      ..sort((a, b) {
        final length = hits.length;
        final da = (a - index + length) % length;
        final db = (b - index + length) % length;
        return da.compareTo(db);
      });
    for (final i in order) {
      if (generation != _queueFillGeneration) return null;
      groups[i] = await _lookupHit(hits[i]);
      missing.remove(i);
      if (_hasTracks(groups[i])) return i;
    }
    return _firstFilled(groups, index);
  }

  Future<void> _lookupMissing(
    List<SearchHit> hits,
    List<List<Track>?> groups,
    List<int> missing,
    int startHit,
    int generation,
  ) async {
    var cursor = 0;
    Future<void> worker() async {
      while (true) {
        if (generation != _queueFillGeneration) return;
        final n = cursor++;
        if (n >= missing.length) return;
        final hitIndex = missing[n];
        groups[hitIndex] = await _lookupHit(hits[hitIndex]);
        if (generation != _queueFillGeneration) return;
        await _publishGrownQueue(groups, startHit);
      }
    }

    final width = missing.length < _lookupConcurrency
        ? missing.length
        : _lookupConcurrency;
    await Future.wait([for (var i = 0; i < width; i++) worker()]);
    if (generation != _queueFillGeneration) return;
    final filled = _assembleQueue(groups, startHit);
    AppLogger.i('play search filled ${filled.tracks.length}', tag: 'player');
    await _publishGrownQueue(groups, startHit);
  }

  Future<void> _publishGrownQueue(
    List<List<Track>?> groups,
    int startHit,
  ) async {
    final next = _assembleQueue(groups, startHit);
    final handler = ref(audioHandlerProvider);
    if (next.tracks.length <= handler.playbackQueue.length) return;
    await handler.setTracks(
      next.tracks,
      startIndex: next.start,
      keepCurrent: true,
    );
  }

  Future<void> _applyStartEdits(
    List<List<Track>?> groups,
    int startHit,
    SearchHit hit,
  ) async {
    final group = groups[startHit];
    if (group == null || group.isEmpty || trackFromSearchHit(hit) == null) {
      return;
    }
    final edited = [...group];
    edited[0] = await _withSavedEdits(edited[0]);
    groups[startHit] = edited;
  }

  /// 没有 cid 时拉分 P。列表上能看到的短视频，每个不超过 15 分钟的分 P 都入队。
  Future<List<Track>> _lookupHit(SearchHit hit) async {
    final local = trackFromSearchHit(hit);
    if (local != null) return [local];
    if (hit.result.duration <= 0) return const [];
    try {
      final result = await tracksOf(hit.result.bvid, cid: hit.result.cid);
      final tracks = result.valueOrNull;
      if (tracks == null) {
        AppLogger.w(
          'play search lookup ${hit.result.bvid} failed: ${result.errorOrNull}',
          tag: 'player',
        );
        return const [];
      }
      final playable = [
        for (final track in tracks)
          if (track.duration.inSeconds > 0 &&
              track.duration.inSeconds <= _maxQueuedSeconds)
            track,
      ];
      if (playable.isNotEmpty) return playable;
      return [
        for (final track in tracks)
          if (track.duration.inSeconds > 0) track,
      ];
    } catch (e, st) {
      AppLogger.e(
        'play search lookup ${hit.result.bvid} threw',
        tag: 'player',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  bool _hasTracks(List<Track>? group) => group != null && group.isNotEmpty;

  int? _firstFilled(List<List<Track>?> groups, int index) {
    for (var n = 0; n < groups.length; n++) {
      final i = (index + n) % groups.length;
      if (_hasTracks(groups[i])) return i;
    }
    return null;
  }

  ({List<Track> tracks, int start}) _assembleQueue(
    List<List<Track>?> groups,
    int startHit,
  ) {
    final tracks = <Track>[];
    var start = 0;
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group == null || group.isEmpty) continue;
      if (i == startHit) start = tracks.length;
      tracks.addAll(group);
    }
    return (tracks: tracks, start: start);
  }

  /// 下一首播放 / 追加到队列。有 cid 时不再请求视频详情。
  Future<Result<void>> enqueueSearchHit(
    SearchHit hit, {
    required bool next,
  }) async {
    final local = trackFromSearchHit(hit);
    if (local == null) {
      return _enqueue(hit.result.bvid, next: next, cid: hit.result.cid);
    }
    final track = await _withSavedEdits(local);
    AppLogger.i(
      '${next ? 'playNext' : 'append'} search ${track.bvid} cid=${track.cid}',
      tag: 'player',
    );
    final handler = ref(audioHandlerProvider);
    if (handler.currentTrack == null) {
      await handler.setTracks([track]);
      return const Result.success(null);
    }
    next ? handler.insertNext(track) : handler.append(track);
    return const Result.success(null);
  }

  /// 加入歌单用的曲目。有 cid 时直接用搜索结果。
  Future<Result<List<Track>>> tracksForSearchHit(SearchHit hit) async {
    final local = trackFromSearchHit(hit);
    if (local == null) return tracksOf(hit.result.bvid, cid: hit.result.cid);
    return Result.success([await _withSavedEdits(local)]);
  }

  /// 用户改过歌名/歌手时，播放和入队沿用改过的版本。
  Future<Track> _withSavedEdits(Track track) async {
    final row = await ref(databaseProvider).tracksDao
        .getTrack(track.bvid, track.cid);
    if (row == null || !row.userEdited) return track;
    return track.copyWith(cleanedName: row.cleanedName, artist: row.artist);
  }

  /// 以 [tracks] 为队列, 从 [index] 开始播放 (歌单/历史)
  Future<void> playList(
    List<Track> tracks, {
    int index = 0,
    bool shuffle = false,
  }) async {
    AppLogger.i(
      'playList count=${tracks.length} index=$index shuffle=$shuffle',
      tag: 'player',
    );
    final handler = ref(audioHandlerProvider);
    await handler.setTracks(
      tracks,
      startIndex: index,
      mode: shuffle ? PlayMode.shuffle : null,
    );
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
    if (tracks == null) {
      AppLogger.w(
        '${next ? 'playNext' : 'append'} $bvid cid=$cid failed: '
        '${result.errorOrNull}',
        tag: 'player',
      );
      return Result.failure(result.errorOrNull!);
    }
    AppLogger.i(
      '${next ? 'playNext' : 'append'} $bvid cid=$cid tracks=${tracks.length}',
      tag: 'player',
    );
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

/// 搜索结果已带分P信息时直接成曲。没有 cid 或时长无效时返回 null。
Track? trackFromSearchHit(SearchHit hit) {
  final result = hit.result;
  final cid = result.cid;
  if (cid == null || result.duration <= 0) return null;
  final name = hit.cleaned.name.trim();
  return Track(
    bvid: result.bvid,
    cid: cid,
    title: result.cleanTitle,
    cleanedName: name.isEmpty ? null : name,
    artist: hit.cleaned.artist,
    duration: Duration(seconds: result.duration),
    cover: absoluteCoverUrl(result.cover),
    uploader: result.author,
    pageIndex: result.pageIndex,
    totalPages: result.totalPages,
  );
}

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
