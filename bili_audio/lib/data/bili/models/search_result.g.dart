// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchResult _$SearchResultFromJson(Map<String, dynamic> json) =>
    _SearchResult(
      bvid: json['bvid'] as String,
      title: json['title'] as String,
      cleanTitle: json['cleanTitle'] as String,
      duration: (json['duration'] as num).toInt(),
      cover: json['cover'] as String,
      author: json['author'] as String,
      play: (json['play'] as num).toInt(),
      description: json['description'] as String?,
      filtered: json['filtered'] as bool?,
    );

Map<String, dynamic> _$SearchResultToJson(_SearchResult instance) =>
    <String, dynamic>{
      'bvid': instance.bvid,
      'title': instance.title,
      'cleanTitle': instance.cleanTitle,
      'duration': instance.duration,
      'cover': instance.cover,
      'author': instance.author,
      'play': instance.play,
      'description': instance.description,
      'filtered': instance.filtered,
    };
