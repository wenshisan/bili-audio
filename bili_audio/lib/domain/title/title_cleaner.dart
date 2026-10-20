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
    var workingTitle = normalizeForDisplay(rawTitle);

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
    final extractSplitRules = enabledRules
        .where((r) => r.type == 'extract' || r.type == 'split')
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    String? extractedTitle;
    String? extractedArtist;

    for (final rule in extractSplitRules) {
      if (rule.type == 'extract') {
        final regex = RegExp(rule.pattern);
        final match = regex.firstMatch(workingTitle);
        if (match != null && match.groupCount >= 1) {
          final extracted = match.group(1)!.trim();
          if (rule.group == 'title') {
            extractedTitle = extracted;
          } else if (rule.group == 'artist') {
            extractedArtist = extracted;
          }
          appliedRules.add(rule.id);
          break;
        }
      } else if (rule.type == 'split') {
        final regex = RegExp(rule.pattern);
        final parts = workingTitle.split(regex);
        if (parts.length == 2) {
          final left = parts[0].trim();
          final right = parts[1].trim();
          if (left.isNotEmpty && right.isNotEmpty) {
            if (rule.order == 'title_artist') {
              extractedTitle = left;
              extractedArtist = right;
            } else if (rule.order == 'artist_title') {
              extractedArtist = left;
              extractedTitle = right;
            }
            appliedRules.add(rule.id);
            break;
          }
        }
      }
    }

    // 4. 兜底逻辑
    final name = extractedTitle ?? workingTitle;
    final artist = extractedArtist;
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

  /// 从JSON字符串加载配置
  static TitleCleaner fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final config = TitleRuleConfig.fromJson(json);
    return TitleCleaner(config);
  }
}
