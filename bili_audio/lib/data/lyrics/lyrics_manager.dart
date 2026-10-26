import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/logging/app_logger.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../domain/lyrics/lyrics_scorer.dart';
import '../../domain/title/title_cleaner.dart';
import '../db/app_database.dart';

/// 歌词查询结果 (M5.4)
sealed class LyricsResult {
  const LyricsResult();
}

/// 已匹配: [lyrics.offset] 已合并 LRC 自带 offset 与用户校准偏移
class LyricsFound extends LyricsResult {
  const LyricsFound(this.lyrics, {required this.fromCache});
  final Lyrics lyrics;
  final bool fromCache;
}

/// 得分在 0.60-0.80 之间, 需要用户确认
class LyricsUncertain extends LyricsResult {
  const LyricsUncertain(this.candidates);
  final List<LyricsCandidate> candidates;
}

/// 无歌词 (用户标记, 或所有候选得分过低)
class LyricsNone extends LyricsResult {
  const LyricsNone({this.candidates = const [], this.markedByUser = false});
  final List<LyricsCandidate> candidates;
  final bool markedByUser;
}

/// 歌词管理器 (M5.3 / M5.4)
///
/// 1. 查 `lyrics_cache`: 命中则读本地 LRC, `no_lyrics` 直接返回无歌词
/// 2. 否则按优先级依次查询远程提供者, 首个 ≥ [autoThreshold] 即采用并缓存
/// 3. 同一曲目的并发查询合并
class LyricsManager {
  LyricsManager(
    this._db,
    this.dir, {
    required List<LyricsProvider> providers,
    this.cleaner,
    this.autoThreshold = 0.80,
    this.uncertainThreshold = 0.60,
  }) : providers = [...providers]
         ..sort((a, b) => a.priority.compareTo(b.priority));

  final AppDatabase _db;
  final Directory dir;
  final List<LyricsProvider> providers;
  final TitleCleaner? cleaner;
  final double autoThreshold;
  final double uncertainThreshold;
  final LyricsScorer _scorer = LyricsScorer();
  final Map<String, Future<LyricsResult>> _inflight = {};

  Future<LyricsResult> find(LyricsQuery q) {
    final key = '${q.bvid}_${q.cid}';
    return _inflight[key] ??= _find(q).whenComplete(() {
      _inflight.remove(key);
    });
  }

  Future<LyricsResult> _find(LyricsQuery q) async {
    final cached = await _fromCache(q.bvid, q.cid);
    if (cached != null) return cached;

    final identity = _primary(q);
    final attempts = _attempts(q, identity);
    if (attempts.isEmpty) return const LyricsNone();
    final first = attempts.first;
    AppLogger.i(
      'search "${first.title}" artist="${first.artist ?? ''}" '
      'from="${q.rawTitle ?? q.title}"',
      tag: 'lyrics',
    );

    final all = <LyricsCandidate>[];
    for (final provider in providers) {
      var sourceDown = false;
      for (final attempt in attempts) {
        List<LyricsCandidate>? candidates;
        for (var retry = 0; retry < 2; retry++) {
          try {
            candidates = await provider.search(attempt);
            break;
          } on LyricsSourceUnavailable catch (e) {
            AppLogger.w(
              'lyrics ${provider.name} retry=$retry failed: $e',
              tag: 'lyrics',
            );
            if (retry == 1) sourceDown = true;
          }
        }
        if (sourceDown || candidates == null) break;
        _mergeCandidates(
          all,
          _relevant(candidates, identity, q.duration.inSeconds),
        );
        final best = candidates.isEmpty ? null : candidates.first;
        if (best != null && best.matchScore >= autoThreshold) {
          AppLogger.i(
            'matched ${provider.name} "${attempt.title}" -> '
            '${best.originalTitle ?? ''} / ${best.originalArtist ?? ''} '
            'score=${best.matchScore.toStringAsFixed(2)}',
            tag: 'lyrics',
          );
          return LyricsFound(await accept(q, best), fromCache: false);
        }
      }
    }
    all.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    final top = all.isEmpty ? null : all.first.matchScore;
    AppLogger.i(
      'no match "${first.title}" artist="${first.artist ?? ''}" '
      'best=${top == null ? '-' : top.toStringAsFixed(2)}',
      tag: 'lyrics',
    );
    final uncertain = all
        .where((c) => c.matchScore >= uncertainThreshold)
        .toList();
    return uncertain.isNotEmpty
        ? LyricsUncertain(uncertain)
        : LyricsNone(candidates: all);
  }

