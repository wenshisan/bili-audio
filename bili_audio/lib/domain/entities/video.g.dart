// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoPage _$VideoPageFromJson(Map<String, dynamic> json) => _VideoPage(
  cid: (json['cid'] as num).toInt(),
  title: json['title'] as String,
  duration: Duration(microseconds: (json['duration'] as num).toInt()),
  pageIndex: (json['pageIndex'] as num).toInt(),
);

Map<String, dynamic> _$VideoPageToJson(_VideoPage instance) =>
    <String, dynamic>{
      'cid': instance.cid,
      'title': instance.title,
      'duration': instance.duration.inMicroseconds,
      'pageIndex': instance.pageIndex,
    };

_Video _$VideoFromJson(Map<String, dynamic> json) => _Video(
  bvid: json['bvid'] as String,
  title: json['title'] as String,
  uploader: json['uploader'] as String,
  uploaderMid: (json['uploaderMid'] as num).toInt(),
  cover: json['cover'] as String,
  pages: (json['pages'] as List<dynamic>)
      .map((e) => VideoPage.fromJson(e as Map<String, dynamic>))
      .toList(),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  viewCount: (json['viewCount'] as num?)?.toInt(),
  publishTime: (json['publishTime'] as num?)?.toInt(),
);

Map<String, dynamic> _$VideoToJson(_Video instance) => <String, dynamic>{
  'bvid': instance.bvid,
  'title': instance.title,
  'uploader': instance.uploader,
  'uploaderMid': instance.uploaderMid,
  'cover': instance.cover,
  'pages': instance.pages.map((e) => e.toJson()).toList(),
  'tags': instance.tags,
  'viewCount': instance.viewCount,
  'publishTime': instance.publishTime,
};
