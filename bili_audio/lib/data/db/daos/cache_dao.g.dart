// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_dao.dart';

// ignore_for_file: type=lint
mixin _$CacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CacheIndexTable get cacheIndex => attachedDatabase.cacheIndex;
  CacheDaoManager get managers => CacheDaoManager(this);
}

class CacheDaoManager {
  final _$CacheDaoMixin _db;
  CacheDaoManager(this._db);
  $$CacheIndexTableTableManager get cacheIndex =>
      $$CacheIndexTableTableManager(_db.attachedDatabase, _db.cacheIndex);
}
