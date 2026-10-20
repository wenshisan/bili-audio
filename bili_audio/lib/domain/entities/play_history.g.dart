// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayHistory _$PlayHistoryFromJson(Map<String, dynamic> json) => _PlayHistory(
  id: (json['id'] as num?)?.toInt(),
  bvid: json['bvid'] as String,
  cid: (json['cid'] as num).toInt(),
  playedAt: (json['playedAt'] as num).toInt(),
  positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
  completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$PlayHistoryToJson(_PlayHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bvid': instance.bvid,
      'cid': instance.cid,
      'playedAt': instance.playedAt,
      'positionMs': instance.positionMs,
      'completion': instance.completion,
    };
