// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_url.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StreamUrl _$StreamUrlFromJson(Map<String, dynamic> json) => _StreamUrl(
  bvid: json['bvid'] as String,
  cid: (json['cid'] as num).toInt(),
  quality: $enumDecode(_$AudioQualityEnumMap, json['quality']),
  url: json['url'] as String,
  backupUrl: json['backupUrl'] as String?,
  expiresAt: (json['expiresAt'] as num).toInt(),
);

Map<String, dynamic> _$StreamUrlToJson(_StreamUrl instance) =>
    <String, dynamic>{
      'bvid': instance.bvid,
      'cid': instance.cid,
      'quality': _$AudioQualityEnumMap[instance.quality]!,
      'url': instance.url,
      'backupUrl': instance.backupUrl,
      'expiresAt': instance.expiresAt,
    };

const _$AudioQualityEnumMap = {
  AudioQuality.k64: 'k64',
  AudioQuality.k132: 'k132',
  AudioQuality.k192: 'k192',
  AudioQuality.dolby: 'dolby',
  AudioQuality.hiRes: 'hiRes',
};
