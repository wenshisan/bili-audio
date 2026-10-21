import 'package:just_audio/just_audio.dart';

/// 播放引擎抽象 (M3.3)
///
/// 隔离 just_audio 的平台依赖, 让 [BiliAudioHandler] 可以用 Fake 引擎单测。
/// 桌面端 (Windows/Linux) 由 `just_audio_media_kit` 提供实现 (D4), 接口不变。
abstract interface class AudioEngine {
  Future<void> setSource(AudioSource source, {Duration? initialPosition});
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setVolume(double volume);
  Future<void> dispose();

  bool get playing;
  double get speed;
  Duration get position;
  Duration get bufferedPosition;
  Duration? get duration;
  ProcessingState get processingState;

  Stream<PlaybackEvent> get playbackEventStream;
  Stream<bool> get playingStream;
  Stream<ProcessingState> get processingStateStream;
  Stream<Duration> get positionStream;
}

/// 基于 just_audio [AudioPlayer] 的实现 (M3.3)
class JustAudioEngine implements AudioEngine {
  JustAudioEngine([AudioPlayer? player]) : _p = player ?? AudioPlayer();

  final AudioPlayer _p;

  @override
  Future<void> setSource(AudioSource source, {Duration? initialPosition}) =>
      _p.setAudioSource(source, initialPosition: initialPosition);
  @override
  Future<void> play() => _p.play();
  @override
  Future<void> pause() => _p.pause();
  @override
  Future<void> stop() => _p.stop();
  @override
  Future<void> seek(Duration position) => _p.seek(position);
  @override
  Future<void> setSpeed(double speed) => _p.setSpeed(speed);
  @override
  Future<void> setVolume(double volume) => _p.setVolume(volume);
  @override
  Future<void> dispose() => _p.dispose();

  @override
  bool get playing => _p.playing;
  @override
  double get speed => _p.speed;
  @override
  Duration get position => _p.position;
  @override
  Duration get bufferedPosition => _p.bufferedPosition;
  @override
  Duration? get duration => _p.duration;
  @override
  ProcessingState get processingState => _p.processingState;

  @override
  Stream<PlaybackEvent> get playbackEventStream => _p.playbackEventStream;
  @override
  Stream<bool> get playingStream => _p.playingStream;
  @override
  Stream<ProcessingState> get processingStateStream =>
      _p.processingStateStream;
  @override
  Stream<Duration> get positionStream => _p.positionStream;
}
