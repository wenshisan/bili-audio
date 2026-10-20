import 'package:freezed_annotation/freezed_annotation.dart';

part 'title_rule.freezed.dart';
part 'title_rule.g.dart';

/// 标题清洗规则配置 (M1.3)
@freezed
sealed class TitleRuleConfig with _$TitleRuleConfig {
  const factory TitleRuleConfig({
    required int version,
    required List<TitleRule> rules,
  }) = _TitleRuleConfig;

  factory TitleRuleConfig.fromJson(Map<String, dynamic> json) =>
      _$TitleRuleConfigFromJson(json);
}

/// 单条标题清洗规则 (M1.3)
@freezed
sealed class TitleRule with _$TitleRule {
  const factory TitleRule({
    required String id,
    required String type,
    required String pattern,
    @Default(true) bool enabled,
    String? flag,
    String? order,
    String? group,
    @Default(0) int priority,
  }) = _TitleRule;

  factory TitleRule.fromJson(Map<String, dynamic> json) =>
      _$TitleRuleFromJson(json);
}

/// 清洗结果 (M1.3)
@freezed
sealed class CleanedTitle with _$CleanedTitle {
  const factory CleanedTitle({
    required String name,
    String? artist,
    @Default([]) List<String> artistCandidates,
    @Default({}) Set<String> flags,
    @Default([]) List<String> appliedRuleIds,
  }) = _CleanedTitle;

  factory CleanedTitle.fromJson(Map<String, dynamic> json) =>
      _$CleanedTitleFromJson(json);
}
