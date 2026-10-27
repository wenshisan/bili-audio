import 'dart:io';

import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/lyrics/lyrics_manager.dart';
import 'package:bili_audio/domain/lyrics/lrc_parser.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:bili_audio/domain/title/title_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProvider implements LyricsProvider {
  final queries = <LyricsQuery>[];

  @override
  String get name => 'rec';

  @override
  int get priority => 1;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery q) async {
    queries.add(q);
    final hit = q.title == '以父之名' && q.artist == '周杰伦';
    final score = hit ? 0.95 : 0.2;
    return [
      LyricsCandidate(
        lyrics: LrcParser.parse('[00:01.00]以父之名'),
        source: name,
        matchScore: score,
        originalTitle: q.title,
        originalArtist: q.artist,
        lrcText: '[00:01.00]以父之名',
      ),
    ];
  }
}

class _HitProvider implements LyricsProvider {
  _HitProvider(this.name, this.priority);

  int calls = 0;

  @override
  final String name;

  @override
  final int priority;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery q) async {
    calls++;
    return [
      LyricsCandidate(
        lyrics: LrcParser.parse('[00:01.00]如烟'),
        source: name,
        matchScore: 0.91,
        originalTitle: '如烟',
        originalArtist: '五月天',
        lrcText: '[00:01.00]如烟',
      ),
    ];
  }
}

class _TitleProvider implements LyricsProvider {
  final queries = <LyricsQuery>[];

  @override
  String get name => 'titles';

  @override
  int get priority => 1;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery q) async {
    queries.add(q);
    return [
      LyricsCandidate(
        lyrics: LrcParser.parse('[00:01.00]跑遍了牧场'),
        source: name,
        matchScore: 0.78,
        originalTitle: '周杰伦',
        originalArtist: '米兰的小铁匠',
        lrcText: '[00:01.00]跑遍了牧场',
      ),
    ];
  }
}

class _DownProvider implements LyricsProvider {
  int calls = 0;

  @override
  String get name => 'down';

  @override
  int get priority => 1;

  @override
  Future<List<LyricsCandidate>> search(LyricsQuery q) async {
    calls++;
    throw const LyricsSourceUnavailable('receive timeout');
  }
}

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
      TracksCompanion.insert(bvid: 'BV1', cid: 1, title: 't', duration: 299),
    );
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  LyricsManager manager(List<LyricsProvider> providers) =>
      LyricsManager(db, dir, providers: providers);

  test('includeMissing 补上没有的歌词源并按优先级排到前面', () async {
    final early = _StubProvider('early', 5, [0.2]);
    final late = _StubProvider('late', 0, [0.91]);
    final m = manager([early]);

    expect(
      m.includeMissing({
        'late': () => late,
        'early': () => _StubProvider('early', 1, [0.1]),
      }),
      1,
    );
    expect(m.includeMissing({'late': () => late}), 0);

    final found = await m.find(q);
    expect(found, isA<LyricsFound>());
    expect((found as LyricsFound).lyrics.lines.single.text, contains('late'));
    expect(early.calls, 0);
  });

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
    expect(
      await manager([
        _StubProvider('a', 1, [0.7, 0.5]),
      ]).find(q),
      isA<LyricsUncertain>(),
    );
    final none = await manager([
      _StubProvider('a', 1, [0.5]),
    ]).find(q);
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
    final m = manager([
      _StubProvider('a', 1, [0.9]),
    ]);
    await m.find(q);
    await m.adjustOffset('BV1', 1, const Duration(milliseconds: 300));
    await m.adjustOffset('BV1', 1, const Duration(milliseconds: -100));

    final fresh = manager([]);
    final r = await fresh.find(q) as LyricsFound;
    expect(r.lyrics.offset, const Duration(milliseconds: 200));
  });

  test('手动选择候选后写入缓存; invalidate 删除文件与索引', () async {
    final m = manager([
      _StubProvider('a', 1, [0.7]),
    ]);
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

  test('用原始标题重新清洗后再向歌词源搜索', () async {
    final cleaner = TitleCleaner.fromJson(
      File('assets/config/title_cleaning_rules.json').readAsStringSync(),
    );
    final provider = _RecordingProvider();
    final m = LyricsManager(db, dir, providers: [provider], cleaner: cleaner);

    final r = await m.find(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '011.周杰伦-以父之名',
        rawTitle: '011.周杰伦-以父之名',
        duration: Duration(seconds: 343),
      ),
    );

    expect(provider.queries.first.title, '以父之名');
    expect(provider.queries.first.artist, '周杰伦');
    expect(r, isA<LyricsFound>());
    expect(provider.queries, hasLength(1));
  });

  test('0065 是干扰，搜索语料只有洋葱和五月天', () async {
    final provider = _RecordingProvider();
    final m = LyricsManager(db, dir, providers: [provider]);

    await m.find(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '0065. 洋葱 - 五月天',
        artist: '五月天',
        rawTitle: '0065. 洋葱 - 五月天',
        duration: Duration(seconds: 240),
      ),
    );

    expect(provider.queries, isNotEmpty);
    expect(provider.queries.first.title, '洋葱');
    expect(provider.queries.first.artist, '五月天');
    for (final query in provider.queries) {
      expect(query.title.contains('0065'), isFalse, reason: query.title);
      expect(query.artist?.contains('0065'), isNot(true));
    }
  });

  test('未注入清洗器时仍把分P标题拆开再搜索', () async {
    final provider = _RecordingProvider();
    final m = LyricsManager(db, dir, providers: [provider]);

    await m.find(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '007.周杰伦-稻香',
        duration: Duration(seconds: 224),
      ),
    );

    expect(provider.queries.first.title, '稻香');
    expect(provider.queries.first.artist, '周杰伦');
  });

  test('书名号已确定歌名时，不把歌手的其他歌放进待选', () async {
    final provider = _TitleProvider();
    final m = LyricsManager(db, dir, providers: [provider]);

    final result = await m.find(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '《搁浅》周杰伦丨百万级录音棚试听丨【Hi-Res无损】',
        rawTitle: '《搁浅》周杰伦丨百万级录音棚试听丨【Hi-Res无损】',
        duration: Duration(seconds: 240),
      ),
    );

    expect(provider.queries.every((q) => q.title == '搁浅'), isTrue);
    expect(result, isA<LyricsNone>());
    expect((result as LyricsNone).candidates, isEmpty);
  });

  test('超时重试一次后改用下一个歌词源', () async {
    final down = _DownProvider();
    final next = _HitProvider('next', 2);
    final m = LyricsManager(db, dir, providers: [next, down]);

    final result = await m.find(
      const LyricsQuery(
        bvid: 'BV1',
        cid: 1,
        title: '【4K Hi-Res】如烟_五月天     还欠了他一生',
        duration: Duration(seconds: 220),
      ),
    );

    expect(down.calls, 2);
    expect(next.calls, 1);
    expect(result, isA<LyricsFound>());
  });
}
