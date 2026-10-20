// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'title_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TitleRuleConfig _$TitleRuleConfigFromJson(Map<String, dynamic> json) =>
    _TitleRuleConfig(
      version: (json['version'] as num).toInt(),
      rules: (json['rules'] as List<dynamic>)
          .map((e) => TitleRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TitleRuleConfigToJson(_TitleRuleConfig instance) =>
    <String, dynamic>{
      'version': instance.version,
      'rules': instance.rules.map((e) => e.toJson()).toList(),
    };

_TitleRule _$TitleRuleFromJson(Map<String, dynamic> json) => _TitleRule(
  id: json['id'] as String,
  type: json['type'] as String,
  pattern: json['pattern'] as String,
  enabled: json['enabled'] as bool? ?? true,
  flag: json['flag'] as String?,
  order: json['order'] as String?,
  group: json['group'] as String?,
  priority: (json['priority'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TitleRuleToJson(_TitleRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'pattern': instance.pattern,
      'enabled': instance.enabled,
      'flag': instance.flag,
      'order': instance.order,
      'group': instance.group,
      'priority': instance.priority,
    };

_CleanedTitle _$CleanedTitleFromJson(Map<String, dynamic> json) =>
    _CleanedTitle(
      name: json['name'] as String,
      artist: json['artist'] as String?,
      artistCandidates:
          (json['artistCandidates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      flags:
          (json['flags'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
          const {},
      appliedRuleIds:
          (json['appliedRuleIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CleanedTitleToJson(_CleanedTitle instance) =>
    <String, dynamic>{
      'name': instance.name,
      'artist': instance.artist,
      'artistCandidates': instance.artistCandidates,
      'flags': instance.flags.toList(),
      'appliedRuleIds': instance.appliedRuleIds,
    };
