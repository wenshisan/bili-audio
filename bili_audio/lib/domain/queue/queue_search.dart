import '../entities/audio_track.dart';
import '../text_normalization.dart';

final _asciiLetters = RegExp(r'^[a-z]+$');

/// 超过这个长度时，拼音索引放到后台建，避免卡住输入。
const queueSearchSyncLimit = 200;

/// 查询在归一化后是否还有可匹配的内容。
bool queueSearchHasQuery(String query) => normalizeForMatch(query).isNotEmpty;

/// 一条曲目预先算好的搜索文本。
class QueueSearchHaystack {
  const QueueSearchHaystack(this.normalized, this.pinyin, this.initials);

  final List<String> normalized;
  final List<String> pinyin;
  final List<String> initials;

  factory QueueSearchHaystack.fromFields(List<String> fields) {
    final normalized = [for (final field in fields) normalizeForMatch(field)];
    return QueueSearchHaystack(
      normalized,
      [for (final field in normalized) toPinyin(field)],
      [for (final field in fields) toPinyinInitials(field)],
    );
  }
}

/// 给后台 isolate 用。入参是每首曲目的原始字段。
List<QueueSearchHaystack> buildQueueSearchHaystacks(List<List<String>> fields) {
  return [for (final group in fields) QueueSearchHaystack.fromFields(group)];
}

/// 当前播放顺序的搜索索引。字面量可立即用，拼音可以稍后补上。
class QueueSearchIndex {
  QueueSearchIndex._(this._haystacks, {required this.pinyinReady});

  final List<QueueSearchHaystack> _haystacks;

  /// 为 false 时还不能按拼音或首字母匹配。
  final bool pinyinReady;

  int get length => _haystacks.length;

  /// 同步建好字面量和拼音。短队列用这个。
  factory QueueSearchIndex.sync(List<Track> tracks) {
    return QueueSearchIndex.ready(buildQueueSearchHaystacks(capture(tracks)));
  }

  /// 只建字面量，输入中文或英文原文时就能过滤。
  factory QueueSearchIndex.literal(List<Track> tracks) {
    return QueueSearchIndex._([
      for (final track in tracks)
        QueueSearchHaystack(
          [
            for (final field in queueSearchFields(track))
              normalizeForMatch(field),
          ],
          const [],
          const [],
        ),
    ], pinyinReady: false);
  }

  factory QueueSearchIndex.ready(List<QueueSearchHaystack> haystacks) {
    return QueueSearchIndex._(haystacks, pinyinReady: true);
  }

  static List<List<String>> capture(List<Track> tracks) => [
    for (final track in tracks) queueSearchFields(track),
  ];

  /// 拼音还没算完，而这个查询又要用拼音。
  bool pending(String query) => !pinyinReady && _needsPinyin(query);

  List<int> match(String query) {
    final tokens = _tokens(query);
    if (tokens.isEmpty) {
      return List<int>.generate(length, (index) => index);
    }
    final hits = <int>[];
    for (var i = 0; i < length; i++) {
      if (_matches(_haystacks[i], tokens)) hits.add(i);
    }
    return hits;
  }

  bool _matches(QueueSearchHaystack haystack, List<String> tokens) {
    for (final token in tokens) {
      final fuzzy = pinyinReady && _tokenNeedsPinyin(token);
      final tokenPinyin = fuzzy ? toPinyin(token) : '';
      var hit = false;
      for (var i = 0; i < haystack.normalized.length; i++) {
        if (haystack.normalized[i].contains(token) ||
            (fuzzy &&
                tokenPinyin.isNotEmpty &&
                haystack.pinyin[i].contains(tokenPinyin)) ||
            (fuzzy && haystack.initials[i].contains(token))) {
          hit = true;
          break;
        }
      }
      if (!hit) return false;
    }
    return true;
  }
}

/// 当前播放顺序里匹配 [query] 的下标。空查询返回全部下标。
///
/// 歌名、原始标题、歌手和 UP 主都参与匹配。忽略大小写和标点。
/// 至少两个字符时同时按全拼和首字母匹配，例如「zhou」或「zjl」对应「周杰伦」。
/// 多个词都要命中，可以分别落在歌名和歌手上。
List<int> matchingQueueIndices(List<Track> ordered, String query) {
  return QueueSearchIndex.sync(ordered).match(query);
}

/// [track] 是否匹配队列内搜索 [query]。
bool trackMatchesQueueQuery(Track track, String query) {
  return matchingQueueIndices([track], query).isNotEmpty;
}

List<String> queueSearchFields(Track track) {
  final fields = <String>[track.displayTitle];
  if (track.title != track.displayTitle) fields.add(track.title);
  fields.add(track.displayArtist);
  final artist = track.artist;
  if (artist != null && artist.isNotEmpty && artist != track.displayArtist) {
    fields.add(artist);
  }
  final uploader = track.uploader;
  if (uploader != null &&
      uploader.isNotEmpty &&
      uploader != track.displayArtist &&
      uploader != artist) {
    fields.add(uploader);
  }
  return fields;
}

bool _needsPinyin(String query) => _tokens(query).any(_tokenNeedsPinyin);

bool _tokenNeedsPinyin(String token) =>
    token.length >= 2 && _asciiLetters.hasMatch(token);

List<String> _tokens(String query) {
  return normalizeForMatch(query)
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList();
}
