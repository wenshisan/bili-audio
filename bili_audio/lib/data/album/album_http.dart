import 'package:dio/dio.dart';

import '../../domain/album/album_provider.dart';
import '../../domain/title/title_cleaner.dart';
import '../lyrics/lyrics_http.dart';

export '../lyrics/lyrics_http.dart' show lyricsClient, lyricsRequestOptions;

/// 把搜索词收成歌名、歌手和实际发给远端的关键词。
({String title, String artist, String keyword}) albumTerms(AlbumQuery query) {
  final loose = TitleCleaner.parseLoose(query.title);
  final title = loose.name.trim().isEmpty
      ? query.title.trim()
      : loose.name.trim();
  final given = query.artist?.trim();
  final parsed = loose.artist?.trim();
  final artist = (given != null && given.isNotEmpty)
      ? given
      : (parsed != null && parsed.isNotEmpty ? parsed : '');
  final filtered = !query.omitArtistFilter && artist.isNotEmpty;
  final keyword = [title, if (filtered) artist].join(' ');
  return (title: title, artist: artist, keyword: keyword);
}

/// 超时或连不上时抛出，让管理器重试并换下一个源。
void throwIfAlbumTransport(DioException error, String source) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      throw AlbumSourceUnavailable('$source ${error.type.name}');
    default:
      return;
  }
}
