import 'dart:io';

import 'package:bili_audio/app/platform/desktop_controls.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/domain/update/distribution.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/player/fakes.dart';

void main() {
  const labels = DesktopControlLabels(
    appName: '音赴光年',
    play: '播放',
    pause: '暂停',
    previous: '上一首',
    next: '下一首',
    nothingPlaying: '暂无播放',
    showWindow: '显示主窗口',
    hideWindow: '隐藏到托盘',
    quit: '退出',
  );
  const playing = DesktopTrackSnapshot(
    title: '夜航',
    artist: '星河',
    playing: true,
    position: Duration(seconds: 12),
    duration: Duration(minutes: 3),
  );

  DesktopMenuEntry entry(List<DesktopMenuEntry> menu, DesktopCommand command) {
    return menu.firstWhere((item) => item.command == command);
  }

  test('空闲时托盘只留窗口操作，切歌不可用', () {
    const idle = DesktopTrackSnapshot();
    final menu = trayMenuEntries(idle, labels);

    expect(menu.first.label, '暂无播放');
    expect(menu.first.enabled, isFalse);
    expect(entry(menu, DesktopCommand.togglePlay).label, '播放');
    expect(entry(menu, DesktopCommand.togglePlay).enabled, isFalse);
    expect(entry(menu, DesktopCommand.previous).enabled, isFalse);
    expect(entry(menu, DesktopCommand.next).enabled, isFalse);
    expect(entry(menu, DesktopCommand.showWindow).enabled, isTrue);
    expect(entry(menu, DesktopCommand.quit).enabled, isTrue);
    expect(playbackTooltip(idle, labels.appName), '音赴光年');
    expect(playbackWindowTitle(idle, labels.appName), '音赴光年');
    expect(menuBarTitle(idle), isEmpty);
    expect(taskbarPhase(idle), DesktopTaskbarPhase.hidden);
    expect(taskbarProgress(idle), isNull);
  });

  test('播放中菜单能暂停和切歌，标题带上歌名', () {
    final menu = trayMenuEntries(playing, labels);

    expect(menu.first.label, '夜航 — 星河');
    expect(entry(menu, DesktopCommand.togglePlay).label, '暂停');
    expect(entry(menu, DesktopCommand.togglePlay).enabled, isTrue);
    expect(entry(menu, DesktopCommand.previous).enabled, isTrue);
    expect(entry(menu, DesktopCommand.next).label, '下一首');
    expect(playbackTooltip(playing, labels.appName), '夜航 — 星河');
    expect(playbackWindowTitle(playing, labels.appName), '夜航 — 星河 — 音赴光年');
    expect(menuBarTitle(playing), ' 夜航');
    expect(taskbarPhase(playing), DesktopTaskbarPhase.playing);
    expect(taskbarProgress(playing), (completed: 12000, total: 180000));
  });

  test('暂停时任务栏进度保持，播放键文案改回播放', () {
    const paused = DesktopTrackSnapshot(
      title: '夜航',
      artist: '',
      position: Duration(seconds: 200),
      duration: Duration(seconds: 180),
    );

    expect(trayMenuEntries(paused, labels).first.label, '夜航');
    expect(
      entry(trayMenuEntries(paused, labels), DesktopCommand.togglePlay).label,
      '播放',
    );
    expect(taskbarPhase(paused), DesktopTaskbarPhase.paused);
    expect(taskbarProgress(paused)?.completed, 180000);
  });

  test('程序坞菜单去掉隐藏和退出，不留下多余分隔线', () {
    final payload = dockMenuPayload(playing, labels);
    final ids = [
      for (final item in payload)
        if (item['id'] != null) item['id'],
    ];

    expect(ids, ['togglePlay', 'previous', 'next', 'show']);
    expect(payload.last['id'], 'show');
    expect(payload.where((item) => item['separator'] == true), hasLength(1));
    expect(payload.first['enabled'], isFalse);
    expect(payload.first['label'], '夜航 — 星河');
  });

  test('进度变化不改变菜单签名，歌名变化会', () {
    final moved = DesktopTrackSnapshot(
      title: playing.title,
      artist: playing.artist,
      playing: playing.playing,
      position: const Duration(seconds: 40),
      duration: playing.duration,
    );
    expect(playbackChromeKey(playing), playbackChromeKey(moved));
    expect(
      playbackChromeKey(playing),
      isNot(playbackChromeKey(const DesktopTrackSnapshot(title: '另一首'))),
    );
  });

  test('菜单栏标题超过 14 个字时截断', () {
    const snap = DesktopTrackSnapshot(title: '一二三四五六七八九十甲乙丙丁戊');
    expect(menuBarTitle(snap), ' 一二三四五六七八九十甲乙丙丁…');
  });

  test('文案和未知命令', () {
    expect(DesktopControlLabels.zh.appName, productTitle());
    expect(commandById('next'), DesktopCommand.next);
    expect(commandById('missing'), isNull);
  });

  test('播放命令切到暂停', () async {
    final db = AppDatabase.memory();
    final dir = Directory.systemTemp.createTempSync('desktop_controls_');
    addTearDown(() async {
      dir.deleteSync(recursive: true);
      await db.close();
    });
    final engine = FakeEngine();
    final handler = BiliAudioHandler(
      engine: engine,
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
    addTearDown(handler.dispose);
    engine.playing = true;

    applyPlaybackCommand(handler, DesktopCommand.togglePlay);
    await Future<void>.delayed(Duration.zero);
    expect(engine.playing, isFalse);

    applyPlaybackCommand(handler, DesktopCommand.showWindow);
    expect(engine.playing, isFalse);
  });
}
