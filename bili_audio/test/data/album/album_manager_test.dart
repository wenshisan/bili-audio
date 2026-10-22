import 'dart:io';

import 'package:bili_audio/data/album/album_manager.dart';
import 'package:bili_audio/domain/album/album_provider.dart';
import 'package:bili_audio/domain/title/title_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

class _Scripted implements AlbumProvider {
  _Scripted(this.name, this.priority, this.candidates);

  @override
  final String name;

  @override
  final int priority;

  final List<AlbumCandidate> candidates;
  int calls = 0;

  @override
  Future<List<AlbumCandidate>> search(AlbumQuery query) async {
    calls++;
    return candidates;
  }
}

class _Down implements AlbumProvider {
  int calls = 0;

  @override
  String get name => 'down';

  @override
  int get priority => 1;

  @override
  Future<List<AlbumCandidate>> search(AlbumQuery query) async {
    calls++;
    throw const AlbumSourceUnavailable('receive timeout');
  }
}

class _Recording implements AlbumProvider {
  final queries = <AlbumQuery>[];

  @override
  String get name => 'rec';

  @override
  int get priority => 1;

  @override
  Future<List<AlbumCandidate>> search(AlbumQuery query) async {
    queries.add(query);
    return const [];
  }
}

AlbumCandidate _hit({
  required String source,
  String albumName = '魔杰座',
  int? year = 2008,
  String? coverUrl = 'https://example.com/a.jpg',
  String? description = '专辑介绍',
  double score = 0.93,
}) {
  return AlbumCandidate(
    source: source,
    matchScore: score,
    title: '七里香',
    artist: '周杰伦',
    durationSeconds: 299,
    albumName: albumName,
    year: year,
    coverUrl: coverUrl,
    description: description,
  );
}

void main() {
  late Directory dir;
  const q = AlbumQuery(
    bvid: 'BV1',
    cid: 1,
    title: '七里香',
    artist: '周杰伦',
    duration: Duration(seconds: 299),
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('album_');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  AlbumManager manager(List<AlbumProvider> providers) =>
      AlbumManager(dir, providers: providers);

  test('网易云图文年份都齐时不再问后面的源，并写入缓存', () async {
    final netease = _Scripted('netease', 1, [_hit(source: 'netease')]);
    final qq = _Scripted('qq', 5, [_hit(source: 'qq', score: 0.99)]);
    final m = manager([qq, netease]);

    final found = await m.find(q) as AlbumFound;
    expect(found.coverSource, 'netease');
    expect(found.descriptionSource, 'netease');
    expect(found.albumName, '魔杰座');
    expect(found.year, 2008);
    expect(found.fromCache, isFalse);
    expect(qq.calls, 0);

    final again = await m.find(q) as AlbumFound;
    expect(again.fromCache, isTrue);
    expect(again.coverUrl, found.coverUrl);
    expect(netease.calls, 1);
  });

  test('封面和介绍可以来自不同的源', () async {
    final netease = _Scripted('netease', 1, [
      _hit(source: 'netease', description: null),
    ]);
    final qq = _Scripted('qq', 5, [
      _hit(source: 'qq', coverUrl: 'https://example.com/qq.jpg'),
    ]);
    final itunes = _Scripted('itunes', 8, [
      _hit(source: 'itunes', description: null),
    ]);

    final found = await manager([itunes, qq, netease]).find(q) as AlbumFound;

    expect(found.coverSource, 'netease');
    expect(found.coverUrl, 'https://example.com/a.jpg');
    expect(found.descriptionSource, 'qq');
    expect(found.description, '专辑介绍');
    expect(found.year, 2008);
    expect(itunes.calls, 0);
  });

  test('专辑名对不上时不借用别的专辑介绍', () async {
    final netease = _Scripted('netease', 1, [
      _hit(source: 'netease', description: null),
    ]);
    final qq = _Scripted('qq', 5, [
      _hit(source: 'qq', albumName: '叶惠美', coverUrl: null),
    ]);

    final found = await manager([netease, qq]).find(q) as AlbumFound;

    expect(found.coverSource, 'netease');
    expect(found.description, isNull);
    expect(found.albumName, '魔杰座');
  });

  test('得分不够时记成没有资料，下次不再搜索', () async {
    final netease = _Scripted('netease', 1, [
      _hit(source: 'netease', score: 0.4),
    ]);
    final m = manager([netease]);

    expect(await m.find(q), isA<AlbumNone>());
    final calls = netease.calls;
    expect(calls, greaterThan(0));
    final again = await m.find(q) as AlbumNone;
    expect(again.fromCache, isTrue);
    expect(netease.calls, calls);
  });

  test('源全部连不上时不写缓存', () async {
    final down = _Down();
    final m = manager([down]);

    expect(await m.find(q), isA<AlbumNone>());
    expect(down.calls, 2);
    expect(await m.find(q), isA<AlbumNone>());
    expect(down.calls, 4);
  });

  test('invalidate 之后重新搜索', () async {
    final netease = _Scripted('netease', 1, [_hit(source: 'netease')]);
    final m = manager([netease]);
    await m.find(q);
    await m.invalidate('BV1', 1);

    final again = await m.find(q) as AlbumFound;
    expect(again.fromCache, isFalse);
    expect(netease.calls, 2);
  });

  test('并发查询合并', () async {
    final netease = _Scripted('netease', 1, [_hit(source: 'netease')]);
    final m = manager([netease]);
    await Future.wait([m.find(q), m.find(q), m.find(q)]);
    expect(netease.calls, 1);
  });

  test('用原始标题重新清洗后再搜索', () async {
    final cleaner = TitleCleaner.fromJson(
      File('assets/config/title_cleaning_rules.json').readAsStringSync(),
    );
    final provider = _Recording();
    final m = AlbumManager(dir, providers: [provider], cleaner: cleaner);

    await m.find(
      const AlbumQuery(
        bvid: 'BV1',
        cid: 1,
        title: '011.周杰伦-以父之名',
        rawTitle: '011.周杰伦-以父之名',
        duration: Duration(seconds: 343),
      ),
    );

    expect(provider.queries.first.title, '以父之名');
    expect(provider.queries.first.artist, '周杰伦');
  });
}
