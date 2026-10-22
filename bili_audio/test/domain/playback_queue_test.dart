import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/domain/queue/playback_queue.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';

void main() {
  List<Track> createTracks(int count) {
    return List.generate(
      count,
      (i) => Track(
        bvid: 'BV$i',
        cid: i,
        title: 'Track $i',
        duration: const Duration(minutes: 3),
      ),
    );
  }

  group('PlaybackQueue 基础功能', () {
    test('顺序播放', () {
      final tracks = createTracks(3);
      final queue = PlaybackQueue(tracks: tracks);

      expect(queue.current?.title, 'Track 0');
      expect(queue.next()?.title, 'Track 1');
      expect(queue.next()?.title, 'Track 2');
      expect(queue.next(), isNull); // 播放完毕
    });

    test('列表循环', () {
      final tracks = createTracks(3);
      final queue = PlaybackQueue(tracks: tracks, mode: PlayMode.listLoop);

      queue.next();
      queue.next();
      expect(queue.next()?.title, 'Track 0'); // 循环回第一首
    });

    test('单曲循环', () {
      final tracks = createTracks(3);
      final queue = PlaybackQueue(tracks: tracks, mode: PlayMode.singleLoop);

      expect(queue.current?.title, 'Track 0');
      expect(queue.next()?.title, 'Track 0');
      expect(queue.next()?.title, 'Track 0');
    });

    test('随机播放', () {
      final tracks = createTracks(10);
      final queue = PlaybackQueue(
        tracks: tracks,
        mode: PlayMode.shuffle,
        seed: 12345,
      );

      final playedTitles = <String>{};
      for (var i = 0; i < 10; i++) {
        final track = queue.current;
        if (track != null) playedTitles.add(track.title);
        queue.next();
      }

      // 应该播放了所有10首歌
      expect(playedTitles.length, 10);
    });

    test('随机模式回退', () {
      final tracks = createTracks(5);
      final queue = PlaybackQueue(tracks: tracks, mode: PlayMode.shuffle);

      final first = queue.current;
      queue.next();
      final second = queue.current;
      queue.next();

      // 回退到上一首
      expect(queue.previous(), second);
      expect(queue.previous(), first);
    });

    test('随机模式没有更早的一首时不跳到列表相邻项', () {
      final queue = PlaybackQueue(
        tracks: createTracks(5),
        mode: PlayMode.shuffle,
        startIndex: 3,
      );

      expect(queue.previous(), isNull);
      expect(queue.current?.title, 'Track 3');
    });

    test('随机模式插入下一首后, 上一首仍是实际听过的那首', () {
      final queue = PlaybackQueue(
        tracks: createTracks(5),
        mode: PlayMode.shuffle,
      );
      queue.jumpTo(4);
      queue.jumpTo(1);
      queue.insertNext(
        const Track(
          bvid: 'BV999',
          cid: 999,
          title: 'Inserted',
          duration: Duration(minutes: 3),
        ),
      );

      expect(queue.previous()?.title, 'Track 4');
      expect(queue.previous()?.title, 'Track 0');
    });
  });

  group('PlaybackQueue 模式切换', () {
    test('顺序 → 随机: 当前曲保持, 列表不提前打乱', () {
      final tracks = createTracks(5);
      final queue = PlaybackQueue(tracks: tracks);

      queue.next();
      queue.next();
      final current = queue.current; // Track 2

      queue.setMode(PlayMode.shuffle);
      expect(queue.current, current); // 当前曲不变
      expect(queue.orderedTracks.map((t) => t.title).toList(), [
        for (var i = 0; i < 5; i++) 'Track $i',
      ]);
      expect(queue.nextTrack, isNull);
    });

    test('顺序 → 随机: 下一首不是原列表的下一首', () {
      for (var seed = 1; seed <= 20; seed++) {
        final queue = PlaybackQueue(tracks: createTracks(8), seed: seed);
        queue.next();
        queue.next(); // Track 2
        queue.setMode(PlayMode.shuffle);
        expect(queue.current?.title, 'Track 2');
        expect(queue.next()?.title, isNot('Track 3'));
      }
    });

    test('随机模式从指定曲开始, 下一首不是它在原列表中的后一首', () {
      for (var seed = 1; seed <= 20; seed++) {
        final queue = PlaybackQueue(
          tracks: createTracks(8),
          mode: PlayMode.shuffle,
          seed: seed,
          startIndex: 4,
        );
        expect(queue.current?.title, 'Track 4');
        expect(queue.next()?.title, isNot('Track 5'));
      }
    });

    test('随机一轮结束后继续, 且不重复刚刚播完的那首', () {
      final queue = PlaybackQueue(
        tracks: createTracks(4),
        mode: PlayMode.shuffle,
        seed: 3,
      );
      Track? last;
      for (var i = 0; i < 4; i++) {
        last = queue.current;
        queue.next();
      }
      expect(queue.current, isNot(last));
      expect(queue.previous(), last);
    });

    test('随机模式下按原顺序追加后, 下一首不再顺着原顺序', () {
      final queue = PlaybackQueue(
        tracks: createTracks(1),
        mode: PlayMode.shuffle,
        seed: 1,
      );
      for (var i = 1; i < 6; i++) {
        queue.append(
          Track(
            bvid: 'BV$i',
            cid: i,
            title: 'Track $i',
            duration: const Duration(minutes: 3),
          ),
        );
      }
      expect(queue.next()?.title, isNot('Track 1'));
    });

    test('点下一首时才随机, 不同种子选到的歌不完全相同', () {
      final picks = <String>{};
      for (var seed = 1; seed <= 20; seed++) {
        final queue = PlaybackQueue(
          tracks: createTracks(8),
          mode: PlayMode.shuffle,
          seed: seed,
        );
        expect(queue.nextTrack, isNull);
        final next = queue.next();
        picks.add(next!.title);
        expect(queue.orderedTracks.map((t) => t.cid).toList(), [
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
        ]);
        expect(next.title, isNot('Track 0'));
        expect(next.title, isNot('Track 1'));
      }
      expect(picks.length, greaterThan(1));
    });

    test('智能随机优先换歌手', () {
      final tracks = [
        for (var i = 0; i < 3; i++)
          Track(
            bvid: 'BV$i',
            cid: i,
            title: 'Track $i',
            artist: i == 2 ? '乙' : '甲',
            duration: const Duration(minutes: 3),
          ),
      ];
      for (var seed = 1; seed <= 15; seed++) {
        final queue = PlaybackQueue(
          tracks: tracks,
          mode: PlayMode.smartShuffle,
          seed: seed,
        );
        expect(queue.next()?.artist, '乙');
      }
    });

    test('随机模式「下一首播放」仍插到紧接着的位置', () {
      final queue = PlaybackQueue(
        tracks: createTracks(5),
        mode: PlayMode.shuffle,
        seed: 3,
      );
      queue.insertNext(
        const Track(
          bvid: 'BV999',
          cid: 999,
          title: 'Inserted',
          duration: Duration(minutes: 3),
        ),
      );
      expect(queue.next()?.title, 'Inserted');
    });

    test('随机 → 顺序: 定位到original位置', () {
      final tracks = createTracks(5);
      final queue = PlaybackQueue(tracks: tracks, mode: PlayMode.shuffle);

      queue.next();
      queue.next();
      final current = queue.current;

      queue.setMode(PlayMode.sequential);
      expect(queue.current, current);
    });
  });

  group('PlaybackQueue 编辑操作', () {
    test('添加到队尾', () {
      final queue = PlaybackQueue(tracks: createTracks(3));
      final newTrack = const Track(
        bvid: 'BV999',
        cid: 999,
        title: 'New Track',
        duration: Duration(minutes: 3),
      );

      queue.append(newTrack);
      expect(queue.length, 4);
    });

    test('插入到下一首', () {
      final queue = PlaybackQueue(tracks: createTracks(3));
      final newTrack = const Track(
        bvid: 'BV999',
        cid: 999,
        title: 'Next Track',
        duration: Duration(minutes: 3),
      );

      queue.insertNext(newTrack);
      expect(queue.next()?.title, 'Next Track');
    });

    test('移除当前播放后，后面的曲目成为当前', () {
      final queue = PlaybackQueue(tracks: createTracks(5));
      queue.next(); // Track 1

      queue.removeAt(1);
      expect(queue.length, 4);
      expect(queue.current?.title, 'Track 2');
      expect(queue.next()?.title, 'Track 3');
    });

    test('按看到的顺序移除「下一首播放」插入的曲目', () {
      final queue = PlaybackQueue(tracks: createTracks(3));
      queue.insertNext(
        const Track(
          bvid: 'BV999',
          cid: 999,
          title: 'Inserted',
          duration: Duration(minutes: 3),
        ),
      );

      queue.removeOrderedAt(1);
      expect(queue.orderedTracks.map((t) => t.title).toList(), [
        'Track 0',
        'Track 1',
        'Track 2',
      ]);
      expect(queue.current?.title, 'Track 0');
      expect(queue.next()?.title, 'Track 1');
    });

    test('同一首出现两次时，移除点中的那一次', () {
      final track = createTracks(1).single;
      final queue = PlaybackQueue(tracks: [track, track]);

      queue.removeOrderedAt(1);
      expect(queue.length, 1);
      expect(queue.current, track);
    });

    test('移除最后一首后队列为空', () {
      final queue = PlaybackQueue(tracks: createTracks(1));
      queue.removeOrderedAt(0);
      expect(queue.isEmpty, true);
      expect(queue.current, isNull);
    });

    test('越界移除不改变队列', () {
      final queue = PlaybackQueue(tracks: createTracks(2));
      queue.removeOrderedAt(5);
      expect(queue.length, 2);
      expect(queue.current?.title, 'Track 0');
    });

    test('随机模式下移除后不会再选到它', () {
      final queue = PlaybackQueue(
        tracks: createTracks(4),
        mode: PlayMode.shuffle,
        seed: 1,
      );
      queue.removeOrderedAt(3);

      final titles = <String>{};
      for (var i = 0; i < 6; i++) {
        titles.add(queue.current!.title);
        queue.next();
      }
      expect(titles, isNot(contains('Track 3')));
    });

    test('移除光标之前的曲目，当前曲不变', () {
      final queue = PlaybackQueue(tracks: createTracks(5));
      queue.next();
      queue.next(); // Track 2

      queue.removeAt(0);
      expect(queue.current?.title, 'Track 2');
      expect(queue.next()?.title, 'Track 3');
    });

    test('调整顺序', () {
      final queue = PlaybackQueue(tracks: createTracks(3));
      expect(queue.reorder(2, 0), true);
      expect(queue.current?.title, 'Track 0');
      expect(queue.tracks.first.title, 'Track 2');
    });

    test('随机模式拒绝调整顺序', () {
      final queue = PlaybackQueue(
        tracks: createTracks(3),
        mode: PlayMode.shuffle,
      );
      expect(queue.reorder(0, 1), false);
    });

    test('清空队列，保留当前', () {
      final queue = PlaybackQueue(tracks: createTracks(5));
      queue.next();
      queue.next(); // Track 2

      queue.clearExceptCurrent();
      expect(queue.length, 1);
      expect(queue.current?.title, 'Track 2');
    });
  });

  group('PlaybackQueue 快照恢复', () {
    test('序列化和反序列化', () {
      final tracks = createTracks(5);
      final queue = PlaybackQueue(tracks: tracks, mode: PlayMode.shuffle);

      queue.next();
      queue.next();

      final snapshot = queue.toSnapshot();
      final restored = PlaybackQueue.fromSnapshot(snapshot);

      expect(restored.current?.bvid, queue.current?.bvid);
      expect(restored.mode, queue.mode);
      expect(restored.length, queue.length);
      expect(
        restored.orderedTracks.map((t) => t.cid),
        queue.orderedTracks.map((t) => t.cid),
      );
      expect(restored.next()?.bvid, queue.next()?.bvid);
    });

    test('旧的打乱顺序快照恢复后回到原列表, 当前曲不变', () {
      final queue = PlaybackQueue(
        tracks: createTracks(4),
        mode: PlayMode.shuffle,
        seed: 1,
      );
      final snapshot = queue.toSnapshot();
      snapshot['order'] = [2, 0, 3, 1];
      snapshot['cursor'] = 1;
      snapshot['history'] = [0];

      final restored = PlaybackQueue.fromSnapshot(snapshot);
      expect(restored.current?.title, 'Track 0');
      expect(restored.orderedTracks.map((t) => t.cid).toList(), [0, 1, 2, 3]);
      expect(restored.previous()?.title, 'Track 2');
    });
  });

  group('PRD 验证', () {
    test('顺序播放正确性', () {
      final queue = PlaybackQueue(tracks: createTracks(3));

      expect(queue.current?.title, 'Track 0');
      queue.next();
      expect(queue.current?.title, 'Track 1');
      queue.next();
      expect(queue.current?.title, 'Track 2');
      expect(queue.next(), isNull);
    });

    test('随机不重复直到一轮结束', () {
      final tracks = createTracks(10);
      final queue = PlaybackQueue(
        tracks: tracks,
        mode: PlayMode.shuffle,
        seed: 42,
      );

      final played = <String>{};
      for (var i = 0; i < 10; i++) {
        final track = queue.current;
        expect(played.contains(track?.title), false);
        if (track != null) played.add(track.title);
        queue.next();
      }

      expect(played.length, 10);
    });
  });

  group('jumpTo', () {
    test('顺序模式跳到指定曲目, 之后按顺序继续', () {
      final queue = PlaybackQueue(tracks: createTracks(5));
      expect(queue.jumpTo(3)?.title, 'Track 3');
      expect(queue.next()?.title, 'Track 4');
      expect(queue.previous()?.title, 'Track 3');
    });

    test('随机模式跳转后"上一曲"回到跳转前', () {
      final queue = PlaybackQueue(
        tracks: createTracks(5),
        mode: PlayMode.shuffle,
        seed: 1,
      );
      final before = queue.current;
      final target = queue.tracks.indexOf(queue.orderedTracks.last);
      queue.jumpTo(target);
      expect(queue.previous(), before);
    });

    test('越界返回 null 且不改变当前曲', () {
      final queue = PlaybackQueue(tracks: createTracks(2));
      expect(queue.jumpTo(9), isNull);
      expect(queue.current?.title, 'Track 0');
    });
  });
}
