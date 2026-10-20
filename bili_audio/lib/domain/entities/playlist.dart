import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

/// 歌单 (M1.1)
///
/// 本地创建的播放列表，对应 dev-tasks 中的 "本地歌单"。
/// 数据库存储在 playlists 表，track 关联存在 playlist_tracks 表。
@freezed
sealed class Playlist with _$Playlist {
  const factory Playlist({
    /// 歌单 ID (UUID)
    required String id,

    /// 歌单名称
    required String name,

    /// 封面 URL 或本地路径 (可选，默认取首曲封面)
    String? cover,

    /// 创建时间 (Unix timestamp)
    required int createdAt,

    /// 最后修改时间 (Unix timestamp)
    required int updatedAt,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
}
