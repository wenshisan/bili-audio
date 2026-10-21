// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
    'bvid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cidMeta = const VerificationMeta('cid');
  @override
  late final GeneratedColumn<int> cid = GeneratedColumn<int>(
    'cid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanedNameMeta = const VerificationMeta(
    'cleanedName',
  );
  @override
  late final GeneratedColumn<String> cleanedName = GeneratedColumn<String>(
    'cleaned_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userEditedMeta = const VerificationMeta(
    'userEdited',
  );
  @override
  late final GeneratedColumn<bool> userEdited = GeneratedColumn<bool>(
    'user_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploaderMeta = const VerificationMeta(
    'uploader',
  );
  @override
  late final GeneratedColumn<String> uploader = GeneratedColumn<String>(
    'uploader',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bvid,
    cid,
    title,
    cleanedName,
    artist,
    userEdited,
    duration,
    cover,
    uploader,
    pageIndex,
    totalPages,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bvid')) {
      context.handle(
        _bvidMeta,
        bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta),
      );
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('cid')) {
      context.handle(
        _cidMeta,
        cid.isAcceptableOrUnknown(data['cid']!, _cidMeta),
      );
    } else if (isInserting) {
      context.missing(_cidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cleaned_name')) {
      context.handle(
        _cleanedNameMeta,
        cleanedName.isAcceptableOrUnknown(
          data['cleaned_name']!,
          _cleanedNameMeta,
        ),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('user_edited')) {
      context.handle(
        _userEditedMeta,
        userEdited.isAcceptableOrUnknown(data['user_edited']!, _userEditedMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('uploader')) {
      context.handle(
        _uploaderMeta,
        uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta),
      );
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bvid, cid};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      bvid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bvid'],
      )!,
      cid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cleanedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cleaned_name'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      userEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_edited'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      uploader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploader'],
      ),
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      ),
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final String bvid;
  final int cid;
  final String title;
  final String? cleanedName;
  final String? artist;
  final bool userEdited;
  final int duration;
  final String? cover;
  final String? uploader;
  final int? pageIndex;
  final int? totalPages;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Track({
    required this.bvid,
    required this.cid,
    required this.title,
    this.cleanedName,
    this.artist,
    required this.userEdited,
    required this.duration,
    this.cover,
    this.uploader,
    this.pageIndex,
    this.totalPages,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bvid'] = Variable<String>(bvid);
    map['cid'] = Variable<int>(cid);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || cleanedName != null) {
      map['cleaned_name'] = Variable<String>(cleanedName);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    map['user_edited'] = Variable<bool>(userEdited);
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    if (!nullToAbsent || uploader != null) {
      map['uploader'] = Variable<String>(uploader);
    }
    if (!nullToAbsent || pageIndex != null) {
      map['page_index'] = Variable<int>(pageIndex);
    }
    if (!nullToAbsent || totalPages != null) {
      map['total_pages'] = Variable<int>(totalPages);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      bvid: Value(bvid),
      cid: Value(cid),
      title: Value(title),
      cleanedName: cleanedName == null && nullToAbsent
          ? const Value.absent()
          : Value(cleanedName),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      userEdited: Value(userEdited),
      duration: Value(duration),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      uploader: uploader == null && nullToAbsent
          ? const Value.absent()
          : Value(uploader),
      pageIndex: pageIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pageIndex),
      totalPages: totalPages == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPages),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      bvid: serializer.fromJson<String>(json['bvid']),
      cid: serializer.fromJson<int>(json['cid']),
      title: serializer.fromJson<String>(json['title']),
      cleanedName: serializer.fromJson<String?>(json['cleanedName']),
      artist: serializer.fromJson<String?>(json['artist']),
      userEdited: serializer.fromJson<bool>(json['userEdited']),
      duration: serializer.fromJson<int>(json['duration']),
      cover: serializer.fromJson<String?>(json['cover']),
      uploader: serializer.fromJson<String?>(json['uploader']),
      pageIndex: serializer.fromJson<int?>(json['pageIndex']),
      totalPages: serializer.fromJson<int?>(json['totalPages']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bvid': serializer.toJson<String>(bvid),
      'cid': serializer.toJson<int>(cid),
      'title': serializer.toJson<String>(title),
      'cleanedName': serializer.toJson<String?>(cleanedName),
      'artist': serializer.toJson<String?>(artist),
      'userEdited': serializer.toJson<bool>(userEdited),
      'duration': serializer.toJson<int>(duration),
      'cover': serializer.toJson<String?>(cover),
      'uploader': serializer.toJson<String?>(uploader),
      'pageIndex': serializer.toJson<int?>(pageIndex),
      'totalPages': serializer.toJson<int?>(totalPages),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Track copyWith({
    String? bvid,
    int? cid,
    String? title,
    Value<String?> cleanedName = const Value.absent(),
    Value<String?> artist = const Value.absent(),
    bool? userEdited,
    int? duration,
    Value<String?> cover = const Value.absent(),
    Value<String?> uploader = const Value.absent(),
    Value<int?> pageIndex = const Value.absent(),
    Value<int?> totalPages = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Track(
    bvid: bvid ?? this.bvid,
    cid: cid ?? this.cid,
    title: title ?? this.title,
    cleanedName: cleanedName.present ? cleanedName.value : this.cleanedName,
    artist: artist.present ? artist.value : this.artist,
    userEdited: userEdited ?? this.userEdited,
    duration: duration ?? this.duration,
    cover: cover.present ? cover.value : this.cover,
    uploader: uploader.present ? uploader.value : this.uploader,
    pageIndex: pageIndex.present ? pageIndex.value : this.pageIndex,
    totalPages: totalPages.present ? totalPages.value : this.totalPages,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      cid: data.cid.present ? data.cid.value : this.cid,
      title: data.title.present ? data.title.value : this.title,
      cleanedName: data.cleanedName.present
          ? data.cleanedName.value
          : this.cleanedName,
      artist: data.artist.present ? data.artist.value : this.artist,
      userEdited: data.userEdited.present
          ? data.userEdited.value
          : this.userEdited,
      duration: data.duration.present ? data.duration.value : this.duration,
      cover: data.cover.present ? data.cover.value : this.cover,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('title: $title, ')
          ..write('cleanedName: $cleanedName, ')
          ..write('artist: $artist, ')
          ..write('userEdited: $userEdited, ')
          ..write('duration: $duration, ')
          ..write('cover: $cover, ')
          ..write('uploader: $uploader, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('totalPages: $totalPages, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bvid,
    cid,
    title,
    cleanedName,
    artist,
    userEdited,
    duration,
    cover,
    uploader,
    pageIndex,
    totalPages,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.bvid == this.bvid &&
          other.cid == this.cid &&
          other.title == this.title &&
          other.cleanedName == this.cleanedName &&
          other.artist == this.artist &&
          other.userEdited == this.userEdited &&
          other.duration == this.duration &&
          other.cover == this.cover &&
          other.uploader == this.uploader &&
          other.pageIndex == this.pageIndex &&
          other.totalPages == this.totalPages &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<String> bvid;
  final Value<int> cid;
  final Value<String> title;
  final Value<String?> cleanedName;
  final Value<String?> artist;
  final Value<bool> userEdited;
  final Value<int> duration;
  final Value<String?> cover;
  final Value<String?> uploader;
  final Value<int?> pageIndex;
  final Value<int?> totalPages;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TracksCompanion({
    this.bvid = const Value.absent(),
    this.cid = const Value.absent(),
    this.title = const Value.absent(),
    this.cleanedName = const Value.absent(),
    this.artist = const Value.absent(),
    this.userEdited = const Value.absent(),
    this.duration = const Value.absent(),
    this.cover = const Value.absent(),
    this.uploader = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String bvid,
    required int cid,
    required String title,
    this.cleanedName = const Value.absent(),
    this.artist = const Value.absent(),
    this.userEdited = const Value.absent(),
    required int duration,
    this.cover = const Value.absent(),
    this.uploader = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bvid = Value(bvid),
       cid = Value(cid),
       title = Value(title),
       duration = Value(duration);
  static Insertable<Track> custom({
    Expression<String>? bvid,
    Expression<int>? cid,
    Expression<String>? title,
    Expression<String>? cleanedName,
    Expression<String>? artist,
    Expression<bool>? userEdited,
    Expression<int>? duration,
    Expression<String>? cover,
    Expression<String>? uploader,
    Expression<int>? pageIndex,
    Expression<int>? totalPages,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bvid != null) 'bvid': bvid,
      if (cid != null) 'cid': cid,
      if (title != null) 'title': title,
      if (cleanedName != null) 'cleaned_name': cleanedName,
      if (artist != null) 'artist': artist,
      if (userEdited != null) 'user_edited': userEdited,
      if (duration != null) 'duration': duration,
      if (cover != null) 'cover': cover,
      if (uploader != null) 'uploader': uploader,
      if (pageIndex != null) 'page_index': pageIndex,
      if (totalPages != null) 'total_pages': totalPages,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith({
    Value<String>? bvid,
    Value<int>? cid,
    Value<String>? title,
    Value<String?>? cleanedName,
    Value<String?>? artist,
    Value<bool>? userEdited,
    Value<int>? duration,
    Value<String?>? cover,
    Value<String?>? uploader,
    Value<int?>? pageIndex,
    Value<int?>? totalPages,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TracksCompanion(
      bvid: bvid ?? this.bvid,
      cid: cid ?? this.cid,
      title: title ?? this.title,
      cleanedName: cleanedName ?? this.cleanedName,
      artist: artist ?? this.artist,
      userEdited: userEdited ?? this.userEdited,
      duration: duration ?? this.duration,
      cover: cover ?? this.cover,
      uploader: uploader ?? this.uploader,
      pageIndex: pageIndex ?? this.pageIndex,
      totalPages: totalPages ?? this.totalPages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (cid.present) {
      map['cid'] = Variable<int>(cid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cleanedName.present) {
      map['cleaned_name'] = Variable<String>(cleanedName.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (userEdited.present) {
      map['user_edited'] = Variable<bool>(userEdited.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('title: $title, ')
          ..write('cleanedName: $cleanedName, ')
          ..write('artist: $artist, ')
          ..write('userEdited: $userEdited, ')
          ..write('duration: $duration, ')
          ..write('cover: $cover, ')
          ..write('uploader: $uploader, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('totalPages: $totalPages, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadonlyMeta = const VerificationMeta(
    'isReadonly',
  );
  @override
  late final GeneratedColumn<bool> isReadonly = GeneratedColumn<bool>(
    'is_readonly',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_readonly" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    cover,
    isReadonly,
    source,
    sourceId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('is_readonly')) {
      context.handle(
        _isReadonlyMeta,
        isReadonly.isAcceptableOrUnknown(data['is_readonly']!, _isReadonlyMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      isReadonly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_readonly'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final String? cover;
  final bool isReadonly;
  final String? source;
  final String? sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Playlist({
    required this.id,
    required this.name,
    this.cover,
    required this.isReadonly,
    this.source,
    this.sourceId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    map['is_readonly'] = Variable<bool>(isReadonly);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      isReadonly: Value(isReadonly),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      cover: serializer.fromJson<String?>(json['cover']),
      isReadonly: serializer.fromJson<bool>(json['isReadonly']),
      source: serializer.fromJson<String?>(json['source']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'cover': serializer.toJson<String?>(cover),
      'isReadonly': serializer.toJson<bool>(isReadonly),
      'source': serializer.toJson<String?>(source),
      'sourceId': serializer.toJson<String?>(sourceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    Value<String?> cover = const Value.absent(),
    bool? isReadonly,
    Value<String?> source = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    cover: cover.present ? cover.value : this.cover,
    isReadonly: isReadonly ?? this.isReadonly,
    source: source.present ? source.value : this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      cover: data.cover.present ? data.cover.value : this.cover,
      isReadonly: data.isReadonly.present
          ? data.isReadonly.value
          : this.isReadonly,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('isReadonly: $isReadonly, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    cover,
    isReadonly,
    source,
    sourceId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.cover == this.cover &&
          other.isReadonly == this.isReadonly &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> cover;
  final Value<bool> isReadonly;
  final Value<String?> source;
  final Value<String?> sourceId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.cover = const Value.absent(),
    this.isReadonly = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.cover = const Value.absent(),
    this.isReadonly = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? cover,
    Expression<bool>? isReadonly,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (cover != null) 'cover': cover,
      if (isReadonly != null) 'is_readonly': isReadonly,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? cover,
    Value<bool>? isReadonly,
    Value<String?>? source,
    Value<String?>? sourceId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      isReadonly: isReadonly ?? this.isReadonly,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (isReadonly.present) {
      map['is_readonly'] = Variable<bool>(isReadonly.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('isReadonly: $isReadonly, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTable extends PlaylistTracks
    with TableInfo<$PlaylistTracksTable, PlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
    'bvid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cidMeta = const VerificationMeta('cid');
  @override
  late final GeneratedColumn<int> cid = GeneratedColumn<int>(
    'cid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistId,
    bvid,
    cid,
    position,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('bvid')) {
      context.handle(
        _bvidMeta,
        bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta),
      );
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('cid')) {
      context.handle(
        _cidMeta,
        cid.isAcceptableOrUnknown(data['cid']!, _cidMeta),
      );
    } else if (isInserting) {
      context.missing(_cidMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, bvid, cid};
  @override
  PlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrack(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      bvid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bvid'],
      )!,
      cid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cid'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $PlaylistTracksTable createAlias(String alias) {
    return $PlaylistTracksTable(attachedDatabase, alias);
  }
}

class PlaylistTrack extends DataClass implements Insertable<PlaylistTrack> {
  final int playlistId;
  final String bvid;
  final int cid;
  final int position;
  final DateTime addedAt;
  const PlaylistTrack({
    required this.playlistId,
    required this.bvid,
    required this.cid,
    required this.position,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['bvid'] = Variable<String>(bvid);
    map['cid'] = Variable<int>(cid);
    map['position'] = Variable<int>(position);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  PlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksCompanion(
      playlistId: Value(playlistId),
      bvid: Value(bvid),
      cid: Value(cid),
      position: Value(position),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrack(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      bvid: serializer.fromJson<String>(json['bvid']),
      cid: serializer.fromJson<int>(json['cid']),
      position: serializer.fromJson<int>(json['position']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'bvid': serializer.toJson<String>(bvid),
      'cid': serializer.toJson<int>(cid),
      'position': serializer.toJson<int>(position),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  PlaylistTrack copyWith({
    int? playlistId,
    String? bvid,
    int? cid,
    int? position,
    DateTime? addedAt,
  }) => PlaylistTrack(
    playlistId: playlistId ?? this.playlistId,
    bvid: bvid ?? this.bvid,
    cid: cid ?? this.cid,
    position: position ?? this.position,
    addedAt: addedAt ?? this.addedAt,
  );
  PlaylistTrack copyWithCompanion(PlaylistTracksCompanion data) {
    return PlaylistTrack(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      cid: data.cid.present ? data.cid.value : this.cid,
      position: data.position.present ? data.position.value : this.position,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrack(')
          ..write('playlistId: $playlistId, ')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, bvid, cid, position, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrack &&
          other.playlistId == this.playlistId &&
          other.bvid == this.bvid &&
          other.cid == this.cid &&
          other.position == this.position &&
          other.addedAt == this.addedAt);
}

class PlaylistTracksCompanion extends UpdateCompanion<PlaylistTrack> {
  final Value<int> playlistId;
  final Value<String> bvid;
  final Value<int> cid;
  final Value<int> position;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const PlaylistTracksCompanion({
    this.playlistId = const Value.absent(),
    this.bvid = const Value.absent(),
    this.cid = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTracksCompanion.insert({
    required int playlistId,
    required String bvid,
    required int cid,
    required int position,
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       bvid = Value(bvid),
       cid = Value(cid),
       position = Value(position);
  static Insertable<PlaylistTrack> custom({
    Expression<int>? playlistId,
    Expression<String>? bvid,
    Expression<int>? cid,
    Expression<int>? position,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (bvid != null) 'bvid': bvid,
      if (cid != null) 'cid': cid,
      if (position != null) 'position': position,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTracksCompanion copyWith({
    Value<int>? playlistId,
    Value<String>? bvid,
    Value<int>? cid,
    Value<int>? position,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return PlaylistTracksCompanion(
      playlistId: playlistId ?? this.playlistId,
      bvid: bvid ?? this.bvid,
      cid: cid ?? this.cid,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (cid.present) {
      map['cid'] = Variable<int>(cid.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory
    with TableInfo<$PlayHistoryTable, PlayHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
    'bvid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cidMeta = const VerificationMeta('cid');
  @override
  late final GeneratedColumn<int> cid = GeneratedColumn<int>(
    'cid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completionMeta = const VerificationMeta(
    'completion',
  );
  @override
  late final GeneratedColumn<double> completion = GeneratedColumn<double>(
    'completion',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bvid,
    cid,
    playedAt,
    positionMs,
    completion,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bvid')) {
      context.handle(
        _bvidMeta,
        bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta),
      );
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('cid')) {
      context.handle(
        _cidMeta,
        cid.isAcceptableOrUnknown(data['cid']!, _cidMeta),
      );
    } else if (isInserting) {
      context.missing(_cidMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('completion')) {
      context.handle(
        _completionMeta,
        completion.isAcceptableOrUnknown(data['completion']!, _completionMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bvid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bvid'],
      )!,
      cid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cid'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      completion: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }
}

class PlayHistoryData extends DataClass implements Insertable<PlayHistoryData> {
  final int id;
  final String bvid;
  final int cid;
  final DateTime playedAt;
  final int positionMs;
  final double completion;
  final String? source;
  const PlayHistoryData({
    required this.id,
    required this.bvid,
    required this.cid,
    required this.playedAt,
    required this.positionMs,
    required this.completion,
    this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bvid'] = Variable<String>(bvid);
    map['cid'] = Variable<int>(cid);
    map['played_at'] = Variable<DateTime>(playedAt);
    map['position_ms'] = Variable<int>(positionMs);
    map['completion'] = Variable<double>(completion);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(
      id: Value(id),
      bvid: Value(bvid),
      cid: Value(cid),
      playedAt: Value(playedAt),
      positionMs: Value(positionMs),
      completion: Value(completion),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
    );
  }

  factory PlayHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryData(
      id: serializer.fromJson<int>(json['id']),
      bvid: serializer.fromJson<String>(json['bvid']),
      cid: serializer.fromJson<int>(json['cid']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      completion: serializer.fromJson<double>(json['completion']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bvid': serializer.toJson<String>(bvid),
      'cid': serializer.toJson<int>(cid),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'positionMs': serializer.toJson<int>(positionMs),
      'completion': serializer.toJson<double>(completion),
      'source': serializer.toJson<String?>(source),
    };
  }

  PlayHistoryData copyWith({
    int? id,
    String? bvid,
    int? cid,
    DateTime? playedAt,
    int? positionMs,
    double? completion,
    Value<String?> source = const Value.absent(),
  }) => PlayHistoryData(
    id: id ?? this.id,
    bvid: bvid ?? this.bvid,
    cid: cid ?? this.cid,
    playedAt: playedAt ?? this.playedAt,
    positionMs: positionMs ?? this.positionMs,
    completion: completion ?? this.completion,
    source: source.present ? source.value : this.source,
  );
  PlayHistoryData copyWithCompanion(PlayHistoryCompanion data) {
    return PlayHistoryData(
      id: data.id.present ? data.id.value : this.id,
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      cid: data.cid.present ? data.cid.value : this.cid,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      completion: data.completion.present
          ? data.completion.value
          : this.completion,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryData(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('playedAt: $playedAt, ')
          ..write('positionMs: $positionMs, ')
          ..write('completion: $completion, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bvid, cid, playedAt, positionMs, completion, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryData &&
          other.id == this.id &&
          other.bvid == this.bvid &&
          other.cid == this.cid &&
          other.playedAt == this.playedAt &&
          other.positionMs == this.positionMs &&
          other.completion == this.completion &&
          other.source == this.source);
}

class PlayHistoryCompanion extends UpdateCompanion<PlayHistoryData> {
  final Value<int> id;
  final Value<String> bvid;
  final Value<int> cid;
  final Value<DateTime> playedAt;
  final Value<int> positionMs;
  final Value<double> completion;
  final Value<String?> source;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.bvid = const Value.absent(),
    this.cid = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.completion = const Value.absent(),
    this.source = const Value.absent(),
  });
  PlayHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String bvid,
    required int cid,
    this.playedAt = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.completion = const Value.absent(),
    this.source = const Value.absent(),
  }) : bvid = Value(bvid),
       cid = Value(cid);
  static Insertable<PlayHistoryData> custom({
    Expression<int>? id,
    Expression<String>? bvid,
    Expression<int>? cid,
    Expression<DateTime>? playedAt,
    Expression<int>? positionMs,
    Expression<double>? completion,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bvid != null) 'bvid': bvid,
      if (cid != null) 'cid': cid,
      if (playedAt != null) 'played_at': playedAt,
      if (positionMs != null) 'position_ms': positionMs,
      if (completion != null) 'completion': completion,
      if (source != null) 'source': source,
    });
  }

  PlayHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? bvid,
    Value<int>? cid,
    Value<DateTime>? playedAt,
    Value<int>? positionMs,
    Value<double>? completion,
    Value<String?>? source,
  }) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      bvid: bvid ?? this.bvid,
      cid: cid ?? this.cid,
      playedAt: playedAt ?? this.playedAt,
      positionMs: positionMs ?? this.positionMs,
      completion: completion ?? this.completion,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (cid.present) {
      map['cid'] = Variable<int>(cid.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (completion.present) {
      map['completion'] = Variable<double>(completion.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('playedAt: $playedAt, ')
          ..write('positionMs: $positionMs, ')
          ..write('completion: $completion, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $LyricsCacheTable extends LyricsCache
    with TableInfo<$LyricsCacheTable, LyricsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
    'bvid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cidMeta = const VerificationMeta('cid');
  @override
  late final GeneratedColumn<int> cid = GeneratedColumn<int>(
    'cid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lrcPathMeta = const VerificationMeta(
    'lrcPath',
  );
  @override
  late final GeneratedColumn<String> lrcPath = GeneratedColumn<String>(
    'lrc_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchScoreMeta = const VerificationMeta(
    'matchScore',
  );
  @override
  late final GeneratedColumn<double> matchScore = GeneratedColumn<double>(
    'match_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offsetMsMeta = const VerificationMeta(
    'offsetMs',
  );
  @override
  late final GeneratedColumn<int> offsetMs = GeneratedColumn<int>(
    'offset_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noLyricsMeta = const VerificationMeta(
    'noLyrics',
  );
  @override
  late final GeneratedColumn<bool> noLyrics = GeneratedColumn<bool>(
    'no_lyrics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("no_lyrics" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bvid,
    cid,
    lrcPath,
    source,
    matchScore,
    offsetMs,
    noLyrics,
    cachedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<LyricsCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bvid')) {
      context.handle(
        _bvidMeta,
        bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta),
      );
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('cid')) {
      context.handle(
        _cidMeta,
        cid.isAcceptableOrUnknown(data['cid']!, _cidMeta),
      );
    } else if (isInserting) {
      context.missing(_cidMeta);
    }
    if (data.containsKey('lrc_path')) {
      context.handle(
        _lrcPathMeta,
        lrcPath.isAcceptableOrUnknown(data['lrc_path']!, _lrcPathMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('match_score')) {
      context.handle(
        _matchScoreMeta,
        matchScore.isAcceptableOrUnknown(data['match_score']!, _matchScoreMeta),
      );
    }
    if (data.containsKey('offset_ms')) {
      context.handle(
        _offsetMsMeta,
        offsetMs.isAcceptableOrUnknown(data['offset_ms']!, _offsetMsMeta),
      );
    }
    if (data.containsKey('no_lyrics')) {
      context.handle(
        _noLyricsMeta,
        noLyrics.isAcceptableOrUnknown(data['no_lyrics']!, _noLyricsMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bvid, cid};
  @override
  LyricsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LyricsCacheData(
      bvid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bvid'],
      )!,
      cid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cid'],
      )!,
      lrcPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lrc_path'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      matchScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}match_score'],
      ),
      offsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_ms'],
      )!,
      noLyrics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}no_lyrics'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LyricsCacheTable createAlias(String alias) {
    return $LyricsCacheTable(attachedDatabase, alias);
  }
}

class LyricsCacheData extends DataClass implements Insertable<LyricsCacheData> {
  final String bvid;
  final int cid;
  final String? lrcPath;
  final String? source;
  final double? matchScore;
  final int offsetMs;
  final bool noLyrics;
  final DateTime cachedAt;
  final DateTime updatedAt;
  const LyricsCacheData({
    required this.bvid,
    required this.cid,
    this.lrcPath,
    this.source,
    this.matchScore,
    required this.offsetMs,
    required this.noLyrics,
    required this.cachedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bvid'] = Variable<String>(bvid);
    map['cid'] = Variable<int>(cid);
    if (!nullToAbsent || lrcPath != null) {
      map['lrc_path'] = Variable<String>(lrcPath);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || matchScore != null) {
      map['match_score'] = Variable<double>(matchScore);
    }
    map['offset_ms'] = Variable<int>(offsetMs);
    map['no_lyrics'] = Variable<bool>(noLyrics);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LyricsCacheCompanion toCompanion(bool nullToAbsent) {
    return LyricsCacheCompanion(
      bvid: Value(bvid),
      cid: Value(cid),
      lrcPath: lrcPath == null && nullToAbsent
          ? const Value.absent()
          : Value(lrcPath),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      matchScore: matchScore == null && nullToAbsent
          ? const Value.absent()
          : Value(matchScore),
      offsetMs: Value(offsetMs),
      noLyrics: Value(noLyrics),
      cachedAt: Value(cachedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LyricsCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LyricsCacheData(
      bvid: serializer.fromJson<String>(json['bvid']),
      cid: serializer.fromJson<int>(json['cid']),
      lrcPath: serializer.fromJson<String?>(json['lrcPath']),
      source: serializer.fromJson<String?>(json['source']),
      matchScore: serializer.fromJson<double?>(json['matchScore']),
      offsetMs: serializer.fromJson<int>(json['offsetMs']),
      noLyrics: serializer.fromJson<bool>(json['noLyrics']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bvid': serializer.toJson<String>(bvid),
      'cid': serializer.toJson<int>(cid),
      'lrcPath': serializer.toJson<String?>(lrcPath),
      'source': serializer.toJson<String?>(source),
      'matchScore': serializer.toJson<double?>(matchScore),
      'offsetMs': serializer.toJson<int>(offsetMs),
      'noLyrics': serializer.toJson<bool>(noLyrics),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LyricsCacheData copyWith({
    String? bvid,
    int? cid,
    Value<String?> lrcPath = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<double?> matchScore = const Value.absent(),
    int? offsetMs,
    bool? noLyrics,
    DateTime? cachedAt,
    DateTime? updatedAt,
  }) => LyricsCacheData(
    bvid: bvid ?? this.bvid,
    cid: cid ?? this.cid,
    lrcPath: lrcPath.present ? lrcPath.value : this.lrcPath,
    source: source.present ? source.value : this.source,
    matchScore: matchScore.present ? matchScore.value : this.matchScore,
    offsetMs: offsetMs ?? this.offsetMs,
    noLyrics: noLyrics ?? this.noLyrics,
    cachedAt: cachedAt ?? this.cachedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LyricsCacheData copyWithCompanion(LyricsCacheCompanion data) {
    return LyricsCacheData(
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      cid: data.cid.present ? data.cid.value : this.cid,
      lrcPath: data.lrcPath.present ? data.lrcPath.value : this.lrcPath,
      source: data.source.present ? data.source.value : this.source,
      matchScore: data.matchScore.present
          ? data.matchScore.value
          : this.matchScore,
      offsetMs: data.offsetMs.present ? data.offsetMs.value : this.offsetMs,
      noLyrics: data.noLyrics.present ? data.noLyrics.value : this.noLyrics,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsCacheData(')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('lrcPath: $lrcPath, ')
          ..write('source: $source, ')
          ..write('matchScore: $matchScore, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('noLyrics: $noLyrics, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bvid,
    cid,
    lrcPath,
    source,
    matchScore,
    offsetMs,
    noLyrics,
    cachedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LyricsCacheData &&
          other.bvid == this.bvid &&
          other.cid == this.cid &&
          other.lrcPath == this.lrcPath &&
          other.source == this.source &&
          other.matchScore == this.matchScore &&
          other.offsetMs == this.offsetMs &&
          other.noLyrics == this.noLyrics &&
          other.cachedAt == this.cachedAt &&
          other.updatedAt == this.updatedAt);
}

class LyricsCacheCompanion extends UpdateCompanion<LyricsCacheData> {
  final Value<String> bvid;
  final Value<int> cid;
  final Value<String?> lrcPath;
  final Value<String?> source;
  final Value<double?> matchScore;
  final Value<int> offsetMs;
  final Value<bool> noLyrics;
  final Value<DateTime> cachedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LyricsCacheCompanion({
    this.bvid = const Value.absent(),
    this.cid = const Value.absent(),
    this.lrcPath = const Value.absent(),
    this.source = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.noLyrics = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LyricsCacheCompanion.insert({
    required String bvid,
    required int cid,
    this.lrcPath = const Value.absent(),
    this.source = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.noLyrics = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bvid = Value(bvid),
       cid = Value(cid);
  static Insertable<LyricsCacheData> custom({
    Expression<String>? bvid,
    Expression<int>? cid,
    Expression<String>? lrcPath,
    Expression<String>? source,
    Expression<double>? matchScore,
    Expression<int>? offsetMs,
    Expression<bool>? noLyrics,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bvid != null) 'bvid': bvid,
      if (cid != null) 'cid': cid,
      if (lrcPath != null) 'lrc_path': lrcPath,
      if (source != null) 'source': source,
      if (matchScore != null) 'match_score': matchScore,
      if (offsetMs != null) 'offset_ms': offsetMs,
      if (noLyrics != null) 'no_lyrics': noLyrics,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LyricsCacheCompanion copyWith({
    Value<String>? bvid,
    Value<int>? cid,
    Value<String?>? lrcPath,
    Value<String?>? source,
    Value<double?>? matchScore,
    Value<int>? offsetMs,
    Value<bool>? noLyrics,
    Value<DateTime>? cachedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LyricsCacheCompanion(
      bvid: bvid ?? this.bvid,
      cid: cid ?? this.cid,
      lrcPath: lrcPath ?? this.lrcPath,
      source: source ?? this.source,
      matchScore: matchScore ?? this.matchScore,
      offsetMs: offsetMs ?? this.offsetMs,
      noLyrics: noLyrics ?? this.noLyrics,
      cachedAt: cachedAt ?? this.cachedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (cid.present) {
      map['cid'] = Variable<int>(cid.value);
    }
    if (lrcPath.present) {
      map['lrc_path'] = Variable<String>(lrcPath.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (matchScore.present) {
      map['match_score'] = Variable<double>(matchScore.value);
    }
    if (offsetMs.present) {
      map['offset_ms'] = Variable<int>(offsetMs.value);
    }
    if (noLyrics.present) {
      map['no_lyrics'] = Variable<bool>(noLyrics.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsCacheCompanion(')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('lrcPath: $lrcPath, ')
          ..write('source: $source, ')
          ..write('matchScore: $matchScore, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('noLyrics: $noLyrics, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheIndexTable extends CacheIndex
    with TableInfo<$CacheIndexTable, CacheIndexData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheIndexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    filePath,
    fileSize,
    complete,
    downloadedBytes,
    cachedAt,
    lastPlayedAt,
    pinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheIndexData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CacheIndexData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheIndexData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
    );
  }

  @override
  $CacheIndexTable createAlias(String alias) {
    return $CacheIndexTable(attachedDatabase, alias);
  }
}

class CacheIndexData extends DataClass implements Insertable<CacheIndexData> {
  final String cacheKey;
  final String filePath;
  final int fileSize;
  final bool complete;
  final int downloadedBytes;
  final DateTime cachedAt;
  final DateTime? lastPlayedAt;
  final bool pinned;
  const CacheIndexData({
    required this.cacheKey,
    required this.filePath,
    required this.fileSize,
    required this.complete,
    required this.downloadedBytes,
    required this.cachedAt,
    this.lastPlayedAt,
    required this.pinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['complete'] = Variable<bool>(complete);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['pinned'] = Variable<bool>(pinned);
    return map;
  }

  CacheIndexCompanion toCompanion(bool nullToAbsent) {
    return CacheIndexCompanion(
      cacheKey: Value(cacheKey),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      complete: Value(complete),
      downloadedBytes: Value(downloadedBytes),
      cachedAt: Value(cachedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      pinned: Value(pinned),
    );
  }

  factory CacheIndexData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheIndexData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      complete: serializer.fromJson<bool>(json['complete']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      pinned: serializer.fromJson<bool>(json['pinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'complete': serializer.toJson<bool>(complete),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'pinned': serializer.toJson<bool>(pinned),
    };
  }

  CacheIndexData copyWith({
    String? cacheKey,
    String? filePath,
    int? fileSize,
    bool? complete,
    int? downloadedBytes,
    DateTime? cachedAt,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    bool? pinned,
  }) => CacheIndexData(
    cacheKey: cacheKey ?? this.cacheKey,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    complete: complete ?? this.complete,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    cachedAt: cachedAt ?? this.cachedAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    pinned: pinned ?? this.pinned,
  );
  CacheIndexData copyWithCompanion(CacheIndexCompanion data) {
    return CacheIndexData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      complete: data.complete.present ? data.complete.value : this.complete,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheIndexData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('complete: $complete, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    filePath,
    fileSize,
    complete,
    downloadedBytes,
    cachedAt,
    lastPlayedAt,
    pinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheIndexData &&
          other.cacheKey == this.cacheKey &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.complete == this.complete &&
          other.downloadedBytes == this.downloadedBytes &&
          other.cachedAt == this.cachedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.pinned == this.pinned);
}

class CacheIndexCompanion extends UpdateCompanion<CacheIndexData> {
  final Value<String> cacheKey;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<bool> complete;
  final Value<int> downloadedBytes;
  final Value<DateTime> cachedAt;
  final Value<DateTime?> lastPlayedAt;
  final Value<bool> pinned;
  final Value<int> rowid;
  const CacheIndexCompanion({
    this.cacheKey = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.complete = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.pinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheIndexCompanion.insert({
    required String cacheKey,
    required String filePath,
    required int fileSize,
    this.complete = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.pinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       filePath = Value(filePath),
       fileSize = Value(fileSize);
  static Insertable<CacheIndexData> custom({
    Expression<String>? cacheKey,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<bool>? complete,
    Expression<int>? downloadedBytes,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<bool>? pinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (complete != null) 'complete': complete,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (pinned != null) 'pinned': pinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheIndexCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? filePath,
    Value<int>? fileSize,
    Value<bool>? complete,
    Value<int>? downloadedBytes,
    Value<DateTime>? cachedAt,
    Value<DateTime?>? lastPlayedAt,
    Value<bool>? pinned,
    Value<int>? rowid,
  }) {
    return CacheIndexCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      complete: complete ?? this.complete,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      cachedAt: cachedAt ?? this.cachedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      pinned: pinned ?? this.pinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheIndexCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('complete: $complete, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('pinned: $pinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreamUrlsTable extends StreamUrls
    with TableInfo<$StreamUrlsTable, StreamUrlRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreamUrlsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bvidMeta = const VerificationMeta('bvid');
  @override
  late final GeneratedColumn<String> bvid = GeneratedColumn<String>(
    'bvid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cidMeta = const VerificationMeta('cid');
  @override
  late final GeneratedColumn<int> cid = GeneratedColumn<int>(
    'cid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backupUrlsMeta = const VerificationMeta(
    'backupUrls',
  );
  @override
  late final GeneratedColumn<String> backupUrls = GeneratedColumn<String>(
    'backup_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bandwidthMeta = const VerificationMeta(
    'bandwidth',
  );
  @override
  late final GeneratedColumn<int> bandwidth = GeneratedColumn<int>(
    'bandwidth',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bvid,
    cid,
    quality,
    url,
    backupUrls,
    mime,
    bandwidth,
    expiresAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stream_urls';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreamUrlRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bvid')) {
      context.handle(
        _bvidMeta,
        bvid.isAcceptableOrUnknown(data['bvid']!, _bvidMeta),
      );
    } else if (isInserting) {
      context.missing(_bvidMeta);
    }
    if (data.containsKey('cid')) {
      context.handle(
        _cidMeta,
        cid.isAcceptableOrUnknown(data['cid']!, _cidMeta),
      );
    } else if (isInserting) {
      context.missing(_cidMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('backup_urls')) {
      context.handle(
        _backupUrlsMeta,
        backupUrls.isAcceptableOrUnknown(data['backup_urls']!, _backupUrlsMeta),
      );
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('bandwidth')) {
      context.handle(
        _bandwidthMeta,
        bandwidth.isAcceptableOrUnknown(data['bandwidth']!, _bandwidthMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bvid, cid, quality};
  @override
  StreamUrlRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreamUrlRow(
      bvid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bvid'],
      )!,
      cid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cid'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quality'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      backupUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_urls'],
      )!,
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      bandwidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bandwidth'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $StreamUrlsTable createAlias(String alias) {
    return $StreamUrlsTable(attachedDatabase, alias);
  }
}

class StreamUrlRow extends DataClass implements Insertable<StreamUrlRow> {
  final String bvid;
  final int cid;
  final int quality;
  final String url;
  final String backupUrls;
  final String mime;
  final int? bandwidth;
  final DateTime expiresAt;
  final DateTime cachedAt;
  const StreamUrlRow({
    required this.bvid,
    required this.cid,
    required this.quality,
    required this.url,
    required this.backupUrls,
    required this.mime,
    this.bandwidth,
    required this.expiresAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bvid'] = Variable<String>(bvid);
    map['cid'] = Variable<int>(cid);
    map['quality'] = Variable<int>(quality);
    map['url'] = Variable<String>(url);
    map['backup_urls'] = Variable<String>(backupUrls);
    map['mime'] = Variable<String>(mime);
    if (!nullToAbsent || bandwidth != null) {
      map['bandwidth'] = Variable<int>(bandwidth);
    }
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  StreamUrlsCompanion toCompanion(bool nullToAbsent) {
    return StreamUrlsCompanion(
      bvid: Value(bvid),
      cid: Value(cid),
      quality: Value(quality),
      url: Value(url),
      backupUrls: Value(backupUrls),
      mime: Value(mime),
      bandwidth: bandwidth == null && nullToAbsent
          ? const Value.absent()
          : Value(bandwidth),
      expiresAt: Value(expiresAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory StreamUrlRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreamUrlRow(
      bvid: serializer.fromJson<String>(json['bvid']),
      cid: serializer.fromJson<int>(json['cid']),
      quality: serializer.fromJson<int>(json['quality']),
      url: serializer.fromJson<String>(json['url']),
      backupUrls: serializer.fromJson<String>(json['backupUrls']),
      mime: serializer.fromJson<String>(json['mime']),
      bandwidth: serializer.fromJson<int?>(json['bandwidth']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bvid': serializer.toJson<String>(bvid),
      'cid': serializer.toJson<int>(cid),
      'quality': serializer.toJson<int>(quality),
      'url': serializer.toJson<String>(url),
      'backupUrls': serializer.toJson<String>(backupUrls),
      'mime': serializer.toJson<String>(mime),
      'bandwidth': serializer.toJson<int?>(bandwidth),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  StreamUrlRow copyWith({
    String? bvid,
    int? cid,
    int? quality,
    String? url,
    String? backupUrls,
    String? mime,
    Value<int?> bandwidth = const Value.absent(),
    DateTime? expiresAt,
    DateTime? cachedAt,
  }) => StreamUrlRow(
    bvid: bvid ?? this.bvid,
    cid: cid ?? this.cid,
    quality: quality ?? this.quality,
    url: url ?? this.url,
    backupUrls: backupUrls ?? this.backupUrls,
    mime: mime ?? this.mime,
    bandwidth: bandwidth.present ? bandwidth.value : this.bandwidth,
    expiresAt: expiresAt ?? this.expiresAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  StreamUrlRow copyWithCompanion(StreamUrlsCompanion data) {
    return StreamUrlRow(
      bvid: data.bvid.present ? data.bvid.value : this.bvid,
      cid: data.cid.present ? data.cid.value : this.cid,
      quality: data.quality.present ? data.quality.value : this.quality,
      url: data.url.present ? data.url.value : this.url,
      backupUrls: data.backupUrls.present
          ? data.backupUrls.value
          : this.backupUrls,
      mime: data.mime.present ? data.mime.value : this.mime,
      bandwidth: data.bandwidth.present ? data.bandwidth.value : this.bandwidth,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreamUrlRow(')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('quality: $quality, ')
          ..write('url: $url, ')
          ..write('backupUrls: $backupUrls, ')
          ..write('mime: $mime, ')
          ..write('bandwidth: $bandwidth, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bvid,
    cid,
    quality,
    url,
    backupUrls,
    mime,
    bandwidth,
    expiresAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreamUrlRow &&
          other.bvid == this.bvid &&
          other.cid == this.cid &&
          other.quality == this.quality &&
          other.url == this.url &&
          other.backupUrls == this.backupUrls &&
          other.mime == this.mime &&
          other.bandwidth == this.bandwidth &&
          other.expiresAt == this.expiresAt &&
          other.cachedAt == this.cachedAt);
}

class StreamUrlsCompanion extends UpdateCompanion<StreamUrlRow> {
  final Value<String> bvid;
  final Value<int> cid;
  final Value<int> quality;
  final Value<String> url;
  final Value<String> backupUrls;
  final Value<String> mime;
  final Value<int?> bandwidth;
  final Value<DateTime> expiresAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const StreamUrlsCompanion({
    this.bvid = const Value.absent(),
    this.cid = const Value.absent(),
    this.quality = const Value.absent(),
    this.url = const Value.absent(),
    this.backupUrls = const Value.absent(),
    this.mime = const Value.absent(),
    this.bandwidth = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreamUrlsCompanion.insert({
    required String bvid,
    required int cid,
    required int quality,
    required String url,
    this.backupUrls = const Value.absent(),
    required String mime,
    this.bandwidth = const Value.absent(),
    required DateTime expiresAt,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bvid = Value(bvid),
       cid = Value(cid),
       quality = Value(quality),
       url = Value(url),
       mime = Value(mime),
       expiresAt = Value(expiresAt);
  static Insertable<StreamUrlRow> custom({
    Expression<String>? bvid,
    Expression<int>? cid,
    Expression<int>? quality,
    Expression<String>? url,
    Expression<String>? backupUrls,
    Expression<String>? mime,
    Expression<int>? bandwidth,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bvid != null) 'bvid': bvid,
      if (cid != null) 'cid': cid,
      if (quality != null) 'quality': quality,
      if (url != null) 'url': url,
      if (backupUrls != null) 'backup_urls': backupUrls,
      if (mime != null) 'mime': mime,
      if (bandwidth != null) 'bandwidth': bandwidth,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreamUrlsCompanion copyWith({
    Value<String>? bvid,
    Value<int>? cid,
    Value<int>? quality,
    Value<String>? url,
    Value<String>? backupUrls,
    Value<String>? mime,
    Value<int?>? bandwidth,
    Value<DateTime>? expiresAt,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return StreamUrlsCompanion(
      bvid: bvid ?? this.bvid,
      cid: cid ?? this.cid,
      quality: quality ?? this.quality,
      url: url ?? this.url,
      backupUrls: backupUrls ?? this.backupUrls,
      mime: mime ?? this.mime,
      bandwidth: bandwidth ?? this.bandwidth,
      expiresAt: expiresAt ?? this.expiresAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bvid.present) {
      map['bvid'] = Variable<String>(bvid.value);
    }
    if (cid.present) {
      map['cid'] = Variable<int>(cid.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (backupUrls.present) {
      map['backup_urls'] = Variable<String>(backupUrls.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (bandwidth.present) {
      map['bandwidth'] = Variable<int>(bandwidth.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreamUrlsCompanion(')
          ..write('bvid: $bvid, ')
          ..write('cid: $cid, ')
          ..write('quality: $quality, ')
          ..write('url: $url, ')
          ..write('backupUrls: $backupUrls, ')
          ..write('mime: $mime, ')
          ..write('bandwidth: $bandwidth, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueSnapshotTable extends QueueSnapshot
    with TableInfo<$QueueSnapshotTable, QueueSnapshotData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueSnapshotTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _originalQueueMeta = const VerificationMeta(
    'originalQueue',
  );
  @override
  late final GeneratedColumn<String> originalQueue = GeneratedColumn<String>(
    'original_queue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentOrderMeta = const VerificationMeta(
    'currentOrder',
  );
  @override
  late final GeneratedColumn<String> currentOrder = GeneratedColumn<String>(
    'current_order',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _historyMeta = const VerificationMeta(
    'history',
  );
  @override
  late final GeneratedColumn<String> history = GeneratedColumn<String>(
    'history',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalQueue,
    currentOrder,
    cursor,
    mode,
    seed,
    history,
    positionMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_snapshot';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueSnapshotData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_queue')) {
      context.handle(
        _originalQueueMeta,
        originalQueue.isAcceptableOrUnknown(
          data['original_queue']!,
          _originalQueueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalQueueMeta);
    }
    if (data.containsKey('current_order')) {
      context.handle(
        _currentOrderMeta,
        currentOrder.isAcceptableOrUnknown(
          data['current_order']!,
          _currentOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentOrderMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
    }
    if (data.containsKey('history')) {
      context.handle(
        _historyMeta,
        history.isAcceptableOrUnknown(data['history']!, _historyMeta),
      );
    } else if (isInserting) {
      context.missing(_historyMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueSnapshotData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueSnapshotData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      originalQueue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_queue'],
      )!,
      currentOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_order'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
      history: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QueueSnapshotTable createAlias(String alias) {
    return $QueueSnapshotTable(attachedDatabase, alias);
  }
}

class QueueSnapshotData extends DataClass
    implements Insertable<QueueSnapshotData> {
  final int id;
  final String originalQueue;
  final String currentOrder;
  final int cursor;
  final String mode;
  final int seed;
  final String history;
  final int positionMs;
  final DateTime updatedAt;
  const QueueSnapshotData({
    required this.id,
    required this.originalQueue,
    required this.currentOrder,
    required this.cursor,
    required this.mode,
    required this.seed,
    required this.history,
    required this.positionMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['original_queue'] = Variable<String>(originalQueue);
    map['current_order'] = Variable<String>(currentOrder);
    map['cursor'] = Variable<int>(cursor);
    map['mode'] = Variable<String>(mode);
    map['seed'] = Variable<int>(seed);
    map['history'] = Variable<String>(history);
    map['position_ms'] = Variable<int>(positionMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QueueSnapshotCompanion toCompanion(bool nullToAbsent) {
    return QueueSnapshotCompanion(
      id: Value(id),
      originalQueue: Value(originalQueue),
      currentOrder: Value(currentOrder),
      cursor: Value(cursor),
      mode: Value(mode),
      seed: Value(seed),
      history: Value(history),
      positionMs: Value(positionMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory QueueSnapshotData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueSnapshotData(
      id: serializer.fromJson<int>(json['id']),
      originalQueue: serializer.fromJson<String>(json['originalQueue']),
      currentOrder: serializer.fromJson<String>(json['currentOrder']),
      cursor: serializer.fromJson<int>(json['cursor']),
      mode: serializer.fromJson<String>(json['mode']),
      seed: serializer.fromJson<int>(json['seed']),
      history: serializer.fromJson<String>(json['history']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalQueue': serializer.toJson<String>(originalQueue),
      'currentOrder': serializer.toJson<String>(currentOrder),
      'cursor': serializer.toJson<int>(cursor),
      'mode': serializer.toJson<String>(mode),
      'seed': serializer.toJson<int>(seed),
      'history': serializer.toJson<String>(history),
      'positionMs': serializer.toJson<int>(positionMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QueueSnapshotData copyWith({
    int? id,
    String? originalQueue,
    String? currentOrder,
    int? cursor,
    String? mode,
    int? seed,
    String? history,
    int? positionMs,
    DateTime? updatedAt,
  }) => QueueSnapshotData(
    id: id ?? this.id,
    originalQueue: originalQueue ?? this.originalQueue,
    currentOrder: currentOrder ?? this.currentOrder,
    cursor: cursor ?? this.cursor,
    mode: mode ?? this.mode,
    seed: seed ?? this.seed,
    history: history ?? this.history,
    positionMs: positionMs ?? this.positionMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QueueSnapshotData copyWithCompanion(QueueSnapshotCompanion data) {
    return QueueSnapshotData(
      id: data.id.present ? data.id.value : this.id,
      originalQueue: data.originalQueue.present
          ? data.originalQueue.value
          : this.originalQueue,
      currentOrder: data.currentOrder.present
          ? data.currentOrder.value
          : this.currentOrder,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      mode: data.mode.present ? data.mode.value : this.mode,
      seed: data.seed.present ? data.seed.value : this.seed,
      history: data.history.present ? data.history.value : this.history,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueSnapshotData(')
          ..write('id: $id, ')
          ..write('originalQueue: $originalQueue, ')
          ..write('currentOrder: $currentOrder, ')
          ..write('cursor: $cursor, ')
          ..write('mode: $mode, ')
          ..write('seed: $seed, ')
          ..write('history: $history, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalQueue,
    currentOrder,
    cursor,
    mode,
    seed,
    history,
    positionMs,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueSnapshotData &&
          other.id == this.id &&
          other.originalQueue == this.originalQueue &&
          other.currentOrder == this.currentOrder &&
          other.cursor == this.cursor &&
          other.mode == this.mode &&
          other.seed == this.seed &&
          other.history == this.history &&
          other.positionMs == this.positionMs &&
          other.updatedAt == this.updatedAt);
}

class QueueSnapshotCompanion extends UpdateCompanion<QueueSnapshotData> {
  final Value<int> id;
  final Value<String> originalQueue;
  final Value<String> currentOrder;
  final Value<int> cursor;
  final Value<String> mode;
  final Value<int> seed;
  final Value<String> history;
  final Value<int> positionMs;
  final Value<DateTime> updatedAt;
  const QueueSnapshotCompanion({
    this.id = const Value.absent(),
    this.originalQueue = const Value.absent(),
    this.currentOrder = const Value.absent(),
    this.cursor = const Value.absent(),
    this.mode = const Value.absent(),
    this.seed = const Value.absent(),
    this.history = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  QueueSnapshotCompanion.insert({
    this.id = const Value.absent(),
    required String originalQueue,
    required String currentOrder,
    required int cursor,
    required String mode,
    required int seed,
    required String history,
    this.positionMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : originalQueue = Value(originalQueue),
       currentOrder = Value(currentOrder),
       cursor = Value(cursor),
       mode = Value(mode),
       seed = Value(seed),
       history = Value(history);
  static Insertable<QueueSnapshotData> custom({
    Expression<int>? id,
    Expression<String>? originalQueue,
    Expression<String>? currentOrder,
    Expression<int>? cursor,
    Expression<String>? mode,
    Expression<int>? seed,
    Expression<String>? history,
    Expression<int>? positionMs,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalQueue != null) 'original_queue': originalQueue,
      if (currentOrder != null) 'current_order': currentOrder,
      if (cursor != null) 'cursor': cursor,
      if (mode != null) 'mode': mode,
      if (seed != null) 'seed': seed,
      if (history != null) 'history': history,
      if (positionMs != null) 'position_ms': positionMs,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  QueueSnapshotCompanion copyWith({
    Value<int>? id,
    Value<String>? originalQueue,
    Value<String>? currentOrder,
    Value<int>? cursor,
    Value<String>? mode,
    Value<int>? seed,
    Value<String>? history,
    Value<int>? positionMs,
    Value<DateTime>? updatedAt,
  }) {
    return QueueSnapshotCompanion(
      id: id ?? this.id,
      originalQueue: originalQueue ?? this.originalQueue,
      currentOrder: currentOrder ?? this.currentOrder,
      cursor: cursor ?? this.cursor,
      mode: mode ?? this.mode,
      seed: seed ?? this.seed,
      history: history ?? this.history,
      positionMs: positionMs ?? this.positionMs,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalQueue.present) {
      map['original_queue'] = Variable<String>(originalQueue.value);
    }
    if (currentOrder.present) {
      map['current_order'] = Variable<String>(currentOrder.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (history.present) {
      map['history'] = Variable<String>(history.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueSnapshotCompanion(')
          ..write('id: $id, ')
          ..write('originalQueue: $originalQueue, ')
          ..write('currentOrder: $currentOrder, ')
          ..write('cursor: $cursor, ')
          ..write('mode: $mode, ')
          ..write('seed: $seed, ')
          ..write('history: $history, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const Setting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      Setting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistTracksTable playlistTracks = $PlaylistTracksTable(this);
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final $LyricsCacheTable lyricsCache = $LyricsCacheTable(this);
  late final $CacheIndexTable cacheIndex = $CacheIndexTable(this);
  late final $StreamUrlsTable streamUrls = $StreamUrlsTable(this);
  late final $QueueSnapshotTable queueSnapshot = $QueueSnapshotTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final TracksDao tracksDao = TracksDao(this as AppDatabase);
  late final PlaylistsDao playlistsDao = PlaylistsDao(this as AppDatabase);
  late final CacheDao cacheDao = CacheDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final StreamUrlsDao streamUrlsDao = StreamUrlsDao(this as AppDatabase);
  late final HistoryDao historyDao = HistoryDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    playlists,
    playlistTracks,
    playHistory,
    lyricsCache,
    cacheIndex,
    streamUrls,
    queueSnapshot,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_tracks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TracksTableCreateCompanionBuilder =
    TracksCompanion Function({
      required String bvid,
      required int cid,
      required String title,
      Value<String?> cleanedName,
      Value<String?> artist,
      Value<bool> userEdited,
      required int duration,
      Value<String?> cover,
      Value<String?> uploader,
      Value<int?> pageIndex,
      Value<int?> totalPages,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TracksTableUpdateCompanionBuilder =
    TracksCompanion Function({
      Value<String> bvid,
      Value<int> cid,
      Value<String> title,
      Value<String?> cleanedName,
      Value<String?> artist,
      Value<bool> userEdited,
      Value<int> duration,
      Value<String?> cover,
      Value<String?> uploader,
      Value<int?> pageIndex,
      Value<int?> totalPages,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleanedName => $composableBuilder(
    column: $table.cleanedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleanedName => $composableBuilder(
    column: $table.cleanedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get cid =>
      $composableBuilder(column: $table.cid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get cleanedName => $composableBuilder(
    column: $table.cleanedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => column,
  );

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
          Track,
          PrefetchHooks Function()
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bvid = const Value.absent(),
                Value<int> cid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> cleanedName = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String?> uploader = const Value.absent(),
                Value<int?> pageIndex = const Value.absent(),
                Value<int?> totalPages = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion(
                bvid: bvid,
                cid: cid,
                title: title,
                cleanedName: cleanedName,
                artist: artist,
                userEdited: userEdited,
                duration: duration,
                cover: cover,
                uploader: uploader,
                pageIndex: pageIndex,
                totalPages: totalPages,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bvid,
                required int cid,
                required String title,
                Value<String?> cleanedName = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                required int duration,
                Value<String?> cover = const Value.absent(),
                Value<String?> uploader = const Value.absent(),
                Value<int?> pageIndex = const Value.absent(),
                Value<int?> totalPages = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion.insert(
                bvid: bvid,
                cid: cid,
                title: title,
                cleanedName: cleanedName,
                artist: artist,
                userEdited: userEdited,
                duration: duration,
                cover: cover,
                uploader: uploader,
                pageIndex: pageIndex,
                totalPages: totalPages,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, Track>(table),
                  BaseReferences<_$AppDatabase, $TracksTable, Track>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
      Track,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> cover,
      Value<bool> isReadonly,
      Value<String?> source,
      Value<String?> sourceId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PlaylistsTableUpdateCompanionBuilder =
    PlaylistsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> cover,
      Value<bool> isReadonly,
      Value<String?> source,
      Value<String?> sourceId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistTracksTable, List<PlaylistTrack>>
  _playlistTracksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistTracks,
    aliasName: 'playlists__id__playlist_tracks__playlist_id',
  );

  $$PlaylistTracksTableProcessedTableManager get playlistTracksRefs {
    final manager = $$PlaylistTracksTableTableManager(
      $_db,
      $_db.playlistTracks,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistTracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReadonly => $composableBuilder(
    column: $table.isReadonly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistTracksRefs(
    Expression<bool> Function($$PlaylistTracksTableFilterComposer f) f,
  ) {
    final $$PlaylistTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableFilterComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReadonly => $composableBuilder(
    column: $table.isReadonly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<bool> get isReadonly => $composableBuilder(
    column: $table.isReadonly,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> playlistTracksRefs<T extends Object>(
    Expression<T> Function($$PlaylistTracksTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({bool playlistTracksRefs})
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<bool> isReadonly = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                cover: cover,
                isReadonly: isReadonly,
                source: source,
                sourceId: sourceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> cover = const Value.absent(),
                Value<bool> isReadonly = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                cover: cover,
                isReadonly: isReadonly,
                source: source,
                sourceId: sourceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, Playlist>(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistTracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistTracksRefs) db.playlistTracks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistTracksRefs)
                    await $_getPrefetchedData<
                      Playlist,
                      $PlaylistsTable,
                      PlaylistTrack
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences
                          ._playlistTracksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistTracksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({bool playlistTracksRefs})
    >;
typedef $$PlaylistTracksTableCreateCompanionBuilder =
    PlaylistTracksCompanion Function({
      required int playlistId,
      required String bvid,
      required int cid,
      required int position,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$PlaylistTracksTableUpdateCompanionBuilder =
    PlaylistTracksCompanion Function({
      Value<int> playlistId,
      Value<String> bvid,
      Value<int> cid,
      Value<int> position,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$PlaylistTracksTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistTracksTable, PlaylistTrack> {
  $$PlaylistTracksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_tracks__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get cid =>
      $composableBuilder(column: $table.cid, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistTracksTable,
          PlaylistTrack,
          $$PlaylistTracksTableFilterComposer,
          $$PlaylistTracksTableOrderingComposer,
          $$PlaylistTracksTableAnnotationComposer,
          $$PlaylistTracksTableCreateCompanionBuilder,
          $$PlaylistTracksTableUpdateCompanionBuilder,
          (PlaylistTrack, $$PlaylistTracksTableReferences),
          PlaylistTrack,
          PrefetchHooks Function({bool playlistId})
        > {
  $$PlaylistTracksTableTableManager(
    _$AppDatabase db,
    $PlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playlistId = const Value.absent(),
                Value<String> bvid = const Value.absent(),
                Value<int> cid = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion(
                playlistId: playlistId,
                bvid: bvid,
                cid: cid,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playlistId,
                required String bvid,
                required int cid,
                required int position,
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion.insert(
                playlistId: playlistId,
                bvid: bvid,
                cid: cid,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistTracksTable, PlaylistTrack>(table),
                  $$PlaylistTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable: $$PlaylistTracksTableReferences
                                    ._playlistIdTable(db),
                                referencedColumn:
                                    $$PlaylistTracksTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistTracksTable,
      PlaylistTrack,
      $$PlaylistTracksTableFilterComposer,
      $$PlaylistTracksTableOrderingComposer,
      $$PlaylistTracksTableAnnotationComposer,
      $$PlaylistTracksTableCreateCompanionBuilder,
      $$PlaylistTracksTableUpdateCompanionBuilder,
      (PlaylistTrack, $$PlaylistTracksTableReferences),
      PlaylistTrack,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$PlayHistoryTableCreateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      required String bvid,
      required int cid,
      Value<DateTime> playedAt,
      Value<int> positionMs,
      Value<double> completion,
      Value<String?> source,
    });
typedef $$PlayHistoryTableUpdateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      Value<String> bvid,
      Value<int> cid,
      Value<DateTime> playedAt,
      Value<int> positionMs,
      Value<double> completion,
      Value<String?> source,
    });

class $$PlayHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completion => $composableBuilder(
    column: $table.completion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completion => $composableBuilder(
    column: $table.completion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get cid =>
      $composableBuilder(column: $table.cid, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get completion => $composableBuilder(
    column: $table.completion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$PlayHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayHistoryTable,
          PlayHistoryData,
          $$PlayHistoryTableFilterComposer,
          $$PlayHistoryTableOrderingComposer,
          $$PlayHistoryTableAnnotationComposer,
          $$PlayHistoryTableCreateCompanionBuilder,
          $$PlayHistoryTableUpdateCompanionBuilder,
          (
            PlayHistoryData,
            BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData>,
          ),
          PlayHistoryData,
          PrefetchHooks Function()
        > {
  $$PlayHistoryTableTableManager(_$AppDatabase db, $PlayHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bvid = const Value.absent(),
                Value<int> cid = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<double> completion = const Value.absent(),
                Value<String?> source = const Value.absent(),
              }) => PlayHistoryCompanion(
                id: id,
                bvid: bvid,
                cid: cid,
                playedAt: playedAt,
                positionMs: positionMs,
                completion: completion,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bvid,
                required int cid,
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<double> completion = const Value.absent(),
                Value<String?> source = const Value.absent(),
              }) => PlayHistoryCompanion.insert(
                id: id,
                bvid: bvid,
                cid: cid,
                playedAt: playedAt,
                positionMs: positionMs,
                completion: completion,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayHistoryTable, PlayHistoryData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlayHistoryTable,
                    PlayHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayHistoryTable,
      PlayHistoryData,
      $$PlayHistoryTableFilterComposer,
      $$PlayHistoryTableOrderingComposer,
      $$PlayHistoryTableAnnotationComposer,
      $$PlayHistoryTableCreateCompanionBuilder,
      $$PlayHistoryTableUpdateCompanionBuilder,
      (
        PlayHistoryData,
        BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData>,
      ),
      PlayHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LyricsCacheTableCreateCompanionBuilder =
    LyricsCacheCompanion Function({
      required String bvid,
      required int cid,
      Value<String?> lrcPath,
      Value<String?> source,
      Value<double?> matchScore,
      Value<int> offsetMs,
      Value<bool> noLyrics,
      Value<DateTime> cachedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LyricsCacheTableUpdateCompanionBuilder =
    LyricsCacheCompanion Function({
      Value<String> bvid,
      Value<int> cid,
      Value<String?> lrcPath,
      Value<String?> source,
      Value<double?> matchScore,
      Value<int> offsetMs,
      Value<bool> noLyrics,
      Value<DateTime> cachedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LyricsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $LyricsCacheTable> {
  $$LyricsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lrcPath => $composableBuilder(
    column: $table.lrcPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get matchScore => $composableBuilder(
    column: $table.matchScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get noLyrics => $composableBuilder(
    column: $table.noLyrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LyricsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $LyricsCacheTable> {
  $$LyricsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lrcPath => $composableBuilder(
    column: $table.lrcPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get matchScore => $composableBuilder(
    column: $table.matchScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMs => $composableBuilder(
    column: $table.offsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get noLyrics => $composableBuilder(
    column: $table.noLyrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LyricsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $LyricsCacheTable> {
  $$LyricsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get cid =>
      $composableBuilder(column: $table.cid, builder: (column) => column);

  GeneratedColumn<String> get lrcPath =>
      $composableBuilder(column: $table.lrcPath, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get matchScore => $composableBuilder(
    column: $table.matchScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetMs =>
      $composableBuilder(column: $table.offsetMs, builder: (column) => column);

  GeneratedColumn<bool> get noLyrics =>
      $composableBuilder(column: $table.noLyrics, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LyricsCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LyricsCacheTable,
          LyricsCacheData,
          $$LyricsCacheTableFilterComposer,
          $$LyricsCacheTableOrderingComposer,
          $$LyricsCacheTableAnnotationComposer,
          $$LyricsCacheTableCreateCompanionBuilder,
          $$LyricsCacheTableUpdateCompanionBuilder,
          (
            LyricsCacheData,
            BaseReferences<_$AppDatabase, $LyricsCacheTable, LyricsCacheData>,
          ),
          LyricsCacheData,
          PrefetchHooks Function()
        > {
  $$LyricsCacheTableTableManager(_$AppDatabase db, $LyricsCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LyricsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LyricsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LyricsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bvid = const Value.absent(),
                Value<int> cid = const Value.absent(),
                Value<String?> lrcPath = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<double?> matchScore = const Value.absent(),
                Value<int> offsetMs = const Value.absent(),
                Value<bool> noLyrics = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LyricsCacheCompanion(
                bvid: bvid,
                cid: cid,
                lrcPath: lrcPath,
                source: source,
                matchScore: matchScore,
                offsetMs: offsetMs,
                noLyrics: noLyrics,
                cachedAt: cachedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bvid,
                required int cid,
                Value<String?> lrcPath = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<double?> matchScore = const Value.absent(),
                Value<int> offsetMs = const Value.absent(),
                Value<bool> noLyrics = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LyricsCacheCompanion.insert(
                bvid: bvid,
                cid: cid,
                lrcPath: lrcPath,
                source: source,
                matchScore: matchScore,
                offsetMs: offsetMs,
                noLyrics: noLyrics,
                cachedAt: cachedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LyricsCacheTable, LyricsCacheData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LyricsCacheTable,
                    LyricsCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LyricsCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LyricsCacheTable,
      LyricsCacheData,
      $$LyricsCacheTableFilterComposer,
      $$LyricsCacheTableOrderingComposer,
      $$LyricsCacheTableAnnotationComposer,
      $$LyricsCacheTableCreateCompanionBuilder,
      $$LyricsCacheTableUpdateCompanionBuilder,
      (
        LyricsCacheData,
        BaseReferences<_$AppDatabase, $LyricsCacheTable, LyricsCacheData>,
      ),
      LyricsCacheData,
      PrefetchHooks Function()
    >;
typedef $$CacheIndexTableCreateCompanionBuilder =
    CacheIndexCompanion Function({
      required String cacheKey,
      required String filePath,
      required int fileSize,
      Value<bool> complete,
      Value<int> downloadedBytes,
      Value<DateTime> cachedAt,
      Value<DateTime?> lastPlayedAt,
      Value<bool> pinned,
      Value<int> rowid,
    });
typedef $$CacheIndexTableUpdateCompanionBuilder =
    CacheIndexCompanion Function({
      Value<String> cacheKey,
      Value<String> filePath,
      Value<int> fileSize,
      Value<bool> complete,
      Value<int> downloadedBytes,
      Value<DateTime> cachedAt,
      Value<DateTime?> lastPlayedAt,
      Value<bool> pinned,
      Value<int> rowid,
    });

class $$CacheIndexTableFilterComposer
    extends Composer<_$AppDatabase, $CacheIndexTable> {
  $$CacheIndexTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheIndexTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheIndexTable> {
  $$CacheIndexTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheIndexTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheIndexTable> {
  $$CacheIndexTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);
}

class $$CacheIndexTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheIndexTable,
          CacheIndexData,
          $$CacheIndexTableFilterComposer,
          $$CacheIndexTableOrderingComposer,
          $$CacheIndexTableAnnotationComposer,
          $$CacheIndexTableCreateCompanionBuilder,
          $$CacheIndexTableUpdateCompanionBuilder,
          (
            CacheIndexData,
            BaseReferences<_$AppDatabase, $CacheIndexTable, CacheIndexData>,
          ),
          CacheIndexData,
          PrefetchHooks Function()
        > {
  $$CacheIndexTableTableManager(_$AppDatabase db, $CacheIndexTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheIndexTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheIndexTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheIndexTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheIndexCompanion(
                cacheKey: cacheKey,
                filePath: filePath,
                fileSize: fileSize,
                complete: complete,
                downloadedBytes: downloadedBytes,
                cachedAt: cachedAt,
                lastPlayedAt: lastPlayedAt,
                pinned: pinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String filePath,
                required int fileSize,
                Value<bool> complete = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheIndexCompanion.insert(
                cacheKey: cacheKey,
                filePath: filePath,
                fileSize: fileSize,
                complete: complete,
                downloadedBytes: downloadedBytes,
                cachedAt: cachedAt,
                lastPlayedAt: lastPlayedAt,
                pinned: pinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CacheIndexTable, CacheIndexData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CacheIndexTable,
                    CacheIndexData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheIndexTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheIndexTable,
      CacheIndexData,
      $$CacheIndexTableFilterComposer,
      $$CacheIndexTableOrderingComposer,
      $$CacheIndexTableAnnotationComposer,
      $$CacheIndexTableCreateCompanionBuilder,
      $$CacheIndexTableUpdateCompanionBuilder,
      (
        CacheIndexData,
        BaseReferences<_$AppDatabase, $CacheIndexTable, CacheIndexData>,
      ),
      CacheIndexData,
      PrefetchHooks Function()
    >;
typedef $$StreamUrlsTableCreateCompanionBuilder =
    StreamUrlsCompanion Function({
      required String bvid,
      required int cid,
      required int quality,
      required String url,
      Value<String> backupUrls,
      required String mime,
      Value<int?> bandwidth,
      required DateTime expiresAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$StreamUrlsTableUpdateCompanionBuilder =
    StreamUrlsCompanion Function({
      Value<String> bvid,
      Value<int> cid,
      Value<int> quality,
      Value<String> url,
      Value<String> backupUrls,
      Value<String> mime,
      Value<int?> bandwidth,
      Value<DateTime> expiresAt,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$StreamUrlsTableFilterComposer
    extends Composer<_$AppDatabase, $StreamUrlsTable> {
  $$StreamUrlsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupUrls => $composableBuilder(
    column: $table.backupUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bandwidth => $composableBuilder(
    column: $table.bandwidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreamUrlsTableOrderingComposer
    extends Composer<_$AppDatabase, $StreamUrlsTable> {
  $$StreamUrlsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bvid => $composableBuilder(
    column: $table.bvid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupUrls => $composableBuilder(
    column: $table.backupUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bandwidth => $composableBuilder(
    column: $table.bandwidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreamUrlsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreamUrlsTable> {
  $$StreamUrlsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bvid =>
      $composableBuilder(column: $table.bvid, builder: (column) => column);

  GeneratedColumn<int> get cid =>
      $composableBuilder(column: $table.cid, builder: (column) => column);

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get backupUrls => $composableBuilder(
    column: $table.backupUrls,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<int> get bandwidth =>
      $composableBuilder(column: $table.bandwidth, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$StreamUrlsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StreamUrlsTable,
          StreamUrlRow,
          $$StreamUrlsTableFilterComposer,
          $$StreamUrlsTableOrderingComposer,
          $$StreamUrlsTableAnnotationComposer,
          $$StreamUrlsTableCreateCompanionBuilder,
          $$StreamUrlsTableUpdateCompanionBuilder,
          (
            StreamUrlRow,
            BaseReferences<_$AppDatabase, $StreamUrlsTable, StreamUrlRow>,
          ),
          StreamUrlRow,
          PrefetchHooks Function()
        > {
  $$StreamUrlsTableTableManager(_$AppDatabase db, $StreamUrlsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreamUrlsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreamUrlsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreamUrlsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bvid = const Value.absent(),
                Value<int> cid = const Value.absent(),
                Value<int> quality = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> backupUrls = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<int?> bandwidth = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreamUrlsCompanion(
                bvid: bvid,
                cid: cid,
                quality: quality,
                url: url,
                backupUrls: backupUrls,
                mime: mime,
                bandwidth: bandwidth,
                expiresAt: expiresAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bvid,
                required int cid,
                required int quality,
                required String url,
                Value<String> backupUrls = const Value.absent(),
                required String mime,
                Value<int?> bandwidth = const Value.absent(),
                required DateTime expiresAt,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreamUrlsCompanion.insert(
                bvid: bvid,
                cid: cid,
                quality: quality,
                url: url,
                backupUrls: backupUrls,
                mime: mime,
                bandwidth: bandwidth,
                expiresAt: expiresAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StreamUrlsTable, StreamUrlRow>(table),
                  BaseReferences<_$AppDatabase, $StreamUrlsTable, StreamUrlRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreamUrlsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StreamUrlsTable,
      StreamUrlRow,
      $$StreamUrlsTableFilterComposer,
      $$StreamUrlsTableOrderingComposer,
      $$StreamUrlsTableAnnotationComposer,
      $$StreamUrlsTableCreateCompanionBuilder,
      $$StreamUrlsTableUpdateCompanionBuilder,
      (
        StreamUrlRow,
        BaseReferences<_$AppDatabase, $StreamUrlsTable, StreamUrlRow>,
      ),
      StreamUrlRow,
      PrefetchHooks Function()
    >;
typedef $$QueueSnapshotTableCreateCompanionBuilder =
    QueueSnapshotCompanion Function({
      Value<int> id,
      required String originalQueue,
      required String currentOrder,
      required int cursor,
      required String mode,
      required int seed,
      required String history,
      Value<int> positionMs,
      Value<DateTime> updatedAt,
    });
typedef $$QueueSnapshotTableUpdateCompanionBuilder =
    QueueSnapshotCompanion Function({
      Value<int> id,
      Value<String> originalQueue,
      Value<String> currentOrder,
      Value<int> cursor,
      Value<String> mode,
      Value<int> seed,
      Value<String> history,
      Value<int> positionMs,
      Value<DateTime> updatedAt,
    });

class $$QueueSnapshotTableFilterComposer
    extends Composer<_$AppDatabase, $QueueSnapshotTable> {
  $$QueueSnapshotTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalQueue => $composableBuilder(
    column: $table.originalQueue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentOrder => $composableBuilder(
    column: $table.currentOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get history => $composableBuilder(
    column: $table.history,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueSnapshotTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueSnapshotTable> {
  $$QueueSnapshotTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalQueue => $composableBuilder(
    column: $table.originalQueue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentOrder => $composableBuilder(
    column: $table.currentOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get history => $composableBuilder(
    column: $table.history,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueSnapshotTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueSnapshotTable> {
  $$QueueSnapshotTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalQueue => $composableBuilder(
    column: $table.originalQueue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentOrder => $composableBuilder(
    column: $table.currentOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<String> get history =>
      $composableBuilder(column: $table.history, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QueueSnapshotTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueSnapshotTable,
          QueueSnapshotData,
          $$QueueSnapshotTableFilterComposer,
          $$QueueSnapshotTableOrderingComposer,
          $$QueueSnapshotTableAnnotationComposer,
          $$QueueSnapshotTableCreateCompanionBuilder,
          $$QueueSnapshotTableUpdateCompanionBuilder,
          (
            QueueSnapshotData,
            BaseReferences<
              _$AppDatabase,
              $QueueSnapshotTable,
              QueueSnapshotData
            >,
          ),
          QueueSnapshotData,
          PrefetchHooks Function()
        > {
  $$QueueSnapshotTableTableManager(_$AppDatabase db, $QueueSnapshotTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueSnapshotTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueSnapshotTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueSnapshotTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> originalQueue = const Value.absent(),
                Value<String> currentOrder = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> seed = const Value.absent(),
                Value<String> history = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => QueueSnapshotCompanion(
                id: id,
                originalQueue: originalQueue,
                currentOrder: currentOrder,
                cursor: cursor,
                mode: mode,
                seed: seed,
                history: history,
                positionMs: positionMs,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String originalQueue,
                required String currentOrder,
                required int cursor,
                required String mode,
                required int seed,
                required String history,
                Value<int> positionMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => QueueSnapshotCompanion.insert(
                id: id,
                originalQueue: originalQueue,
                currentOrder: currentOrder,
                cursor: cursor,
                mode: mode,
                seed: seed,
                history: history,
                positionMs: positionMs,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueueSnapshotTable, QueueSnapshotData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $QueueSnapshotTable,
                    QueueSnapshotData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueSnapshotTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueSnapshotTable,
      QueueSnapshotData,
      $$QueueSnapshotTableFilterComposer,
      $$QueueSnapshotTableOrderingComposer,
      $$QueueSnapshotTableAnnotationComposer,
      $$QueueSnapshotTableCreateCompanionBuilder,
      $$QueueSnapshotTableUpdateCompanionBuilder,
      (
        QueueSnapshotData,
        BaseReferences<_$AppDatabase, $QueueSnapshotTable, QueueSnapshotData>,
      ),
      QueueSnapshotData,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(_db, _db.playlistTracks);
  $$PlayHistoryTableTableManager get playHistory =>
      $$PlayHistoryTableTableManager(_db, _db.playHistory);
  $$LyricsCacheTableTableManager get lyricsCache =>
      $$LyricsCacheTableTableManager(_db, _db.lyricsCache);
  $$CacheIndexTableTableManager get cacheIndex =>
      $$CacheIndexTableTableManager(_db, _db.cacheIndex);
  $$StreamUrlsTableTableManager get streamUrls =>
      $$StreamUrlsTableTableManager(_db, _db.streamUrls);
  $$QueueSnapshotTableTableManager get queueSnapshot =>
      $$QueueSnapshotTableTableManager(_db, _db.queueSnapshot);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
