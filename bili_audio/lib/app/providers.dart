import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/player/bili_audio_handler.dart';
import '../data/repositories/repositories.dart';
import '../domain/entities/audio_track.dart';

/// 全局依赖 (M6)
///
/// 默认实现直接抛错: 真实依赖在 `bootstrap()` 中构建并 override,
/// 测试中用 Fake 仓储 + Fake 引擎 override, UI 只依赖接口。
Never _notOverridden(String name) =>
    throw UnimplementedError('$name 必须在 ProviderScope overrides 中提供');

/// 播放器在每次加载曲目时读取的偏好 (设置页 / 登录后修改)
class PlaybackPrefs {
  PlaybackPrefs({this.quality = AudioQuality.k132, this.loggedIn = false});

  AudioQuality quality;
  bool loggedIn;
}

final playbackPrefsProvider = Provider<PlaybackPrefs>((ref) => PlaybackPrefs());

final databaseProvider =
    Provider<AppDatabase>((ref) => _notOverridden('databaseProvider'));

final searchRepositoryProvider =
    Provider<SearchRepository>((ref) => _notOverridden('searchRepositoryProvider'));

final videoRepositoryProvider =
    Provider<VideoRepository>((ref) => _notOverridden('videoRepositoryProvider'));

final audioHandlerProvider =
    Provider<BiliAudioHandler>((ref) => _notOverridden('audioHandlerProvider'));

/// 播放状态 (播放/暂停/缓冲、模式、队列索引)
final playbackStateProvider = StreamProvider<PlaybackState>(
  (ref) => ref.watch(audioHandlerProvider).playbackState,
);

/// 当前曲目 (通知栏同款信息)
final mediaItemProvider = StreamProvider<MediaItem?>(
  (ref) => ref.watch(audioHandlerProvider).mediaItem,
);

/// 当前播放顺序的队列
final queueItemsProvider = StreamProvider<List<MediaItem>>(
  (ref) => ref.watch(audioHandlerProvider).queue,
);

/// 播放进度 (约 200ms 一次)
final positionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(audioHandlerProvider).engine.positionStream,
);
