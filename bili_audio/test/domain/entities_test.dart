import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/core/utils/result.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/domain/entities/lyrics.dart';
import 'package:bili_audio/domain/entities/video.dart';

void main() {
  const track = Track(
    bvid: 'BV1xx411c7mD',
    cid: 42,
    title: '七里香【Hi-Res】',
    duration: Duration(seconds: 299),
    uploader: 'UP主',
  );

  group('Track', () {
    test('相等性', () {
      expect(track, track.copyWith());
      expect(track == track.copyWith(cid: 43), false);
    });

    test('JSON 往返', () {
      expect(Track.fromJson(track.toJson()), track);
    });

    test('显示字段兜底', () {
      expect(track.displayTitle, '七里香【Hi-Res】');
      expect(track.displayArtist, 'UP主');
      final cleaned = track.copyWith(cleanedName: '七里香', artist: '周杰伦');
      expect(cleaned.displayTitle, '七里香');
      expect(cleaned.displayArtist, '周杰伦');
      expect(const Track(bvid: 'b', cid: 1, title: 't', duration: Duration.zero)
          .displayArtist, '未知');
    });

    test('缓存键', () {
      expect(track.cacheKey(AudioQuality.k132), 'BV1xx411c7mD_42_30232');
    });
  });

  test('Video JSON 往返', () {
    const video = Video(
      bvid: 'BV1',
      title: '合集',
      uploader: 'UP',
      uploaderMid: 1,
      cover: 'https://example.com/c.jpg',
      pages: [VideoPage(cid: 1, title: 'P1', duration: Duration(seconds: 60), pageIndex: 1)],
      tags: ['周杰伦'],
    );
    expect(Video.fromJson(video.toJson()), video);
  });

  test('Lyrics JSON 往返', () {
    const lyrics = Lyrics(
      lines: [LyricLine(timestamp: Duration(seconds: 1), text: 'a', translation: 'b')],
      offset: Duration(milliseconds: -300),
      source: 'lrclib',
      matchScore: 0.9,
    );
    expect(Lyrics.fromJson(lyrics.toJson()), lyrics);
  });

  group('Result', () {
    test('success / failure', () {
      const ok = Result<int>.success(1);
      const err = Result<int>.failure('boom');
      expect(ok.isSuccess, true);
      expect(ok.valueOrNull, 1);
      expect(err.isFailure, true);
      expect(err.errorOrNull, 'boom');
      expect(ok.map((v) => v + 1).valueOrNull, 2);
      expect(err.map((v) => v + 1).errorOrNull, 'boom');
      expect(ok.flatMap((v) => Result<String>.success('$v')).valueOrNull, '1');
    });
  });
}
