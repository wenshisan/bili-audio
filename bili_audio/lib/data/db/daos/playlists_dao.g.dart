// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlists_dao.dart';

// ignore_for_file: type=lint
mixin _$PlaylistsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaylistsTable get playlists => attachedDatabase.playlists;
  $TracksTable get tracks => attachedDatabase.tracks;
  $PlaylistTracksTable get playlistTracks => attachedDatabase.playlistTracks;
  PlaylistsDaoManager get managers => PlaylistsDaoManager(this);
}

class PlaylistsDaoManager {
  final _$PlaylistsDaoMixin _db;
  PlaylistsDaoManager(this._db);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db.attachedDatabase, _db.playlists);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(
        _db.attachedDatabase,
        _db.playlistTracks,
      );
}
