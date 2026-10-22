// D5: 有意使用 just_audio 实验性 StreamAudioSource 实现边听边存;
// 升级 just_audio 时需回归 test/data/audio/caching_audio_test.dart
// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:bili_audio/core/utils/result.dart';
import 'package:bili_audio/data/bili/bili_stream_api.dart';
import 'package:bili_audio/data/player/audio_engine.dart';
import 'package:bili_audio/data/repositories/repositories.dart';
import 'package:bili_audio/domain/entities/app_error.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/entities/stream_url.dart';
import 'package:just_audio/just_audio.dart';

/// 不依赖平台插件的播放引擎
class FakeEngine implements AudioEngine {
  final sources = <AudioSource>[];
  final positions = <Duration?>[];
  final _events = StreamController<PlaybackEvent>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _state = StreamController<ProcessingState>.broadcast();

  /// 加载时模拟播放器发起首个范围请求 (触发流地址解析)
  bool requestOnLoad = false;

  /// 换源时再报一次播放完成。用来确认切歌不会因此被当成播完而随机跳走。
  bool emitCompletedOnSetSource = false;

  @override
  bool playing = false;
  @override
  Duration position = Duration.zero;
  @override
  ProcessingState processingState = ProcessingState.idle;
  @override
  double speed = 1;

  @override
  Future<void> setSource(
    AudioSource source, {
    Duration? initialPosition,
  }) async {
    sources.add(source);
    positions.add(initialPosition);
    position = initialPosition ?? Duration.zero;
    if (requestOnLoad) await (source as StreamAudioSource).request(0, 1);
    processingState = ProcessingState.ready;
    if (emitCompletedOnSetSource) {
      processingState = ProcessingState.completed;
      _state.add(ProcessingState.completed);
    }
  }

  @override
  Future<void> play() async => _playing.add(playing = true);
  @override
  Future<void> pause() async => _playing.add(playing = false);
  @override
  Future<void> stop() async {
    playing = false;
    processingState = ProcessingState.idle;
  }

  @override
  Future<void> seek(Duration p) async => position = p;
  @override
  Future<void> setSpeed(double s) async => speed = s;
  @override
  Future<void> setVolume(double v) async {}
  @override
  Future<void> dispose() async {}

  /// 模拟当前曲播放结束
  Future<void> complete() async {
    processingState = ProcessingState.completed;
    _state.add(ProcessingState.completed);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  Duration? get duration => null;
  @override
  Stream<PlaybackEvent> get playbackEventStream => _events.stream;
  @override
  Stream<bool> get playingStream => _playing.stream;
  @override
  Stream<ProcessingState> get processingStateStream => _state.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
}

class CountingStreamRepository implements StreamRepository {
  final resolved = <String>[];
  AppError? failWith;

  @override
  Future<Result<StreamSelection>> resolve(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) async {
    resolved.add(track.bvid);
    if (failWith != null) return Result.failure(failWith!);
    return Result.success((
      stream: StreamUrl(
        bvid: track.bvid,
        cid: track.cid,
        quality: quality,
        url: 'https://cdn/${track.bvid}',
        expiresAt: 0,
      ),
      downgradedForGuest: false,
    ));
  }

  @override
  Future<Result<StreamSelection>> refresh(
    Track track,
    AudioQuality quality, {
    bool loggedIn = false,
  }) => resolve(track, quality, loggedIn: loggedIn);
}

List<Track> makeTracks(int n) => [
  for (var i = 0; i < n; i++)
    Track(
      bvid: 'BV$i',
      cid: i,
      title: 'T$i',
      artist: 'A${i % 3}',
      duration: const Duration(minutes: 3),
    ),
];
