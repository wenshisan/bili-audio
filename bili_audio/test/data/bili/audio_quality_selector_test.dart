import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/data/bili/audio_quality_selector.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';

void main() {
  group('AudioQualitySelector', () {
    test('collect 解析 audio 数组', () {
      final dash = {
        'audio': [
          {'id': 30232, 'base_url': 'https://example.com/132k.m4a'},
          {'id': 30280, 'base_url': 'https://example.com/192k.m4a'},
        ],
      };

      final candidates = AudioQualitySelector.collect(dash);

      expect(candidates.length, 2);
      expect(candidates[0].quality, AudioQuality.k132);
      expect(candidates[1].quality, AudioQuality.k192);
    });

    test('collect 包含 dolby.audio', () {
      final dash = {
        'audio': [
          {'id': 30232, 'base_url': 'https://example.com/132k.m4a'},
        ],
        'dolby': {
          'audio': [
            {'id': 30250, 'base_url': 'https://example.com/dolby.m4a'},
          ],
        },
      };

      final candidates = AudioQualitySelector.collect(dash);

      expect(candidates.length, 2);
      expect(candidates.any((c) => c.quality == AudioQuality.dolby), true);
    });

    test('collect 包含 flac.audio', () {
      final dash = {
        'flac': {
          'audio': {'id': 30251, 'base_url': 'https://example.com/flac.m4a'},
        },
      };

      final candidates = AudioQualitySelector.collect(dash);

      expect(candidates.length, 1);
      expect(candidates[0].quality, AudioQuality.hiRes);
    });

    test('select 选择不高于目标的最高档', () {
      final candidates = [
        (quality: AudioQuality.k64, url: 'url64', backupUrls: <String>[]),
        (quality: AudioQuality.k132, url: 'url132', backupUrls: <String>[]),
        (quality: AudioQuality.k192, url: 'url192', backupUrls: <String>[]),
      ];

      final selected = AudioQualitySelector.select(
        candidates,
        AudioQuality.k192,
        loggedIn: true,
      );

      expect(selected!.quality, AudioQuality.k192);
    });

    test('select 未登录时上限 132K', () {
      final candidates = [
        (quality: AudioQuality.k132, url: 'url132', backupUrls: <String>[]),
        (quality: AudioQuality.k192, url: 'url192', backupUrls: <String>[]),
        (quality: AudioQuality.hiRes, url: 'urlHiRes', backupUrls: <String>[]),
      ];

      final selected = AudioQualitySelector.select(
        candidates,
        AudioQuality.hiRes,
        loggedIn: false,
      );

      expect(selected!.quality, AudioQuality.k132);
    });

    test('select 没有不高于目标的时退而选最低档', () {
      final candidates = [
        (quality: AudioQuality.k192, url: 'url192', backupUrls: <String>[]),
        (quality: AudioQuality.dolby, url: 'urlDolby', backupUrls: <String>[]),
      ];

      final selected = AudioQualitySelector.select(
        candidates,
        AudioQuality.k64,
        loggedIn: true,
      );

      expect(selected!.quality, AudioQuality.k192);
    });

    test('空候选返回 null', () {
      final selected = AudioQualitySelector.select(
        [],
        AudioQuality.k132,
        loggedIn: true,
      );

      expect(selected, isNull);
    });
  });
}
