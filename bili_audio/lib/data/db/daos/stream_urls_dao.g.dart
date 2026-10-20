// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_urls_dao.dart';

// ignore_for_file: type=lint
mixin _$StreamUrlsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TracksTable get tracks => attachedDatabase.tracks;
  $StreamUrlsTable get streamUrls => attachedDatabase.streamUrls;
  StreamUrlsDaoManager get managers => StreamUrlsDaoManager(this);
}

class StreamUrlsDaoManager {
  final _$StreamUrlsDaoMixin _db;
  StreamUrlsDaoManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db.attachedDatabase, _db.tracks);
  $$StreamUrlsTableTableManager get streamUrls =>
      $$StreamUrlsTableTableManager(_db.attachedDatabase, _db.streamUrls);
}
