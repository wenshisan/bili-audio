import 'package:dio/dio.dart';

import '../../domain/album/album_provider.dart';
import '../../domain/title/title_cleaner.dart';

export '../lyrics/lyrics_http.dart' show lyricsClient, lyricsRequestOptions;

/// 先抽出歌名和歌手，再拼实际发给远端的关键词。
({String title, String artist, String keyword}) albumTerms(AlbumQuery query) {
  final corpus = TitleCleaner.searchCorpus(query.title, artist: query.artist);
  final title = corpus.title;
  final artist = corpus.artist ?? '';
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
