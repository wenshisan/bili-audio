import 'dart:io';

import 'package:bili_audio/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bili_audio_log_');
    AppLogger.enabled = true;
    AppLogger.minLevel = LogLevel.debug;
  });

  tearDown(() async {
    await AppLogger.dispose();
    AppLogger.enabled = true;
    AppLogger.minLevel = LogLevel.debug;
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('formatLine 带等级、tag 和 error', () {
    final line = AppLogger.formatLine(
      DateTime(2026, 10, 21, 15, 4, 5, 7),
      LogLevel.warn,
      'search',
      'drop BV1',
      error: 'timeout',
    );
    expect(line, '2026-10-21 15:04:05.007 [W] search: drop BV1 | timeout');
  });

  test('低于阈值的日志不落盘', () async {
    await AppLogger.init(dir);
    AppLogger.minLevel = LogLevel.warn;
    AppLogger.d('hidden', tag: 'search');
    AppLogger.w('visible', tag: 'search');
    await AppLogger.dispose();

    final files = dir.listSync().whereType<File>().toList();
    expect(files, hasLength(1));
    final text = files.single.readAsStringSync();
    expect(text, isNot(contains('hidden')));
    expect(text, contains('[W] search: visible'));
  });

  test('enabled=false 时不写文件', () async {
    await AppLogger.init(dir);
    AppLogger.enabled = false;
    AppLogger.e('nope', tag: 'player');
    await AppLogger.dispose();

    final text = dir.listSync().whereType<File>().single.readAsStringSync();
    expect(text, isNot(contains('nope')));
  });
}
