// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LyricLine _$LyricLineFromJson(Map<String, dynamic> json) => _LyricLine(
  timestamp: Duration(microseconds: (json['timestamp'] as num).toInt()),
  text: json['text'] as String,
  translation: json['translation'] as String?,
);

Map<String, dynamic> _$LyricLineToJson(_LyricLine instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.inMicroseconds,
      'text': instance.text,
      'translation': instance.translation,
    };

_Lyrics _$LyricsFromJson(Map<String, dynamic> json) => _Lyrics(
  lines: (json['lines'] as List<dynamic>)
      .map((e) => LyricLine.fromJson(e as Map<String, dynamic>))
      .toList(),
  offset: json['offset'] == null
      ? Duration.zero
      : Duration(microseconds: (json['offset'] as num).toInt()),
  source: json['source'] as String?,
  matchScore: (json['matchScore'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LyricsToJson(_Lyrics instance) => <String, dynamic>{
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'offset': instance.offset.inMicroseconds,
  'source': instance.source,
  'matchScore': instance.matchScore,
};
