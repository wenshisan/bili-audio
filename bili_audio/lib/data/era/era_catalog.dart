import '../../core/utils/result.dart';
import '../repositories/repositories.dart';

/// 某一年代里的一首歌，只描述曲目，不带播放地址。
class EraTrack {
  const EraTrack({
    required this.name,
    required this.artist,
    required this.duration,
  });

  final String name;
  final String artist;
  final Duration duration;
}

typedef EraCatalogPage = ({
  List<EraTrack> tracks,
  int page,
  int total,
  bool hasMore,
});

/// 年代歌单。播放仍由 B 站搜索这些歌名来完成。
abstract interface class EraCatalog {
  Future<Result<EraCatalogPage>> page(DiscoverTab tab, {int page = 1});
}
