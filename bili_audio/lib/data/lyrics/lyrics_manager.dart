import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/lyrics.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
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
    this.autoThreshold = 0.80,
    this.uncertainThreshold = 0.60,
  }) : providers = [...providers]
          ..sort((a, b) => a.priority.compareTo(b.priority));

  final AppDatabase _db;
  final Directory dir;
  final List<LyricsProvider> providers;
  final double autoThreshold;
  final double uncertainThreshold;
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

    final all = <LyricsCandidate>[];
    for (final provider in providers) {
      final candidates = await provider.search(q);
      all.addAll(candidates);
      final best = candidates.isEmpty ? null : candidates.first;
      if (best != null && best.matchScore >= autoThreshold) {
        return LyricsFound(await accept(q, best), fromCache: false);
      }
    }
    all.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    final uncertain =
        all.where((c) => c.matchScore >= uncertainThreshold).toList();
    return uncertain.isNotEmpty
        ? LyricsUncertain(uncertain)
        : LyricsNone(candidates: all);
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
      Duration(milliseconds: await _db.lyricsDao.adjustOffset(bvid, cid, delta));

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