  /// 先抽出歌名和歌手再搜索。艺人过滤落空时再去掉过滤重试。
  /// 书名号已经写明歌名时不再把歌手当成歌名去搜。
  List<LyricsQuery> _attempts(
    LyricsQuery q,
    ({String title, String? artist}) primary,
  ) {
    final out = <LyricsQuery>[];

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
        LyricsQuery(
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

  /// 没有带上真实歌名的结果不进待选。来源没给歌名时保留原得分。
  List<LyricsCandidate> _relevant(
    List<LyricsCandidate> raw,
    ({String title, String? artist}) identity,
    int durationSeconds,
  ) {
    final kept = <LyricsCandidate>[];
    for (final candidate in raw) {
      final lyricsTitle = candidate.originalTitle?.trim() ?? '';
      if (lyricsTitle.isEmpty) {
        kept.add(candidate);
        continue;
      }
      final aligned = _scorer.pick(
        trackTitle: identity.title,
        trackArtist: identity.artist ?? '',
        trackDuration: durationSeconds,
        lyricsTitle: lyricsTitle,
        lyricsArtist: candidate.originalArtist ?? '',
        lyricsDuration: durationSeconds,
      );
      if (aligned == null) continue;
      final score = aligned < candidate.matchScore
          ? aligned
          : candidate.matchScore;
      kept.add(
        LyricsCandidate(
          lyrics: candidate.lyrics.copyWith(matchScore: score),
          source: candidate.source,
          matchScore: score,
          originalTitle: candidate.originalTitle,
          originalArtist: candidate.originalArtist,
          lrcText: candidate.lrcText,
        ),
      );
    }
    return kept;
  }

  bool _songInQuotes(String raw, String title) {
    if (title.isEmpty) return false;
    return RegExp('[《「『]${RegExp.escape(title)}[》」』]').hasMatch(raw);
  }

  /// 原标题和清洗结果指向同一首歌时只搜一次。
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

  ({String title, String? artist}) _primary(LyricsQuery q) {
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

  void _mergeCandidates(List<LyricsCandidate> all, List<LyricsCandidate> next) {
    for (final candidate in next) {
      final index = all.indexWhere(
        (e) =>
            e.source == candidate.source &&
            e.originalTitle == candidate.originalTitle &&
            e.originalArtist == candidate.originalArtist,
      );
      if (index < 0) {
        all.add(candidate);
      } else if (candidate.matchScore > all[index].matchScore) {
        all[index] = candidate;
      }
    }
  }

  Future<LyricsResult?> _fromCache(String bvid, int cid) async {
    final row = await _db.lyricsDao.get(bvid, cid);
    if (row == null) return null;
    if (row.noLyrics) return const LyricsNone(markedByUser: true);
    final path = row.lrcPath;
    if (path == null) return null;
    final file = File(p.join(dir.path, path));
    if (!file.existsSync()) return null;
    final lyrics = LrcParser.parse(await file.readAsString());
    return LyricsFound(
      lyrics.copyWith(
        offset: lyrics.offset + Duration(milliseconds: row.offsetMs),
        source: row.source,
        matchScore: row.matchScore,
      ),
      fromCache: true,
    );
  }

  /// 采用候选 (自动匹配或用户手动选择): 写 LRC 文件与索引
  Future<Lyrics> accept(LyricsQuery q, LyricsCandidate c) async {
    final name = '${q.bvid}_${q.cid}.lrc';
    await dir.create(recursive: true);
    final text = c.lrcText;
    if (text != null) await File(p.join(dir.path, name)).writeAsString(text);
    await _db.lyricsDao.saveMatch(
      bvid: q.bvid,
      cid: q.cid,
      lrcPath: name,
      source: c.source,
      score: c.matchScore,
    );
    final row = await _db.lyricsDao.get(q.bvid, q.cid);
    return c.lyrics.copyWith(
      offset: c.lyrics.offset + Duration(milliseconds: row?.offsetMs ?? 0),
    );
  }

  Future<void> markNoLyrics(String bvid, int cid) =>
      _db.lyricsDao.markNoLyrics(bvid, cid);

  /// 调整用户偏移 (0.1s 步进由 UI 控制)
  Future<Duration> adjustOffset(String bvid, int cid, Duration delta) async =>
      Duration(
        milliseconds: await _db.lyricsDao.adjustOffset(bvid, cid, delta),
      );

  /// 清除缓存 (编辑歌名后重新匹配)
  Future<void> invalidate(String bvid, int cid) async {
    final row = await _db.lyricsDao.get(bvid, cid);
    final path = row?.lrcPath;
    if (path != null) {
      final f = File(p.join(dir.path, path));
      if (f.existsSync()) await f.delete();
    }
    await _db.lyricsDao.clear(bvid, cid);
  }
}
