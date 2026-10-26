import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/logging/app_logger.dart';
import '../../domain/album/album_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import '../../domain/title/title_cleaner.dart';

/// 专辑查询结果。
sealed class AlbumResult {
  const AlbumResult();
}

/// 已匹配到官方专辑图、年份或介绍。缺的字段留空。
class AlbumFound extends AlbumResult {
  const AlbumFound({
    this.albumName,
    this.year,
    this.description,
    this.coverUrl,
    this.coverSource,
    this.descriptionSource,
    this.matchScore = 0,
    required this.fromCache,
  });

  final String? albumName;
  final int? year;
  final String? description;
  final String? coverUrl;
  final String? coverSource;
  final String? descriptionSource;
  final double matchScore;
  final bool fromCache;
}

/// 各源都对不上，或上次已经确认没有资料。
class AlbumNone extends AlbumResult {
  const AlbumNone({this.fromCache = false});

  final bool fromCache;
}

/// 专辑资料管理器。
///
/// 按优先级问各个源。封面、年份、介绍各自取第一个得分够高的结果，
/// 所以图和介绍可以来自不同的源。三项都齐了就不再往下问。
class AlbumManager {
  AlbumManager(
    this.dir, {
    required List<AlbumProvider> providers,
    this.cleaner,
    this.autoThreshold = 0.80,
  }) : providers = [...providers]
         ..sort((a, b) => a.priority.compareTo(b.priority));

  /// 2: 四位分 P 序号以前留在歌名里，当时记成「没有专辑」的结果要重查。
  static const _cacheVersion = 2;

  final Directory dir;
  final List<AlbumProvider> providers;
  final TitleCleaner? cleaner;
  final double autoThreshold;
  final LyricsScorer _scorer = LyricsScorer();
  final Map<String, Future<AlbumResult>> _inflight = {};

  Future<AlbumResult> find(AlbumQuery q) {
    final key = '${q.bvid}_${q.cid}';
    return _inflight[key] ??= _find(q).whenComplete(() {
      _inflight.remove(key);
    });
  }

  Future<AlbumResult> _find(AlbumQuery q) async {
    final cached = await _fromCache(q.bvid, q.cid);
    if (cached != null) return cached;

    final identity = _primary(q);
    final attempts = _attempts(q, identity);
    if (attempts.isEmpty) {
      await _saveNone(q);
      return const AlbumNone();
    }
    final first = attempts.first;
    AppLogger.i(
      'album search "${first.title}" artist="${first.artist ?? ''}"',
      tag: 'album',
    );

    AlbumCandidate? cover;
    AlbumCandidate? text;
    AlbumCandidate? dated;
    var responded = false;

    bool compatible(AlbumCandidate hit) {
      final anchor = cover ?? text ?? dated;
      if (anchor == null || identical(anchor, hit)) return true;
      return _sameAlbum(anchor.albumName, hit.albumName);
    }

    void consider(AlbumCandidate hit) {
      if (hit.matchScore < autoThreshold) return;
      if (cover == null && _filled(hit.coverUrl) && compatible(hit)) {
        cover = hit;
      }
      if (text == null && _filled(hit.description) && compatible(hit)) {
        text = hit;
      }
      if (dated == null && hit.year != null && compatible(hit)) dated = hit;
    }

    for (final provider in providers) {
      final batch = await _collect(
        provider,
        attempts,
        identity,
        q.duration.inSeconds,
      );
      if (batch.responded) responded = true;
      for (final hit in batch.hits) {
        consider(hit);
      }
      if (cover != null && text != null && dated != null) break;
    }

    if (!responded) return const AlbumNone();

    final found = _compose(cover, text, dated);
    if (found == null) {
      AppLogger.i(
        'album none "${first.title}" artist="${first.artist ?? ''}"',
        tag: 'album',
      );
      await _saveNone(q);
      return const AlbumNone();
    }
    AppLogger.i(
      'album matched cover=${found.coverSource ?? '-'} '
      'text=${found.descriptionSource ?? '-'} year=${found.year ?? '-'} '
      'album="${found.albumName ?? ''}"',
      tag: 'album',
    );
    await _save(q, found);
    return found;
  }

