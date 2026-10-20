// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracks_dao.dart';

// ignore_for_file: type=lint
mixin _$TracksDaoMixin on DatabaseAccessor<AppDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  TracksDaoManager get managers => TracksDaoManager(this);
}

class TracksDaoManager {
  final _$TracksDaoMixin _db;
  TracksDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
}
