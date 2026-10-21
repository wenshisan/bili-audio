// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_dao.dart';

// ignore_for_file: type=lint
mixin _$LyricsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $LyricsCacheTable get lyricsCache => attachedDatabase.lyricsCache;
  LyricsDaoManager get managers => LyricsDaoManager(this);
}

class LyricsDaoManager {
  final _$LyricsDaoMixin _db;
  LyricsDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$LyricsCacheTableTableManager get lyricsCache =>
      $$LyricsCacheTableTableManager(_db.attachedDatabase, _db.lyricsCache);
}
