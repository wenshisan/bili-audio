import 'package:audio_service/audio_service.dart';

import '../../domain/entities/audio_track.dart';
import '../db/app_database.dart' as db;

/// 一次浏览树点播：整表播放，或跳到当前队列的下标。
class BrowsePlay {
  const BrowsePlay.tracks(this.tracks, {this.start = 0}) : queueIndex = null;

  const BrowsePlay.queue(this.queueIndex)
      : tracks = null,
        start = 0;

  final List<Track>? tracks;
  final int start;
  final int? queueIndex;
}

/// Android Auto / 车机媒体浏览树。
///
/// 只暴露正在播放、本地歌单、最近播放。车机用系统界面，不嵌入 Flutter。
class MediaLibrary {
  MediaLibrary(this.database, this.queueTracks);

  final db.AppDatabase database;
  final List<Track> Function() queueTracks;

  static const root = 'root';
  static const nowPlaying = 'now_playing';
  static const playlists = 'playlists';
  static const recent = 'recent';

  Future<List<MediaItem>> children(String parentId) async {
    final id = parentId.isEmpty ? root : parentId;
    if (id == root) {
      return const [
        MediaItem(id: nowPlaying, title: '正在播放', playable: false),
        MediaItem(id: playlists, title: '歌单', playable: false),
        MediaItem(id: recent, title: '最近播放', playable: false),
      ];
    }
    if (id == nowPlaying) {
      final tracks = queueTracks();
      return [
        for (var i = 0; i < tracks.length; i++)
          _item('queue:$i', tracks[i], playable: true),
      ];
    }
    if (id == playlists) {
      final rows = await database.playlistsDao.getAllPlaylists();
      return [
        for (final row in rows)
          MediaItem(id: 'playlist:${row.id}', title: row.name, playable: false),
      ];
    }
    if (id.startsWith('playlist:')) {
      final playlistId = int.tryParse(id.substring('playlist:'.length));
      if (playlistId == null) return const [];
      final rows = await database.playlistsDao.getPlaylistTracks(playlistId);
      return [
        for (final row in rows)
          _item('pl:$playlistId:${row.bvid}:${row.cid}', _map(row), playable: true),
      ];
    }
    if (id == recent) {
      final entries = await database.historyDao.watchRecent(limit: 50).first;
      final seen = <String>{};
      final items = <MediaItem>[];
      for (final entry in entries) {
        final track = _map(entry.track);
        final key = '${track.bvid}:${track.cid}';
        if (!seen.add(key)) continue;
        items.add(_item('hist:$key', track, playable: true));
      }
      return items;
    }
    return const [];
  }

  Future<BrowsePlay?> resolve(String mediaId) async {
    if (mediaId.startsWith('queue:')) {
      final index = int.tryParse(mediaId.substring('queue:'.length));
      if (index == null) return null;
      return BrowsePlay.queue(index);
    }
    if (mediaId.startsWith('playlist:')) {
      final playlistId = int.tryParse(mediaId.substring('playlist:'.length));
      if (playlistId == null) return null;
      final tracks = [
        for (final row in await database.playlistsDao.getPlaylistTracks(playlistId)) _map(row),
      ];
      if (tracks.isEmpty) return null;
      return BrowsePlay.tracks(tracks);
    }
    if (mediaId.startsWith('pl:')) {
      final parts = mediaId.split(':');
      if (parts.length < 4) return null;
      final playlistId = int.tryParse(parts[1]);
      if (playlistId == null) return null;
      final tracks = [
        for (final row in await database.playlistsDao.getPlaylistTracks(playlistId)) _map(row),
      ];
      final index = tracks.indexWhere((t) => t.bvid == parts[2] && '${t.cid}' == parts[3]);
      if (index < 0) return null;
      return BrowsePlay.tracks(tracks, start: index);
    }
    if (mediaId.startsWith('hist:')) {
      final parts = mediaId.split(':');
      if (parts.length < 3) return null;
      final cid = int.tryParse(parts[2]);
      if (cid == null) return null;
      final row = await database.tracksDao.getTrack(parts[1], cid);
      if (row == null) return null;
      return BrowsePlay.tracks([_map(row)]);
    }
    return null;
  }

  MediaItem _item(String id, Track track, {required bool playable}) => MediaItem(
        id: id,
        title: track.displayTitle,
        artist: track.displayArtist,
        duration: track.duration,
        playable: playable,
      );

  Track _map(db.Track row) => Track(
        bvid: row.bvid,
        cid: row.cid,
        title: row.title,
        cleanedName: row.cleanedName,
        artist: row.artist,
        duration: Duration(seconds: row.duration),
        cover: row.cover,
        uploader: row.uploader,
        pageIndex: row.pageIndex,
        totalPages: row.totalPages,
      );
}