  Future<({List<AlbumCandidate> hits, bool responded})> _collect(
    AlbumProvider provider,
    List<AlbumQuery> attempts,
    ({String title, String? artist}) identity,
    int durationSeconds,
  ) async {
    final hits = <AlbumCandidate>[];
    var responded = false;
    for (final attempt in attempts) {
      List<AlbumCandidate>? raw;
      var down = false;
      for (var retry = 0; retry < 2; retry++) {
        try {
          raw = await provider.search(attempt);
          responded = true;
          break;
        } on AlbumSourceUnavailable catch (e) {
          AppLogger.w(
            'album ${provider.name} retry=$retry failed: $e',
            tag: 'album',
          );
          if (retry == 1) down = true;
        }
      }
      if (down || raw == null) break;
      for (final item in raw) {
        final aligned = _align(item, identity, durationSeconds);
        if (aligned != null) hits.add(aligned);
      }
      if (hits.any(_selfContained)) break;
    }
    hits.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return (hits: hits, responded: responded);
  }

  AlbumCandidate? _align(
    AlbumCandidate candidate,
    ({String title, String? artist}) identity,
    int durationSeconds,
  ) {
    final title = candidate.title.trim();
    if (title.isEmpty) return null;
    final aligned = _scorer.pick(
      trackTitle: identity.title,
      trackArtist: identity.artist ?? '',
      trackDuration: durationSeconds,
      lyricsTitle: title,
      lyricsArtist: candidate.artist,
      lyricsDuration: candidate.durationSeconds,
    );
    if (aligned == null) return null;
    final score = aligned < candidate.matchScore
        ? aligned
        : candidate.matchScore;
    return candidate.withScore(score);
  }

  bool _selfContained(AlbumCandidate hit) =>
      hit.matchScore >= autoThreshold &&
      _filled(hit.coverUrl) &&
      _filled(hit.description) &&
      hit.year != null;

