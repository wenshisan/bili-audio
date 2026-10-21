import 'dart:io';

import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/lyrics/lyrics_manager.dart';
import 'package:bili_audio/domain/lyrics/lrc_parser.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubProvider implements LyricsProvider {
  _StubProvider(this.name, this.priority, this.scores);

  @override
  final String name;
  @override
  final int priority;
  final List<double> scores;
  int calls = 0;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery q) async {
    calls++;
    return [
      for (final s in scores)
        LyricsCandidate(
          lyrics: LrcParser.parse('[00:01.00]$name $s'),
          source: name,
          matchScore: s,
          lrcText: '[00:01.00]$name $s',
        ),
    ];
  }
}

void main() {
  late AppDatabase db;
  late Directory dir;
  const q = LyricsQuery(
    bvid: 'BV1',
    cid: 1,
    title: '七里香',
    duration: Duration(seconds: 299),
  );

  setUp(() async {
    db = AppDatabase.memory();
    dir = await Directory.systemTemp.createTemp('lyrics_');
    await db.tracksDao.ensureTrack(
        TracksCompanion.insert(bvid: 'BV1', cid: 1, title: 't', duration: 299));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  LyricsManager manager(List<LyricsProvider> providers) =>
      LyricsManager(db, dir, providers: providers);

  test('按优先级查询, 首个 ≥0.80 即停止并缓存', () async {
    final a = _StubProvider('a', 1, [0.9]);
    final b = _StubProvider('b', 2, [0.95]);
    final m = manager([b, a]);

    final r = await m.find(q);
    expect(r, isA<LyricsFound>());
    expect((r as LyricsFound).lyrics.lines.single.text, 'a 0.9');
    expect(b.calls, 0);

    // 第二次命中本地缓存, 不再调用提供者
    final again = await m.find(q);
    expect((again as LyricsFound).fromCache, true);
    expect(a.calls, 1);
  });

  test('得分 0.60-0.80 返回待确认候选; <0.60 返回无歌词', () async {
    expect(await manager([_StubProvider('a', 1, [0.7, 0.5])]).find(q),
        isA<LyricsUncertain>());
    final none = await manager([_StubProvider('a', 1, [0.5])]).find(q);
    expect(none, isA<LyricsNone>());
    expect((none as LyricsNone).markedByUser, false);
  });

  test('"无歌词"标记后不再搜索', () async {
    final a = _StubProvider('a', 1, [0.9]);
    final m = manager([a]);
    await m.markNoLyrics('BV1', 1);
    final r = await m.find(q);
    expect((r as LyricsNone).markedByUser, true);
    expect(a.calls, 0);
  });

  test('偏移量累加并持久化, 重新读取后生效', () async {
    final m = manager([_StubProvider('a', 1, [0.9])]);
    await m.find(q);
    await m.adjustOffset('BV1', 1, const Duration(milliseconds: 300));
    await m.adjustOffset('BV1', 1, const Duration(milliseconds: -100));

    final fresh = manager([]);
    final r = await fresh.find(q) as LyricsFound;
    expect(r.lyrics.offset, const Duration(milliseconds: 200));
  });

  test('手动选择候选后写入缓存; invalidate 删除文件与索引', () async {
    final m = manager([_StubProvider('a', 1, [0.7])]);
    final r = await m.find(q) as LyricsUncertain;
    await m.accept(q, r.candidates.first);
    expect(File('${dir.path}/BV1_1.lrc').existsSync(), true);

    await m.invalidate('BV1', 1);
    expect(File('${dir.path}/BV1_1.lrc').existsSync(), false);
    expect(await db.lyricsDao.get('BV1', 1), isNull);
  });

  test('并发查询合并', () async {
    final a = _StubProvider('a', 1, [0.9]);
    final m = manager([a]);
    await Future.wait([m.find(q), m.find(q), m.find(q)]);
    expect(a.calls, 1);
  });
}
