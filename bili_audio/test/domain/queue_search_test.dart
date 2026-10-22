import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/queue/queue_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tracks = [
    _track(title: '晴天', artist: '周杰伦', cid: 1),
    _track(title: '七里香', artist: '周杰伦', cid: 2),
    _track(title: '江南', artist: '林俊杰', cid: 3),
    _track(title: 'Yellow', artist: 'Coldplay', cid: 4),
    _track(
      title: '【4K】晴天官方MV',
      cleanedName: '晴天',
      artist: '周杰伦',
      uploader: '杰威尔音乐',
      cid: 5,
    ),
  ];

  List<String> titles(String query) => [
    for (final index in matchingQueueIndices(tracks, query))
      tracks[index].title,
  ];

  test('空查询保留全部顺序', () {
    expect(queueSearchHasQuery('   '), isFalse);
    expect(queueSearchHasQuery('。。。'), isFalse);
    expect(matchingQueueIndices(tracks, '  '), [0, 1, 2, 3, 4]);
  });

  test('按歌名、歌手和 UP 主匹配', () {
    expect(titles('七里'), ['七里香']);
    expect(titles('周杰伦'), ['晴天', '七里香', '【4K】晴天官方MV']);
    expect(titles('杰威尔'), ['【4K】晴天官方MV']);
    expect(titles('官方'), ['【4K】晴天官方MV']);
    expect(titles('没有这首'), isEmpty);
  });

  test('忽略大小写和标点，并支持拼音', () {
    expect(titles('YELLOW'), ['Yellow']);
    expect(titles('Ｙｅｌｌｏｗ'), ['Yellow']);
    expect(titles('cold play'), ['Yellow']);
    expect(titles('zhou'), ['晴天', '七里香', '【4K】晴天官方MV']);
    expect(titles('zjl'), ['晴天', '七里香', '【4K】晴天官方MV']);
    expect(titles('ljj'), ['江南']);
    expect(titles('qi'), ['晴天', '七里香', '【4K】晴天官方MV']);
    expect(titles('a'), ['Yellow']);
  });

  test('多个词都要命中', () {
    expect(titles('七里 周杰'), ['七里香']);
    expect(titles('江南 周'), isEmpty);
    expect(titles('江南 林'), ['江南']);
  });

  test('字面索引先返回原文匹配，拼音查询等索引补齐', () {
    final literal = QueueSearchIndex.literal(tracks);
    expect(literal.pending('zhou'), isTrue);
    expect(literal.pending('七里'), isFalse);
    expect(literal.match('七里'), [1]);
    expect(literal.match('zhou'), isEmpty);

    final ready = QueueSearchIndex.ready(
      buildQueueSearchHaystacks(QueueSearchIndex.capture(tracks)),
    );
    expect(ready.pending('zhou'), isFalse);
    expect(ready.match('zhou'), [0, 1, 4]);
    expect(ready.match('zjl'), [0, 1, 4]);
  });

  test('拼音索引可以在后台 isolate 算完再匹配', () async {
    final haystacks = await compute(
      buildQueueSearchHaystacks,
      QueueSearchIndex.capture(tracks),
    );
    final index = QueueSearchIndex.ready(haystacks);
    expect(index.match('ljj'), [2]);
    expect(index.match('七里'), [1]);
  });
}

Track _track({
  required String title,
  required int cid,
  String? artist,
  String? cleanedName,
  String? uploader,
}) {
  return Track(
    bvid: 'BV$cid',
    cid: cid,
    title: title,
    artist: artist,
    cleanedName: cleanedName,
    uploader: uploader,
    duration: const Duration(minutes: 3),
  );
}
