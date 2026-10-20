// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Track _$TrackFromJson(Map<String, dynamic> json) => _Track(
  bvid: json['bvid'] as String,
  cid: (json['cid'] as num).toInt(),
  title: json['title'] as String,
  cleanedName: json['cleanedName'] as String?,
  artist: json['artist'] as String?,
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  cover: json['cover'] as String?,
  uploader: json['uploader'] as String?,
  pageIndex: (json['pageIndex'] as num?)?.toInt(),
  totalPages: (json['totalPages'] as num?)?.toInt(),
);

Map<String, dynamic> _$TrackToJson(_Track instance) => <String, dynamic>{
  'bvid': instance.bvid,
  'cid': instance.cid,
  'title': instance.title,
  'cleanedName': instance.cleanedName,
  'artist': instance.artist,
  'duration': instance.duration.inMicroseconds,
  'cover': instance.cover,
  'uploader': instance.uploader,
  'pageIndex': instance.pageIndex,
  'totalPages': instance.totalPages,
};