  AlbumFound? _compose(
    AlbumCandidate? cover,
    AlbumCandidate? text,
    AlbumCandidate? dated,
  ) {
    final coverUrl = _text(cover?.coverUrl);
    final description = _text(text?.description);
    final year = cover?.year ?? text?.year ?? dated?.year;
    if (coverUrl == null && description == null && year == null) return null;
    final scores = <double>[
      if (coverUrl != null && cover != null) cover.matchScore,
      if (description != null && text != null) text.matchScore,
      if (year != null && dated != null) dated.matchScore,
    ];
    return AlbumFound(
      albumName: _albumName(cover, text, dated),
      year: year,
      description: description,
      coverUrl: coverUrl,
      coverSource: coverUrl == null ? null : cover?.source,
      descriptionSource: description == null ? null : text?.source,
      matchScore: scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b),
      fromCache: false,
    );
  }

  String? _albumName(
    AlbumCandidate? cover,
    AlbumCandidate? text,
    AlbumCandidate? dated,
  ) {
    for (final candidate in [cover, text, dated]) {
      final name = _text(candidate?.albumName);
      if (name != null) return name;
    }
    return null;
  }

  Future<void> invalidate(String bvid, int cid) async {
    final file = _file(bvid, cid);
    if (file.existsSync()) await file.delete();
  }

  Future<AlbumResult?> _fromCache(String bvid, int cid) async {
    final file = _file(bvid, cid);
    if (!file.existsSync()) return null;
    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } catch (_) {
      await file.delete();
      return null;
    }
    if (decoded is! Map) return null;
    if (decoded['v'] != _cacheVersion) {
      await file.delete();
      return null;
    }
    if (decoded['none'] == true) return const AlbumNone(fromCache: true);
    final cover = _text(decoded['coverUrl'] as String?);
    final description = _text(decoded['description'] as String?);
    final year = decoded['year'];
    final parsedYear = year is num ? year.toInt() : null;
    if (cover == null && description == null && parsedYear == null) {
      return const AlbumNone(fromCache: true);
    }
    final score = decoded['score'];
    return AlbumFound(
      albumName: _text(decoded['albumName'] as String?),
      year: parsedYear,
      description: description,
      coverUrl: cover,
      coverSource: _text(decoded['coverSource'] as String?),
      descriptionSource: _text(decoded['descriptionSource'] as String?),
      matchScore: score is num ? score.toDouble() : 0,
      fromCache: true,
    );
  }

  Future<void> _save(AlbumQuery q, AlbumFound found) async {
    await dir.create(recursive: true);
    await _file(q.bvid, q.cid).writeAsString(
      jsonEncode({
        'v': _cacheVersion,
        'none': false,
        'albumName': found.albumName,
        'year': found.year,
        'description': found.description,
        'coverUrl': found.coverUrl,
        'coverSource': found.coverSource,
        'descriptionSource': found.descriptionSource,
        'score': found.matchScore,
      }),
    );
  }

  Future<void> _saveNone(AlbumQuery q) async {
    await dir.create(recursive: true);
    await _file(
      q.bvid,
      q.cid,
    ).writeAsString(jsonEncode({'v': _cacheVersion, 'none': true}));
  }

  File _file(String bvid, int cid) =>
      File(p.join(dir.path, '${bvid}_$cid.json'));

  bool _filled(String? value) => _text(value) != null;

  String? _text(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  bool _sameAlbum(String? a, String? b) {
    final left = _normAlbum(a);
    final right = _normAlbum(b);
    if (left.isEmpty || right.isEmpty) return true;
    if (left == right) return true;
    final shorter = left.length <= right.length ? left : right;
    final longer = left.length <= right.length ? right : left;
    return shorter.length >= 2 && longer.contains(shorter);
  }

  String _normAlbum(String? raw) => (raw ?? '').toLowerCase().replaceAll(
    RegExp(r'''[\s\-—_()（）【】\[\]·.]+'''),
    '',
  );

  List<AlbumQuery> _attempts(
    AlbumQuery q,
    ({String title, String? artist}) primary,
  ) {
    final out = <AlbumQuery>[];

    void add(String title, String? artist, {required bool omitArtistFilter}) {
      final corpus = TitleCleaner.searchCorpus(title, artist: artist);
      final name = corpus.title.trim();
      if (name.isEmpty) return;
      final normArtist = corpus.artist;
      final omit = omitArtistFilter && normArtist != null;
      final key = _searchKey(name, normArtist, omit: omit);
      final exists = out.any(
        (e) => _searchKey(e.title, e.artist, omit: e.omitArtistFilter) == key,
      );
      if (exists) return;
      out.add(
        AlbumQuery(
          bvid: q.bvid,
          cid: q.cid,
          title: name,
          artist: normArtist,
          duration: q.duration,
          omitArtistFilter: omit,
        ),
      );
    }

    final title = primary.title;
    final artist = primary.artist;
    add(title, artist, omitArtistFilter: false);
    add(title, artist, omitArtistFilter: true);
    final stored = q.title.trim();
    if (stored.isNotEmpty && stored != title) {
      add(stored, q.artist, omitArtistFilter: false);
    }
    final raw = q.rawTitle?.trim();
    final source = (raw != null && raw.isNotEmpty) ? raw : q.title;
    if (artist != null && artist != title && !_songInQuotes(source, title)) {
      add(artist, title, omitArtistFilter: false);
    }
    return out.length > 4 ? out.sublist(0, 4) : out;
  }

  bool _songInQuotes(String raw, String title) {
    if (title.isEmpty) return false;
    return RegExp('[《「『]${RegExp.escape(title)}[》」』]').hasMatch(raw);
  }

  (String, String?, bool) _searchKey(
    String title,
    String? artist, {
    required bool omit,
  }) {
    final loose = TitleCleaner.parseLoose(title);
    final name = loose.name.trim().isEmpty ? title.trim() : loose.name.trim();
    final given = artist?.trim();
    final who = (given != null && given.isNotEmpty) ? given : loose.artist;
    final normWho = (who == null || who.trim().isEmpty) ? null : who.trim();
    return (name, normWho, omit && normWho != null);
  }

  ({String title, String? artist}) _primary(AlbumQuery q) {
    final raw = q.rawTitle?.trim();
    final source = (raw != null && raw.isNotEmpty) ? raw : q.title;
    final loose = TitleCleaner.searchCorpus(source);
    final fresh = cleaner?.clean(source);
    final freshName = fresh?.name.trim() ?? '';
    final looseName = loose.title.trim();
    final useFresh =
        freshName.isNotEmpty &&
        (looseName.isEmpty || freshName.length < looseName.length);
    final name = useFresh
        ? freshName
        : (looseName.isEmpty ? q.title.trim() : looseName);
    final parsedArtist = useFresh ? fresh?.artist : loose.artist;
    final artist = (parsedArtist != null && parsedArtist.trim().isNotEmpty)
        ? parsedArtist.trim()
        : q.artist;
    return (title: name, artist: artist);
  }
}
