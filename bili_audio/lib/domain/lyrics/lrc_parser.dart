import '../entities/lyrics.dart';

/// LRC 解析器 (M1.4)
///
/// 支持:
/// - [mm:ss] [mm:ss.xx] [mm:ss.xxx] 格式
/// - 单行多时间戳
/// - [offset:+/-ms] 偏移量
/// - 元数据标签 (ar: ti: al: 等)
class LrcParser {
  /// 解析 LRC 文本
  static Lyrics parse(String lrcText) {
    final lines = <LyricLine>[];
    Duration offset = Duration.zero;
    final metadata = <String, String>{};

    for (var line in lrcText.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;

      // 解析元数据标签
      final metaMatch = RegExp(r'^\[([a-z]+):(.+)\]$').firstMatch(line);
      if (metaMatch != null) {
        final key = metaMatch.group(1)!;
        final value = metaMatch.group(2)!.trim();
        metadata[key] = value;

        // 解析 offset
        if (key == 'offset') {
          final offsetMs = int.tryParse(value);
          if (offsetMs != null) {
            offset = Duration(milliseconds: offsetMs);
          }
        }
        continue;
      }

      // 解析时间戳行
      final timestamps = <Duration>[];
      var text = line;

      // 提取所有时间戳
      final timePattern = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\]');
      final matches = timePattern.allMatches(line).toList();

      if (matches.isEmpty) continue;

      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3) ?? '0';
        // 处理 .xx 和 .xxx 格式
        final millis = millisStr.length == 2
            ? int.parse(millisStr) * 10
            : int.parse(millisStr.padRight(3, '0').substring(0, 3));

        timestamps.add(Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        ));
      }

      // 提取歌词文本 (移除所有时间戳)
      text = line.replaceAll(timePattern, '').trim();

      // 为每个时间戳创建一行歌词
      for (final timestamp in timestamps) {
        lines.add(LyricLine(timestamp: timestamp, text: text));
      }
    }

    // 按时间戳排序
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 合并同时间戳的行为原文+翻译
    final mergedLines = <LyricLine>[];
    for (var i = 0; i < lines.length; i++) {
      if (i + 1 < lines.length &&
          lines[i].timestamp == lines[i + 1].timestamp) {
        // 同时间戳: 合并为原文+翻译
        mergedLines.add(LyricLine(
          timestamp: lines[i].timestamp,
          text: lines[i].text,
          translation: lines[i + 1].text,
        ));
        i++; // 跳过下一行
      } else {
        mergedLines.add(lines[i]);
      }
    }

    return Lyrics(
      lines: mergedLines,
      offset: offset,
      source: metadata['source'],
    );
  }
}

/// 歌词时间轴 (M1.4)
///
/// 用于播放时快速定位当前歌词行。
class LyricsTimeline {
  LyricsTimeline(this.lyrics);

  final Lyrics lyrics;

  /// 查找指定位置的歌词行索引 (二分查找)
  ///
  /// 返回当前应该显示的歌词行索引，如果没有则返回 -1。
  int indexAt(Duration position) {
    if (lyrics.lines.isEmpty) return -1;

    // offset 为负数时，歌词提前显示；为正数时，歌词延后显示
    // 因此需要从 position 中减去 offset
    final adjustedPosition = position - lyrics.offset;

    // 二分查找最后一个 timestamp <= adjustedPosition 的行
    var left = 0;
    var right = lyrics.lines.length - 1;
    var result = -1;

    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final line = lyrics.lines[mid];

      if (line.timestamp <= adjustedPosition) {
        result = mid;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    return result;
  }

  /// 获取指定位置的歌词行
  LyricLine? lineAt(Duration position) {
    final index = indexAt(position);
    return index >= 0 ? lyrics.lines[index] : null;
  }
}
