import 'dart:convert';

import '../entities/video.dart';
import '../text_normalization.dart';
import 'title_rule.dart';

/// 标题清洗器 (M1.3)
///
/// 将B站视频标题清洗为歌名和歌手，支持规则配置。
class TitleCleaner {
  TitleCleaner(this.config);

  final TitleRuleConfig config;

  /// 清洗标题
  ///
  /// 参数:
  /// - [rawTitle]: 原始标题 (视频标题或分P标题)
  /// - [video]: 视频元信息 (用于兜底逻辑)
  /// - [pageIndex]: 分P序号 (用于判断是否使用分P标题)
  /// - [disabledRuleIds]: 用户禁用的规则ID列表
  CleanedTitle clean(
    String rawTitle, {
    Video? video,
    int? pageIndex,
    Set<String> disabledRuleIds = const {},
  }) {
    final appliedRules = <String>[];
    final flags = <String>{};
    // 折叠空白之前先去掉解说尾巴和分P序号，否则 "如烟_五月天    还欠了…"
    // 会被收成单空格，后续规则认不出哪一段是歌名。
    var workingTitle = _preprocess(rawTitle);

    // 启用的规则
    final enabledRules = config.rules
        .where((r) => r.enabled && !disabledRuleIds.contains(r.id))
        .toList();

    // 1. 标记规则 (flag)
    for (final rule in enabledRules.where((r) => r.type == 'flag')) {
      final regex = RegExp(rule.pattern, caseSensitive: false);
      if (regex.hasMatch(workingTitle)) {
        flags.add(rule.flag!);
        appliedRules.add(rule.id);
      }
    }

    // 2. 删除规则 (remove)
    for (final rule in enabledRules.where((r) => r.type == 'remove')) {
      final regex = RegExp(rule.pattern, caseSensitive: false);
      final before = workingTitle;
      workingTitle = workingTitle.replaceAll(regex, '').trim();
      if (before != workingTitle) {
        appliedRules.add(rule.id);
      }
    }

    // 3. 提取/拆分规则 (按优先级降序)
    final extractSplitRules =
        enabledRules
            .where((r) => r.type == 'extract' || r.type == 'split')
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

    String? extractedTitle;
    String? extractedArtist;

    for (final rule in extractSplitRules) {
      if (rule.type == 'extract') {
        final regex = RegExp(rule.pattern);
        for (final match in regex.allMatches(workingTitle)) {
          if (match.groupCount < 1) continue;
          // 《淮水竹亭》写在「主题曲」括号里时不是歌名。
          if (_isInsideParens(workingTitle, match.start)) continue;
          final extracted = match.group(1)!.trim();
          if (extracted.isEmpty) continue;
          if (rule.group == 'title') {
            extractedTitle = extracted;
          } else if (rule.group == 'artist') {
            extractedArtist = extracted;
          }
          appliedRules.add(rule.id);
          break;
        }
        if (extractedTitle != null || extractedArtist != null) break;
      } else if (rule.type == 'split') {
        final regex = RegExp(rule.pattern);
        final parts = workingTitle
            .split(regex)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          final left = parts[0];
          final right = parts[1];
          if (rule.id == 'sep_underscore' &&
              (!_hasCjk(left) || !_hasCjk(right))) {
            continue;
          }
          if (rule.order == 'title_artist') {
            extractedTitle = left;
            extractedArtist = right;
          } else if (rule.order == 'artist_title') {
            extractedArtist = left;
            extractedTitle = right;
          }
          if (extractedTitle != null) {
            appliedRules.add(rule.id);
            break;
          }
        }
      }
    }

    // 规则文件没覆盖的紧凑写法：`周杰伦-稻香`、`如烟_五月天`。
    if (extractedTitle == null && extractedArtist == null) {
      final builtin = _splitBuiltin(workingTitle);
      if (builtin != null) {
        extractedArtist = builtin.$1;
        extractedTitle = builtin.$2;
        appliedRules.add(builtin.$3);
      }
    }

    if (extractedTitle != null && extractedArtist == null) {
      final remainder = workingTitle.replaceAll(
        RegExp('[《「『][^》」』]*[》」』]'),
        ' ',
      );
      extractedArtist = _artistFromRemainder(remainder);
    }

    // 4. 兜底逻辑
    var name = _polish(extractedTitle ?? workingTitle);
    var artist = extractedArtist == null ? null : _clipArtist(extractedArtist);
    if (name.isEmpty) name = normalizeForDisplay(rawTitle);
    final artistCandidates = <String>[];

    // 添加UP主作为候选歌手
    if (video != null && video.uploader.isNotEmpty) {
      artistCandidates.add(video.uploader);
    }

