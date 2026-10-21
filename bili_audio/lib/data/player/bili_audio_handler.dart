import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import '../../domain/entities/app_error.dart';
import '../../domain/entities/audio_track.dart';
import '../../domain/queue/playback_queue.dart';
import '../audio/cache_download_manager.dart';
import '../audio/caching_stream_audio_source.dart';
import '../repositories/repositories.dart';
import 'audio_engine.dart';
import 'queue_snapshot_store.dart';

/// 后台播放入口 (M3.1 / M3.4)
///
/// - 播放器每次只加载当前曲; 下一首仅预解析流地址 (D8)
/// - 播放模式由 [PlaybackQueue] 控制, 引擎始终不循环
/// - 队列变化后防抖写入 `queue_snapshot`
class BiliAudioHandler extends BaseAudioHandler with SeekHandler {
  BiliAudioHandler({
    required this.engine,
    required this.streams,
    required this.downloads,
    this.snapshots,
    AudioQuality Function()? quality,
    bool Function()? loggedIn,
  })  : _quality = quality ?? (() => AudioQuality.k132),
        _loggedIn = loggedIn ?? (() => false) {
    _subs.add(engine.playbackEventStream.listen((_) => _broadcast()));
    _subs.add(engine.playingStream.listen((_) => _broadcast()));
    _subs.add(engine.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) unawaited(_onCompleted());
    }));
    _publishQueue();
  }

  final AudioEngine engine;
  final StreamRepository streams;
  final CacheDownloadManager downloads;
  final QueueSnapshotStore? snapshots;
  final AudioQuality Function() _quality;
  final bool Function() _loggedIn;

  final _subs = <StreamSubscription<Object?>>[];
  final _errors = StreamController<AppError>.broadcast();
  PlaybackQueue _q = PlaybackQueue();
  int _loadToken = 0;

  /// 领域队列 (BaseAudioHandler.queue 是 MediaItem 列表)
  PlaybackQueue get playbackQueue => _q;
  Track? get currentTrack => _q.current;

  /// 播放失败等错误, 由 UI 展示 (如需登录、风控)
  Stream<AppError> get errors => _errors.stream;

  /// 设置新队列并从 [startIndex] 开始
  Future<void> setTracks(
    List<Track> tracks, {
    int startIndex = 0,
    bool autoplay = true,
  }) async {
    _q = PlaybackQueue(tracks: tracks, mode: _q.mode);
    if (startIndex != 0) _q.jumpTo(startIndex);
    await _loadCurrent(autoplay: autoplay);
  }

  /// 启动时恢复上次队列与位置, 不自动播放
  Future<bool> restore() async {
    final snap = await snapshots?.load();
    if (snap == null || snap.$1.isEmpty) return false;
    _q = snap.$1;
    await _loadCurrent(autoplay: false, position: snap.$2);
    return true;
  }

  Future<void> _loadCurrent({
    required bool autoplay,
    Duration? position,
  }) async {
    final track = _q.current;
    _publishQueue();
    if (track == null) {
      await engine.stop();
      return;
    }
    final token = ++_loadToken;
    final quality = _quality();
    final key = track.cacheKey(quality);
    downloads.playingKey = key;
    final item = toMediaItem(track);
    mediaItem.add(item);

    final source = CachingStreamAudioSource(
      cacheKey: key,
      resolveUrl: () => _url(track, quality, refresh: false),
      refreshUrl: () => _url(track, quality, refresh: true),
      downloads: downloads,
      tag: item,
    );
    try {
      await engine.setSource(source, initialPosition: position);
      if (token != _loadToken) return; // 快速切歌时丢弃过期加载
      if (autoplay) unawaited(engine.play());
    } on AppError catch (e) {
      _errors.add(e);
    } catch (e) {
      _errors.add(AppError.unknown(message: '播放失败: $e', cause: e));
    }
    unawaited(_preloadNext());
    _save();
  }

  Future<String> _url(
    Track track,
    AudioQuality quality, {
    required bool refresh,
  }) async {
    final result = refresh
        ? await streams.refresh(track, quality, loggedIn: _loggedIn())
        : await streams.resolve(track, quality, loggedIn: _loggedIn());
    final selection = result.valueOrNull;
    if (selection == null) throw result.errorOrNull!;
    return selection.stream.url;
  }

  /// 预解析下一首流地址; 已完整缓存则跳过 (二次播放 0 网络请求)
  Future<void> _preloadNext() async {
    final next = _q.nextTrack;
    if (next == null) return;
    final quality = _quality();
    if (await downloads.store.completed(next.cacheKey(quality)) != null) return;
    await streams.resolve(next, quality, loggedIn: _loggedIn());
  }

  Future<void> _onCompleted() async {
    if (_q.mode == PlayMode.singleLoop) {
      await engine.seek(Duration.zero);
      unawaited(engine.play());
      return;
    }
    if (_q.next() == null) {
      await engine.pause();
      await engine.seek(Duration.zero);
      _save();
      return;
    }
    await _loadCurrent(autoplay: true);
  }

  // ---- 播放控制 ----

  @override
  Future<void> play() => engine.play();
  @override
  Future<void> pause() async {
    await engine.pause();
    _save();
  }

  @override
  Future<void> stop() async {
    await engine.stop();
    _save();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => engine.seek(position);
  @override
  Future<void> setSpeed(double speed) => engine.setSpeed(speed);

  @override
  Future<void> skipToNext() async {
    if (_q.mode == PlayMode.singleLoop) {
      // 用户主动切歌时单曲循环也前进一首
      _q.setMode(PlayMode.listLoop);
      _q.next();
      _q.setMode(PlayMode.singleLoop);
    } else if (_q.next() == null) {
      return;
    }
    await _loadCurrent(autoplay: true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (engine.position > const Duration(seconds: 3) || _q.previous() == null) {
      return engine.seek(Duration.zero);
    }
    await _loadCurrent(autoplay: true);
  }

  /// [index] 为 [queue] (当前播放顺序) 中的位置
  @override
  Future<void> skipToQueueItem(int index) async {
    final ordered = _q.orderedTracks;
    if (index < 0 || index >= ordered.length) return;
    _q.jumpTo(_q.tracks.indexOf(ordered[index]));
    await _loadCurrent(autoplay: true);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async =>
      setPlayMode(switch (repeatMode) {
        AudioServiceRepeatMode.one => PlayMode.singleLoop,
        AudioServiceRepeatMode.all ||
        AudioServiceRepeatMode.group =>
          PlayMode.listLoop,
        AudioServiceRepeatMode.none => PlayMode.sequential,
      });

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async =>
      setPlayMode(shuffleMode == AudioServiceShuffleMode.none
          ? PlayMode.sequential
          : PlayMode.shuffle);

  // ---- 队列编辑 ----

  void setPlayMode(PlayMode mode) => _edit(() => _q.setMode(mode));
  void append(Track track) => _edit(() => _q.append(track));
  void insertNext(Track track) => _edit(() => _q.insertNext(track));
  void clearExceptCurrent() => _edit(_q.clearExceptCurrent);

  /// 随机模式下拒绝并返回 false
  bool reorder(int from, int to) {
    final ok = _q.reorder(from, to);
    if (ok) _edit(() {});
    return ok;
  }

  /// [index] 为 [PlaybackQueue.tracks] 中的位置; 删除当前曲时自动加载新的当前曲
  Future<void> removeAt(int index) async {
    final wasCurrent = _q.current;
    _q.removeAt(index);
    if (_q.current != wasCurrent) {
      await _loadCurrent(autoplay: engine.playing);
    } else {
      _edit(() {});
    }
  }

  void _edit(void Function() change) {
    change();
    _publishQueue();
    _broadcast();
    _save();
  }

  void _save() => snapshots?.scheduleSave(_q, engine.position);

  void _publishQueue() =>
      queue.add([for (final t in _q.orderedTracks) toMediaItem(t)]);

  void _broadcast() {
    final mode = _q.mode;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (engine.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (engine.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: engine.playing,
      updatePosition: engine.position,
      bufferedPosition: engine.bufferedPosition,
      speed: engine.speed,
      queueIndex: _q.isEmpty ? null : _q.cursor,
      repeatMode: switch (mode) {
        PlayMode.singleLoop => AudioServiceRepeatMode.one,
        PlayMode.listLoop => AudioServiceRepeatMode.all,
        _ => AudioServiceRepeatMode.none,
      },
      shuffleMode: mode == PlayMode.shuffle || mode == PlayMode.smartShuffle
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    ));
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await snapshots?.flush();
    snapshots?.dispose();
    await _errors.close();
    await engine.dispose();
  }

  /// 通知栏/锁屏信息: 标题、歌手、分P、封面 (M4.1)
  static MediaItem toMediaItem(Track t) => MediaItem(
        id: '${t.bvid}_${t.cid}',
        title: t.displayTitle,
        artist: t.displayArtist,
        album: (t.totalPages ?? 1) > 1 ? 'P${t.pageIndex}/${t.totalPages}' : null,
        duration: t.duration,
        artUri: t.cover == null || t.cover!.isEmpty ? null : Uri.tryParse(t.cover!),
        extras: {'bvid': t.bvid, 'cid': t.cid},
      );
}