    return CleanedTitle(
      name: name,
      artist: artist,
      artistCandidates: artistCandidates,
      flags: flags,
      appliedRuleIds: appliedRules,
    );
  }

  /// 搜索前先抽出歌名和歌手。`0065. 洋葱 - 五月天` 里的 `0065` 是分 P 序号，不进入搜索词。
  static ({String title, String? artist}) searchCorpus(
    String raw, {
    String? artist,
  }) {
    final loose = parseLoose(raw);
    final extracted = loose.name.trim();
    final title = extracted.isEmpty ? raw.trim() : extracted;
    final given = artist?.trim();
    if (given != null && given.isNotEmpty) {
      return (title: title, artist: given);
    }
    final parsed = loose.artist?.trim();
    return (
      title: title,
      artist: parsed == null || parsed.isEmpty ? null : parsed,
    );
  }

  /// 不依赖规则文件，把 `007.周杰伦-稻香` 这类分P标题拆成歌名和歌手。
  ///
  /// 歌词搜索在清洗器未注入、或库里的歌名仍是原标题时走这里。
  static ({String name, String? artist}) parseLoose(String raw) {
    var text = _preprocess(raw);
    text = text.replaceAll(_noiseBracket, ' ');
    text = text.replaceAll(_bareQuality, ' ');
    text = normalizeForDisplay(text);
    if (text.isEmpty) return (name: raw.trim(), artist: null);

    final quote = RegExp('[《「『]([^》」』]+)[》」』]');
    for (final match in quote.allMatches(text)) {
      if (_isInsideParens(text, match.start)) continue;
      final name = match.group(1)!.trim();
      if (name.isEmpty) continue;
      final remainder = text.replaceAll(RegExp('[《「『][^》」』]*[》」』]'), ' ');
      return (name: _polish(name), artist: _artistFromRemainder(remainder));
    }

    final spaced = RegExp(r'\s[-—–]\s');
    if (spaced.hasMatch(text)) {
      final parts = text
          .split(spaced)
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        return (name: _polish(parts[0]), artist: _clipArtist(parts[1]));
      }
    }

    final builtin = _splitBuiltin(text);
    if (builtin != null) {
      return (name: _polish(builtin.$2), artist: _clipArtist(builtin.$1));
    }

    final name = _polish(text);
    return (name: name.isEmpty ? raw.trim() : name, artist: null);
  }

  static final _noiseBracket = RegExp(
    '[【\\[(（「][^】\\])）」]*?(?:Hi-?Res|无损|FLAC|320K|DSD|APE|WAV|4K|60帧|HDR|杜比|中字|字幕|歌词|Official|MV|PV|Live|现场|演唱会|翻唱|cover|カバー|试听|录音棚|百万|纯享|完整版|官方|烟嗓|伴奏|片尾曲|片头曲|主题曲|影视)[^】\\])）」]*[】\\])）」]',
    caseSensitive: false,
  );

  static final _bareQuality = RegExp(
    r'(?<![A-Za-z])(?:Hi-?Res|FLAC|DSD|APE|WAV)(?![A-Za-z])',
    caseSensitive: false,
  );

  /// 解说、序号、音质尾巴先削掉，再交给规则做分隔。
  static String _preprocess(String raw) {
    var text = raw;
    text = text.replaceAll(RegExp(r'——.{8,}'), '');
    text = text.replaceAll(RegExp(r'[ \t]{2,}\S.*$'), '');
    text = text.replaceFirst(RegExp(r'^\d{1,4}[.、．]\s*'), '');
    text = text.replaceAll(
      RegExp(
        r'[|｜丨][^|｜丨]*?(?:试听|录音棚|百万|无损|Hi-?Res|4K|字幕|中字)[^|｜丨]*',
        caseSensitive: false,
      ),
      '',
    );
    return normalizeForDisplay(text);
  }

  static bool _isInsideParens(String text, int index) {
    var depth = 0;
    final end = index < text.length ? index : text.length;
    for (var i = 0; i < end; i++) {
      final ch = text[i];
      if (ch == '(' || ch == '（') {
        depth++;
      } else if ((ch == ')' || ch == '）') && depth > 0) {
        depth--;
      }
    }
    return depth > 0;
  }

  static bool _hasCjk(String text) => RegExp(r'[\u4e00-\u9fff]').hasMatch(text);

  /// 返回 (歌手, 歌名, 规则 id)。
  static (String, String, String)? _splitBuiltin(String text) {
    final cjkDash = RegExp(r'(?<=[\u4e00-\u9fff])[-－](?=[\u4e00-\u9fff])');
    if (cjkDash.hasMatch(text)) {
      final parts = text
          .split(cjkDash)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2 && _hasCjk(parts[0]) && _hasCjk(parts[1])) {
        return (parts[0], parts[1], 'builtin_cjk_dash');
      }
    }
    if (text.contains('_')) {
      final parts = text
          .split('_')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2 && _hasCjk(parts[0]) && _hasCjk(parts[1])) {
        return (parts[1], parts[0], 'builtin_underscore');
      }
    }
    return null;
  }

  static String _polish(String value) {
    var text = value.replaceAll(RegExp(r'[（(][^）)]*[）)]'), '');
    text = text.replaceAll(RegExp(r'\s*[|｜丨].*$'), '');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static final _versionOnly = RegExp(
    r'^(?:钢琴版|吉他版|原版|现场版|直播版|翻唱|cover|live|mv|pv|官方|完整版|伴奏|纯音乐|instrumental|official)$',
    caseSensitive: false,
  );

  static String? _artistFromRemainder(String remainder) {
    return _clipArtist(remainder.replaceFirst(RegExp(r'^[\s\-—–:：]+'), ''));
  }

  static String? _clipArtist(String value) {
    final polished = _polish(value);
    if (polished.isEmpty || _versionOnly.hasMatch(polished)) return null;
    final token =
        polished.length <= 20 &&
            !polished.contains('，') &&
            !polished.contains('。')
        ? polished
        : polished.split(RegExp(r'\s+')).first;
    if (token.isEmpty || token.length > 20) return null;
    if (token.contains('，') || token.contains('。')) return null;
    if (_versionOnly.hasMatch(token)) return null;
    return token;
  }

  /// 从JSON字符串加载配置
  static TitleCleaner fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final config = TitleRuleConfig.fromJson(json);
    return TitleCleaner(config);
  }
}
