// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ServerProfilesTable extends ServerProfiles
    with TableInfo<$ServerProfilesTable, ServerProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<String> serverVersion = GeneratedColumn<String>(
    'server_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowPrivateHttpMeta = const VerificationMeta(
    'allowPrivateHttp',
  );
  @override
  late final GeneratedColumn<bool> allowPrivateHttp = GeneratedColumn<bool>(
    'allow_private_http',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_private_http" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baseUrl,
    name,
    userId,
    username,
    deviceId,
    serverVersion,
    allowPrivateHttp,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'server_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServerProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serverVersionMeta);
    }
    if (data.containsKey('allow_private_http')) {
      context.handle(
        _allowPrivateHttpMeta,
        allowPrivateHttp.isAcceptableOrUnknown(
          data['allow_private_http']!,
          _allowPrivateHttpMeta,
        ),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_version'],
      )!,
      allowPrivateHttp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_private_http'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $ServerProfilesTable createAlias(String alias) {
    return $ServerProfilesTable(attachedDatabase, alias);
  }
}

class ServerProfile extends DataClass implements Insertable<ServerProfile> {
  final String id;
  final String baseUrl;
  final String name;
  final String userId;
  final String username;
  final String deviceId;
  final String serverVersion;
  final bool allowPrivateHttp;
  final DateTime lastUsedAt;
  const ServerProfile({
    required this.id,
    required this.baseUrl,
    required this.name,
    required this.userId,
    required this.username,
    required this.deviceId,
    required this.serverVersion,
    required this.allowPrivateHttp,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['base_url'] = Variable<String>(baseUrl);
    map['name'] = Variable<String>(name);
    map['user_id'] = Variable<String>(userId);
    map['username'] = Variable<String>(username);
    map['device_id'] = Variable<String>(deviceId);
    map['server_version'] = Variable<String>(serverVersion);
    map['allow_private_http'] = Variable<bool>(allowPrivateHttp);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  ServerProfilesCompanion toCompanion(bool nullToAbsent) {
    return ServerProfilesCompanion(
      id: Value(id),
      baseUrl: Value(baseUrl),
      name: Value(name),
      userId: Value(userId),
      username: Value(username),
      deviceId: Value(deviceId),
      serverVersion: Value(serverVersion),
      allowPrivateHttp: Value(allowPrivateHttp),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory ServerProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerProfile(
      id: serializer.fromJson<String>(json['id']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      name: serializer.fromJson<String>(json['name']),
      userId: serializer.fromJson<String>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      serverVersion: serializer.fromJson<String>(json['serverVersion']),
      allowPrivateHttp: serializer.fromJson<bool>(json['allowPrivateHttp']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'name': serializer.toJson<String>(name),
      'userId': serializer.toJson<String>(userId),
      'username': serializer.toJson<String>(username),
      'deviceId': serializer.toJson<String>(deviceId),
      'serverVersion': serializer.toJson<String>(serverVersion),
      'allowPrivateHttp': serializer.toJson<bool>(allowPrivateHttp),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  ServerProfile copyWith({
    String? id,
    String? baseUrl,
    String? name,
    String? userId,
    String? username,
    String? deviceId,
    String? serverVersion,
    bool? allowPrivateHttp,
    DateTime? lastUsedAt,
  }) => ServerProfile(
    id: id ?? this.id,
    baseUrl: baseUrl ?? this.baseUrl,
    name: name ?? this.name,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    deviceId: deviceId ?? this.deviceId,
    serverVersion: serverVersion ?? this.serverVersion,
    allowPrivateHttp: allowPrivateHttp ?? this.allowPrivateHttp,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  ServerProfile copyWithCompanion(ServerProfilesCompanion data) {
    return ServerProfile(
      id: data.id.present ? data.id.value : this.id,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      allowPrivateHttp: data.allowPrivateHttp.present
          ? data.allowPrivateHttp.value
          : this.allowPrivateHttp,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerProfile(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('allowPrivateHttp: $allowPrivateHttp, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseUrl,
    name,
    userId,
    username,
    deviceId,
    serverVersion,
    allowPrivateHttp,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerProfile &&
          other.id == this.id &&
          other.baseUrl == this.baseUrl &&
          other.name == this.name &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.deviceId == this.deviceId &&
          other.serverVersion == this.serverVersion &&
          other.allowPrivateHttp == this.allowPrivateHttp &&
          other.lastUsedAt == this.lastUsedAt);
}

class ServerProfilesCompanion extends UpdateCompanion<ServerProfile> {
  final Value<String> id;
  final Value<String> baseUrl;
  final Value<String> name;
  final Value<String> userId;
  final Value<String> username;
  final Value<String> deviceId;
  final Value<String> serverVersion;
  final Value<bool> allowPrivateHttp;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const ServerProfilesCompanion({
    this.id = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.allowPrivateHttp = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServerProfilesCompanion.insert({
    required String id,
    required String baseUrl,
    required String name,
    required String userId,
    required String username,
    required String deviceId,
    required String serverVersion,
    this.allowPrivateHttp = const Value.absent(),
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       baseUrl = Value(baseUrl),
       name = Value(name),
       userId = Value(userId),
       username = Value(username),
       deviceId = Value(deviceId),
       serverVersion = Value(serverVersion),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<ServerProfile> custom({
    Expression<String>? id,
    Expression<String>? baseUrl,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<String>? username,
    Expression<String>? deviceId,
    Expression<String>? serverVersion,
    Expression<bool>? allowPrivateHttp,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseUrl != null) 'base_url': baseUrl,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (deviceId != null) 'device_id': deviceId,
      if (serverVersion != null) 'server_version': serverVersion,
      if (allowPrivateHttp != null) 'allow_private_http': allowPrivateHttp,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServerProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? baseUrl,
    Value<String>? name,
    Value<String>? userId,
    Value<String>? username,
    Value<String>? deviceId,
    Value<String>? serverVersion,
    Value<bool>? allowPrivateHttp,
    Value<DateTime>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return ServerProfilesCompanion(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      deviceId: deviceId ?? this.deviceId,
      serverVersion: serverVersion ?? this.serverVersion,
      allowPrivateHttp: allowPrivateHttp ?? this.allowPrivateHttp,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<String>(serverVersion.value);
    }
    if (allowPrivateHttp.present) {
      map['allow_private_http'] = Variable<bool>(allowPrivateHttp.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServerProfilesCompanion(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('deviceId: $deviceId, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('allowPrivateHttp: $allowPrivateHttp, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedItemsTable extends CachedItems
    with TableInfo<$CachedItemsTable, CachedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _indexNumberMeta = const VerificationMeta(
    'indexNumber',
  );
  @override
  late final GeneratedColumn<int> indexNumber = GeneratedColumn<int>(
    'index_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productionYearMeta = const VerificationMeta(
    'productionYear',
  );
  @override
  late final GeneratedColumn<int> productionYear = GeneratedColumn<int>(
    'production_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDownloadedMeta = const VerificationMeta(
    'isDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
    'is_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _containerMeta = const VerificationMeta(
    'container',
  );
  @override
  late final GeneratedColumn<String> container = GeneratedColumn<String>(
    'container',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    serverId,
    itemId,
    itemType,
    name,
    subtitle,
    albumId,
    artistId,
    imageUrl,
    durationMs,
    indexNumber,
    productionYear,
    isFavorite,
    isDownloaded,
    container,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('index_number')) {
      context.handle(
        _indexNumberMeta,
        indexNumber.isAcceptableOrUnknown(
          data['index_number']!,
          _indexNumberMeta,
        ),
      );
    }
    if (data.containsKey('production_year')) {
      context.handle(
        _productionYearMeta,
        productionYear.isAcceptableOrUnknown(
          data['production_year']!,
          _productionYearMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
        _isDownloadedMeta,
        isDownloaded.isAcceptableOrUnknown(
          data['is_downloaded']!,
          _isDownloadedMeta,
        ),
      );
    }
    if (data.containsKey('container')) {
      context.handle(
        _containerMeta,
        container.isAcceptableOrUnknown(data['container']!, _containerMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, itemId};
  @override
  CachedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedItem(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      indexNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}index_number'],
      ),
      productionYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}production_year'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_downloaded'],
      )!,
      container: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedItemsTable createAlias(String alias) {
    return $CachedItemsTable(attachedDatabase, alias);
  }
}

class CachedItem extends DataClass implements Insertable<CachedItem> {
  final String serverId;
  final String itemId;
  final String itemType;
  final String name;
  final String? subtitle;
  final String? albumId;
  final String? artistId;
  final String? imageUrl;
  final int durationMs;
  final int? indexNumber;
  final int? productionYear;
  final bool isFavorite;
  final bool isDownloaded;
  final String? container;
  final DateTime updatedAt;
  const CachedItem({
    required this.serverId,
    required this.itemId,
    required this.itemType,
    required this.name,
    this.subtitle,
    this.albumId,
    this.artistId,
    this.imageUrl,
    required this.durationMs,
    this.indexNumber,
    this.productionYear,
    required this.isFavorite,
    required this.isDownloaded,
    this.container,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    map['item_id'] = Variable<String>(itemId);
    map['item_type'] = Variable<String>(itemType);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<String>(artistId);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || indexNumber != null) {
      map['index_number'] = Variable<int>(indexNumber);
    }
    if (!nullToAbsent || productionYear != null) {
      map['production_year'] = Variable<int>(productionYear);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    if (!nullToAbsent || container != null) {
      map['container'] = Variable<String>(container);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedItemsCompanion(
      serverId: Value(serverId),
      itemId: Value(itemId),
      itemType: Value(itemType),
      name: Value(name),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      durationMs: Value(durationMs),
      indexNumber: indexNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(indexNumber),
      productionYear: productionYear == null && nullToAbsent
          ? const Value.absent()
          : Value(productionYear),
      isFavorite: Value(isFavorite),
      isDownloaded: Value(isDownloaded),
      container: container == null && nullToAbsent
          ? const Value.absent()
          : Value(container),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedItem(
      serverId: serializer.fromJson<String>(json['serverId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      name: serializer.fromJson<String>(json['name']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      artistId: serializer.fromJson<String?>(json['artistId']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      indexNumber: serializer.fromJson<int?>(json['indexNumber']),
      productionYear: serializer.fromJson<int?>(json['productionYear']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      container: serializer.fromJson<String?>(json['container']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<String>(itemType),
      'name': serializer.toJson<String>(name),
      'subtitle': serializer.toJson<String?>(subtitle),
      'albumId': serializer.toJson<String?>(albumId),
      'artistId': serializer.toJson<String?>(artistId),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'durationMs': serializer.toJson<int>(durationMs),
      'indexNumber': serializer.toJson<int?>(indexNumber),
      'productionYear': serializer.toJson<int?>(productionYear),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'container': serializer.toJson<String?>(container),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedItem copyWith({
    String? serverId,
    String? itemId,
    String? itemType,
    String? name,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> albumId = const Value.absent(),
    Value<String?> artistId = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    int? durationMs,
    Value<int?> indexNumber = const Value.absent(),
    Value<int?> productionYear = const Value.absent(),
    bool? isFavorite,
    bool? isDownloaded,
    Value<String?> container = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedItem(
    serverId: serverId ?? this.serverId,
    itemId: itemId ?? this.itemId,
    itemType: itemType ?? this.itemType,
    name: name ?? this.name,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    albumId: albumId.present ? albumId.value : this.albumId,
    artistId: artistId.present ? artistId.value : this.artistId,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    durationMs: durationMs ?? this.durationMs,
    indexNumber: indexNumber.present ? indexNumber.value : this.indexNumber,
    productionYear: productionYear.present
        ? productionYear.value
        : this.productionYear,
    isFavorite: isFavorite ?? this.isFavorite,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    container: container.present ? container.value : this.container,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedItem copyWithCompanion(CachedItemsCompanion data) {
    return CachedItem(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      name: data.name.present ? data.name.value : this.name,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      indexNumber: data.indexNumber.present
          ? data.indexNumber.value
          : this.indexNumber,
      productionYear: data.productionYear.present
          ? data.productionYear.value
          : this.productionYear,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      container: data.container.present ? data.container.value : this.container,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedItem(')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('name: $name, ')
          ..write('subtitle: $subtitle, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('durationMs: $durationMs, ')
          ..write('indexNumber: $indexNumber, ')
          ..write('productionYear: $productionYear, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('container: $container, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serverId,
    itemId,
    itemType,
    name,
    subtitle,
    albumId,
    artistId,
    imageUrl,
    durationMs,
    indexNumber,
    productionYear,
    isFavorite,
    isDownloaded,
    container,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedItem &&
          other.serverId == this.serverId &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.name == this.name &&
          other.subtitle == this.subtitle &&
          other.albumId == this.albumId &&
          other.artistId == this.artistId &&
          other.imageUrl == this.imageUrl &&
          other.durationMs == this.durationMs &&
          other.indexNumber == this.indexNumber &&
          other.productionYear == this.productionYear &&
          other.isFavorite == this.isFavorite &&
          other.isDownloaded == this.isDownloaded &&
          other.container == this.container &&
          other.updatedAt == this.updatedAt);
}

class CachedItemsCompanion extends UpdateCompanion<CachedItem> {
  final Value<String> serverId;
  final Value<String> itemId;
  final Value<String> itemType;
  final Value<String> name;
  final Value<String?> subtitle;
  final Value<String?> albumId;
  final Value<String?> artistId;
  final Value<String?> imageUrl;
  final Value<int> durationMs;
  final Value<int?> indexNumber;
  final Value<int?> productionYear;
  final Value<bool> isFavorite;
  final Value<bool> isDownloaded;
  final Value<String?> container;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedItemsCompanion({
    this.serverId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.name = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.indexNumber = const Value.absent(),
    this.productionYear = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.container = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedItemsCompanion.insert({
    required String serverId,
    required String itemId,
    required String itemType,
    required String name,
    this.subtitle = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.indexNumber = const Value.absent(),
    this.productionYear = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.container = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       itemId = Value(itemId),
       itemType = Value(itemType),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<CachedItem> custom({
    Expression<String>? serverId,
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<String>? name,
    Expression<String>? subtitle,
    Expression<String>? albumId,
    Expression<String>? artistId,
    Expression<String>? imageUrl,
    Expression<int>? durationMs,
    Expression<int>? indexNumber,
    Expression<int>? productionYear,
    Expression<bool>? isFavorite,
    Expression<bool>? isDownloaded,
    Expression<String>? container,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (name != null) 'name': name,
      if (subtitle != null) 'subtitle': subtitle,
      if (albumId != null) 'album_id': albumId,
      if (artistId != null) 'artist_id': artistId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (durationMs != null) 'duration_ms': durationMs,
      if (indexNumber != null) 'index_number': indexNumber,
      if (productionYear != null) 'production_year': productionYear,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (container != null) 'container': container,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedItemsCompanion copyWith({
    Value<String>? serverId,
    Value<String>? itemId,
    Value<String>? itemType,
    Value<String>? name,
    Value<String?>? subtitle,
    Value<String?>? albumId,
    Value<String?>? artistId,
    Value<String?>? imageUrl,
    Value<int>? durationMs,
    Value<int?>? indexNumber,
    Value<int?>? productionYear,
    Value<bool>? isFavorite,
    Value<bool>? isDownloaded,
    Value<String?>? container,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedItemsCompanion(
      serverId: serverId ?? this.serverId,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      imageUrl: imageUrl ?? this.imageUrl,
      durationMs: durationMs ?? this.durationMs,
      indexNumber: indexNumber ?? this.indexNumber,
      productionYear: productionYear ?? this.productionYear,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      container: container ?? this.container,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (indexNumber.present) {
      map['index_number'] = Variable<int>(indexNumber.value);
    }
    if (productionYear.present) {
      map['production_year'] = Variable<int>(productionYear.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (container.present) {
      map['container'] = Variable<String>(container.value);
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
    return (StringBuffer('CachedItemsCompanion(')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('name: $name, ')
          ..write('subtitle: $subtitle, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('durationMs: $durationMs, ')
          ..write('indexNumber: $indexNumber, ')
          ..write('productionYear: $productionYear, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('container: $container, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadEntriesTable extends DownloadEntries
    with TableInfo<$DownloadEntriesTable, DownloadEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    itemId,
    status,
    filePath,
    progress,
    sizeBytes,
    checksum,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DownloadEntriesTable createAlias(String alias) {
    return $DownloadEntriesTable(attachedDatabase, alias);
  }
}

class DownloadEntry extends DataClass implements Insertable<DownloadEntry> {
  final String id;
  final String serverId;
  final String itemId;
  final String status;
  final String? filePath;
  final double progress;
  final int sizeBytes;
  final String? checksum;
  final DateTime updatedAt;
  const DownloadEntry({
    required this.id,
    required this.serverId,
    required this.itemId,
    required this.status,
    this.filePath,
    required this.progress,
    required this.sizeBytes,
    this.checksum,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server_id'] = Variable<String>(serverId);
    map['item_id'] = Variable<String>(itemId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['progress'] = Variable<double>(progress);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DownloadEntriesCompanion toCompanion(bool nullToAbsent) {
    return DownloadEntriesCompanion(
      id: Value(id),
      serverId: Value(serverId),
      itemId: Value(itemId),
      status: Value(status),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      progress: Value(progress),
      sizeBytes: Value(sizeBytes),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadEntry(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      status: serializer.fromJson<String>(json['status']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      progress: serializer.fromJson<double>(json['progress']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String>(serverId),
      'itemId': serializer.toJson<String>(itemId),
      'status': serializer.toJson<String>(status),
      'filePath': serializer.toJson<String?>(filePath),
      'progress': serializer.toJson<double>(progress),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'checksum': serializer.toJson<String?>(checksum),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DownloadEntry copyWith({
    String? id,
    String? serverId,
    String? itemId,
    String? status,
    Value<String?> filePath = const Value.absent(),
    double? progress,
    int? sizeBytes,
    Value<String?> checksum = const Value.absent(),
    DateTime? updatedAt,
  }) => DownloadEntry(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    itemId: itemId ?? this.itemId,
    status: status ?? this.status,
    filePath: filePath.present ? filePath.value : this.filePath,
    progress: progress ?? this.progress,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    checksum: checksum.present ? checksum.value : this.checksum,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DownloadEntry copyWithCompanion(DownloadEntriesCompanion data) {
    return DownloadEntry(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      status: data.status.present ? data.status.value : this.status,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      progress: data.progress.present ? data.progress.value : this.progress,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadEntry(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('progress: $progress, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    itemId,
    status,
    filePath,
    progress,
    sizeBytes,
    checksum,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadEntry &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.itemId == this.itemId &&
          other.status == this.status &&
          other.filePath == this.filePath &&
          other.progress == this.progress &&
          other.sizeBytes == this.sizeBytes &&
          other.checksum == this.checksum &&
          other.updatedAt == this.updatedAt);
}

class DownloadEntriesCompanion extends UpdateCompanion<DownloadEntry> {
  final Value<String> id;
  final Value<String> serverId;
  final Value<String> itemId;
  final Value<String> status;
  final Value<String?> filePath;
  final Value<double> progress;
  final Value<int> sizeBytes;
  final Value<String?> checksum;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DownloadEntriesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.progress = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.checksum = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadEntriesCompanion.insert({
    required String id,
    required String serverId,
    required String itemId,
    required String status,
    this.filePath = const Value.absent(),
    this.progress = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.checksum = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serverId = Value(serverId),
       itemId = Value(itemId),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<DownloadEntry> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? itemId,
    Expression<String>? status,
    Expression<String>? filePath,
    Expression<double>? progress,
    Expression<int>? sizeBytes,
    Expression<String>? checksum,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (itemId != null) 'item_id': itemId,
      if (status != null) 'status': status,
      if (filePath != null) 'file_path': filePath,
      if (progress != null) 'progress': progress,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (checksum != null) 'checksum': checksum,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? serverId,
    Value<String>? itemId,
    Value<String>? status,
    Value<String?>? filePath,
    Value<double>? progress,
    Value<int>? sizeBytes,
    Value<String?>? checksum,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DownloadEntriesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      itemId: itemId ?? this.itemId,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum ?? this.checksum,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
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
    return (StringBuffer('DownloadEntriesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('progress: $progress, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('checksum: $checksum, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueEntriesTable extends QueueEntries
    with TableInfo<$QueueEntriesTable, QueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queueIndexMeta = const VerificationMeta(
    'queueIndex',
  );
  @override
  late final GeneratedColumn<int> queueIndex = GeneratedColumn<int>(
    'queue_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    serverId,
    queueIndex,
    itemId,
    isCurrent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('queue_index')) {
      context.handle(
        _queueIndexMeta,
        queueIndex.isAcceptableOrUnknown(data['queue_index']!, _queueIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_queueIndexMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, queueIndex};
  @override
  QueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueEntry(
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      queueIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queue_index'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
    );
  }

  @override
  $QueueEntriesTable createAlias(String alias) {
    return $QueueEntriesTable(attachedDatabase, alias);
  }
}

class QueueEntry extends DataClass implements Insertable<QueueEntry> {
  final String serverId;
  final int queueIndex;
  final String itemId;
  final bool isCurrent;
  const QueueEntry({
    required this.serverId,
    required this.queueIndex,
    required this.itemId,
    required this.isCurrent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    map['queue_index'] = Variable<int>(queueIndex);
    map['item_id'] = Variable<String>(itemId);
    map['is_current'] = Variable<bool>(isCurrent);
    return map;
  }

  QueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return QueueEntriesCompanion(
      serverId: Value(serverId),
      queueIndex: Value(queueIndex),
      itemId: Value(itemId),
      isCurrent: Value(isCurrent),
    );
  }

  factory QueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueEntry(
      serverId: serializer.fromJson<String>(json['serverId']),
      queueIndex: serializer.fromJson<int>(json['queueIndex']),
      itemId: serializer.fromJson<String>(json['itemId']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'queueIndex': serializer.toJson<int>(queueIndex),
      'itemId': serializer.toJson<String>(itemId),
      'isCurrent': serializer.toJson<bool>(isCurrent),
    };
  }

  QueueEntry copyWith({
    String? serverId,
    int? queueIndex,
    String? itemId,
    bool? isCurrent,
  }) => QueueEntry(
    serverId: serverId ?? this.serverId,
    queueIndex: queueIndex ?? this.queueIndex,
    itemId: itemId ?? this.itemId,
    isCurrent: isCurrent ?? this.isCurrent,
  );
  QueueEntry copyWithCompanion(QueueEntriesCompanion data) {
    return QueueEntry(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      queueIndex: data.queueIndex.present
          ? data.queueIndex.value
          : this.queueIndex,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntry(')
          ..write('serverId: $serverId, ')
          ..write('queueIndex: $queueIndex, ')
          ..write('itemId: $itemId, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, queueIndex, itemId, isCurrent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueEntry &&
          other.serverId == this.serverId &&
          other.queueIndex == this.queueIndex &&
          other.itemId == this.itemId &&
          other.isCurrent == this.isCurrent);
}

class QueueEntriesCompanion extends UpdateCompanion<QueueEntry> {
  final Value<String> serverId;
  final Value<int> queueIndex;
  final Value<String> itemId;
  final Value<bool> isCurrent;
  final Value<int> rowid;
  const QueueEntriesCompanion({
    this.serverId = const Value.absent(),
    this.queueIndex = const Value.absent(),
    this.itemId = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueueEntriesCompanion.insert({
    required String serverId,
    required int queueIndex,
    required String itemId,
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId),
       queueIndex = Value(queueIndex),
       itemId = Value(itemId);
  static Insertable<QueueEntry> custom({
    Expression<String>? serverId,
    Expression<int>? queueIndex,
    Expression<String>? itemId,
    Expression<bool>? isCurrent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (queueIndex != null) 'queue_index': queueIndex,
      if (itemId != null) 'item_id': itemId,
      if (isCurrent != null) 'is_current': isCurrent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueueEntriesCompanion copyWith({
    Value<String>? serverId,
    Value<int>? queueIndex,
    Value<String>? itemId,
    Value<bool>? isCurrent,
    Value<int>? rowid,
  }) {
    return QueueEntriesCompanion(
      serverId: serverId ?? this.serverId,
      queueIndex: queueIndex ?? this.queueIndex,
      itemId: itemId ?? this.itemId,
      isCurrent: isCurrent ?? this.isCurrent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (queueIndex.present) {
      map['queue_index'] = Variable<int>(queueIndex.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntriesCompanion(')
          ..write('serverId: $serverId, ')
          ..write('queueIndex: $queueIndex, ')
          ..write('itemId: $itemId, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingReportsTable extends PendingReports
    with TableInfo<$PendingReportsTable, PendingReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingReportsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    itemId,
    eventType,
    positionMs,
    payloadJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingReportsTable createAlias(String alias) {
    return $PendingReportsTable(attachedDatabase, alias);
  }
}

class PendingReport extends DataClass implements Insertable<PendingReport> {
  final int id;
  final String serverId;
  final String itemId;
  final String eventType;
  final int positionMs;
  final String payloadJson;
  final DateTime createdAt;
  const PendingReport({
    required this.id,
    required this.serverId,
    required this.itemId,
    required this.eventType,
    required this.positionMs,
    required this.payloadJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['item_id'] = Variable<String>(itemId);
    map['event_type'] = Variable<String>(eventType);
    map['position_ms'] = Variable<int>(positionMs);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingReportsCompanion toCompanion(bool nullToAbsent) {
    return PendingReportsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      itemId: Value(itemId),
      eventType: Value(eventType),
      positionMs: Value(positionMs),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
    );
  }

  factory PendingReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingReport(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'itemId': serializer.toJson<String>(itemId),
      'eventType': serializer.toJson<String>(eventType),
      'positionMs': serializer.toJson<int>(positionMs),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingReport copyWith({
    int? id,
    String? serverId,
    String? itemId,
    String? eventType,
    int? positionMs,
    String? payloadJson,
    DateTime? createdAt,
  }) => PendingReport(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    itemId: itemId ?? this.itemId,
    eventType: eventType ?? this.eventType,
    positionMs: positionMs ?? this.positionMs,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingReport copyWithCompanion(PendingReportsCompanion data) {
    return PendingReport(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingReport(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('eventType: $eventType, ')
          ..write('positionMs: $positionMs, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    itemId,
    eventType,
    positionMs,
    payloadJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingReport &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.itemId == this.itemId &&
          other.eventType == this.eventType &&
          other.positionMs == this.positionMs &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt);
}

class PendingReportsCompanion extends UpdateCompanion<PendingReport> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> itemId;
  final Value<String> eventType;
  final Value<int> positionMs;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  const PendingReportsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingReportsCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String itemId,
    required String eventType,
    required int positionMs,
    required String payloadJson,
    required DateTime createdAt,
  }) : serverId = Value(serverId),
       itemId = Value(itemId),
       eventType = Value(eventType),
       positionMs = Value(positionMs),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingReport> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? itemId,
    Expression<String>? eventType,
    Expression<int>? positionMs,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (itemId != null) 'item_id': itemId,
      if (eventType != null) 'event_type': eventType,
      if (positionMs != null) 'position_ms': positionMs,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingReportsCompanion copyWith({
    Value<int>? id,
    Value<String>? serverId,
    Value<String>? itemId,
    Value<String>? eventType,
    Value<int>? positionMs,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
  }) {
    return PendingReportsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      itemId: itemId ?? this.itemId,
      eventType: eventType ?? this.eventType,
      positionMs: positionMs ?? this.positionMs,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingReportsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('eventType: $eventType, ')
          ..write('positionMs: $positionMs, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ServerProfilesTable serverProfiles = $ServerProfilesTable(this);
  late final $CachedItemsTable cachedItems = $CachedItemsTable(this);
  late final $DownloadEntriesTable downloadEntries = $DownloadEntriesTable(
    this,
  );
  late final $QueueEntriesTable queueEntries = $QueueEntriesTable(this);
  late final $PendingReportsTable pendingReports = $PendingReportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    serverProfiles,
    cachedItems,
    downloadEntries,
    queueEntries,
    pendingReports,
  ];
}

typedef $$ServerProfilesTableCreateCompanionBuilder =
    ServerProfilesCompanion Function({
      required String id,
      required String baseUrl,
      required String name,
      required String userId,
      required String username,
      required String deviceId,
      required String serverVersion,
      Value<bool> allowPrivateHttp,
      required DateTime lastUsedAt,
      Value<int> rowid,
    });
typedef $$ServerProfilesTableUpdateCompanionBuilder =
    ServerProfilesCompanion Function({
      Value<String> id,
      Value<String> baseUrl,
      Value<String> name,
      Value<String> userId,
      Value<String> username,
      Value<String> deviceId,
      Value<String> serverVersion,
      Value<bool> allowPrivateHttp,
      Value<DateTime> lastUsedAt,
      Value<int> rowid,
    });

class $$ServerProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ServerProfilesTable> {
  $$ServerProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowPrivateHttp => $composableBuilder(
    column: $table.allowPrivateHttp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ServerProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ServerProfilesTable> {
  $$ServerProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowPrivateHttp => $composableBuilder(
    column: $table.allowPrivateHttp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServerProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServerProfilesTable> {
  $$ServerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowPrivateHttp => $composableBuilder(
    column: $table.allowPrivateHttp,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$ServerProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServerProfilesTable,
          ServerProfile,
          $$ServerProfilesTableFilterComposer,
          $$ServerProfilesTableOrderingComposer,
          $$ServerProfilesTableAnnotationComposer,
          $$ServerProfilesTableCreateCompanionBuilder,
          $$ServerProfilesTableUpdateCompanionBuilder,
          (
            ServerProfile,
            BaseReferences<_$AppDatabase, $ServerProfilesTable, ServerProfile>,
          ),
          ServerProfile,
          PrefetchHooks Function()
        > {
  $$ServerProfilesTableTableManager(
    _$AppDatabase db,
    $ServerProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> serverVersion = const Value.absent(),
                Value<bool> allowPrivateHttp = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServerProfilesCompanion(
                id: id,
                baseUrl: baseUrl,
                name: name,
                userId: userId,
                username: username,
                deviceId: deviceId,
                serverVersion: serverVersion,
                allowPrivateHttp: allowPrivateHttp,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String baseUrl,
                required String name,
                required String userId,
                required String username,
                required String deviceId,
                required String serverVersion,
                Value<bool> allowPrivateHttp = const Value.absent(),
                required DateTime lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => ServerProfilesCompanion.insert(
                id: id,
                baseUrl: baseUrl,
                name: name,
                userId: userId,
                username: username,
                deviceId: deviceId,
                serverVersion: serverVersion,
                allowPrivateHttp: allowPrivateHttp,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ServerProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServerProfilesTable,
      ServerProfile,
      $$ServerProfilesTableFilterComposer,
      $$ServerProfilesTableOrderingComposer,
      $$ServerProfilesTableAnnotationComposer,
      $$ServerProfilesTableCreateCompanionBuilder,
      $$ServerProfilesTableUpdateCompanionBuilder,
      (
        ServerProfile,
        BaseReferences<_$AppDatabase, $ServerProfilesTable, ServerProfile>,
      ),
      ServerProfile,
      PrefetchHooks Function()
    >;
typedef $$CachedItemsTableCreateCompanionBuilder =
    CachedItemsCompanion Function({
      required String serverId,
      required String itemId,
      required String itemType,
      required String name,
      Value<String?> subtitle,
      Value<String?> albumId,
      Value<String?> artistId,
      Value<String?> imageUrl,
      Value<int> durationMs,
      Value<int?> indexNumber,
      Value<int?> productionYear,
      Value<bool> isFavorite,
      Value<bool> isDownloaded,
      Value<String?> container,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedItemsTableUpdateCompanionBuilder =
    CachedItemsCompanion Function({
      Value<String> serverId,
      Value<String> itemId,
      Value<String> itemType,
      Value<String> name,
      Value<String?> subtitle,
      Value<String?> albumId,
      Value<String?> artistId,
      Value<String?> imageUrl,
      Value<int> durationMs,
      Value<int?> indexNumber,
      Value<int?> productionYear,
      Value<bool> isFavorite,
      Value<bool> isDownloaded,
      Value<String?> container,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexNumber => $composableBuilder(
    column: $table.indexNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productionYear => $composableBuilder(
    column: $table.productionYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get container => $composableBuilder(
    column: $table.container,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexNumber => $composableBuilder(
    column: $table.indexNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productionYear => $composableBuilder(
    column: $table.productionYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get container => $composableBuilder(
    column: $table.container,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedItemsTable> {
  $$CachedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get indexNumber => $composableBuilder(
    column: $table.indexNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get productionYear => $composableBuilder(
    column: $table.productionYear,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get container =>
      $composableBuilder(column: $table.container, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedItemsTable,
          CachedItem,
          $$CachedItemsTableFilterComposer,
          $$CachedItemsTableOrderingComposer,
          $$CachedItemsTableAnnotationComposer,
          $$CachedItemsTableCreateCompanionBuilder,
          $$CachedItemsTableUpdateCompanionBuilder,
          (
            CachedItem,
            BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem>,
          ),
          CachedItem,
          PrefetchHooks Function()
        > {
  $$CachedItemsTableTableManager(_$AppDatabase db, $CachedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> serverId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> artistId = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> indexNumber = const Value.absent(),
                Value<int?> productionYear = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<String?> container = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion(
                serverId: serverId,
                itemId: itemId,
                itemType: itemType,
                name: name,
                subtitle: subtitle,
                albumId: albumId,
                artistId: artistId,
                imageUrl: imageUrl,
                durationMs: durationMs,
                indexNumber: indexNumber,
                productionYear: productionYear,
                isFavorite: isFavorite,
                isDownloaded: isDownloaded,
                container: container,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String serverId,
                required String itemId,
                required String itemType,
                required String name,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> artistId = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> indexNumber = const Value.absent(),
                Value<int?> productionYear = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<String?> container = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedItemsCompanion.insert(
                serverId: serverId,
                itemId: itemId,
                itemType: itemType,
                name: name,
                subtitle: subtitle,
                albumId: albumId,
                artistId: artistId,
                imageUrl: imageUrl,
                durationMs: durationMs,
                indexNumber: indexNumber,
                productionYear: productionYear,
                isFavorite: isFavorite,
                isDownloaded: isDownloaded,
                container: container,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedItemsTable,
      CachedItem,
      $$CachedItemsTableFilterComposer,
      $$CachedItemsTableOrderingComposer,
      $$CachedItemsTableAnnotationComposer,
      $$CachedItemsTableCreateCompanionBuilder,
      $$CachedItemsTableUpdateCompanionBuilder,
      (
        CachedItem,
        BaseReferences<_$AppDatabase, $CachedItemsTable, CachedItem>,
      ),
      CachedItem,
      PrefetchHooks Function()
    >;
typedef $$DownloadEntriesTableCreateCompanionBuilder =
    DownloadEntriesCompanion Function({
      required String id,
      required String serverId,
      required String itemId,
      required String status,
      Value<String?> filePath,
      Value<double> progress,
      Value<int> sizeBytes,
      Value<String?> checksum,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DownloadEntriesTableUpdateCompanionBuilder =
    DownloadEntriesCompanion Function({
      Value<String> id,
      Value<String> serverId,
      Value<String> itemId,
      Value<String> status,
      Value<String?> filePath,
      Value<double> progress,
      Value<int> sizeBytes,
      Value<String?> checksum,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DownloadEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DownloadEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadEntriesTable,
          DownloadEntry,
          $$DownloadEntriesTableFilterComposer,
          $$DownloadEntriesTableOrderingComposer,
          $$DownloadEntriesTableAnnotationComposer,
          $$DownloadEntriesTableCreateCompanionBuilder,
          $$DownloadEntriesTableUpdateCompanionBuilder,
          (
            DownloadEntry,
            BaseReferences<_$AppDatabase, $DownloadEntriesTable, DownloadEntry>,
          ),
          DownloadEntry,
          PrefetchHooks Function()
        > {
  $$DownloadEntriesTableTableManager(
    _$AppDatabase db,
    $DownloadEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadEntriesCompanion(
                id: id,
                serverId: serverId,
                itemId: itemId,
                status: status,
                filePath: filePath,
                progress: progress,
                sizeBytes: sizeBytes,
                checksum: checksum,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serverId,
                required String itemId,
                required String status,
                Value<String?> filePath = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadEntriesCompanion.insert(
                id: id,
                serverId: serverId,
                itemId: itemId,
                status: status,
                filePath: filePath,
                progress: progress,
                sizeBytes: sizeBytes,
                checksum: checksum,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadEntriesTable,
      DownloadEntry,
      $$DownloadEntriesTableFilterComposer,
      $$DownloadEntriesTableOrderingComposer,
      $$DownloadEntriesTableAnnotationComposer,
      $$DownloadEntriesTableCreateCompanionBuilder,
      $$DownloadEntriesTableUpdateCompanionBuilder,
      (
        DownloadEntry,
        BaseReferences<_$AppDatabase, $DownloadEntriesTable, DownloadEntry>,
      ),
      DownloadEntry,
      PrefetchHooks Function()
    >;
typedef $$QueueEntriesTableCreateCompanionBuilder =
    QueueEntriesCompanion Function({
      required String serverId,
      required int queueIndex,
      required String itemId,
      Value<bool> isCurrent,
      Value<int> rowid,
    });
typedef $$QueueEntriesTableUpdateCompanionBuilder =
    QueueEntriesCompanion Function({
      Value<String> serverId,
      Value<int> queueIndex,
      Value<String> itemId,
      Value<bool> isCurrent,
      Value<int> rowid,
    });

class $$QueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queueIndex => $composableBuilder(
    column: $table.queueIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queueIndex => $composableBuilder(
    column: $table.queueIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get queueIndex => $composableBuilder(
    column: $table.queueIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);
}

class $$QueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueEntriesTable,
          QueueEntry,
          $$QueueEntriesTableFilterComposer,
          $$QueueEntriesTableOrderingComposer,
          $$QueueEntriesTableAnnotationComposer,
          $$QueueEntriesTableCreateCompanionBuilder,
          $$QueueEntriesTableUpdateCompanionBuilder,
          (
            QueueEntry,
            BaseReferences<_$AppDatabase, $QueueEntriesTable, QueueEntry>,
          ),
          QueueEntry,
          PrefetchHooks Function()
        > {
  $$QueueEntriesTableTableManager(_$AppDatabase db, $QueueEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> serverId = const Value.absent(),
                Value<int> queueIndex = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueEntriesCompanion(
                serverId: serverId,
                queueIndex: queueIndex,
                itemId: itemId,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String serverId,
                required int queueIndex,
                required String itemId,
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueEntriesCompanion.insert(
                serverId: serverId,
                queueIndex: queueIndex,
                itemId: itemId,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueEntriesTable,
      QueueEntry,
      $$QueueEntriesTableFilterComposer,
      $$QueueEntriesTableOrderingComposer,
      $$QueueEntriesTableAnnotationComposer,
      $$QueueEntriesTableCreateCompanionBuilder,
      $$QueueEntriesTableUpdateCompanionBuilder,
      (
        QueueEntry,
        BaseReferences<_$AppDatabase, $QueueEntriesTable, QueueEntry>,
      ),
      QueueEntry,
      PrefetchHooks Function()
    >;
typedef $$PendingReportsTableCreateCompanionBuilder =
    PendingReportsCompanion Function({
      Value<int> id,
      required String serverId,
      required String itemId,
      required String eventType,
      required int positionMs,
      required String payloadJson,
      required DateTime createdAt,
    });
typedef $$PendingReportsTableUpdateCompanionBuilder =
    PendingReportsCompanion Function({
      Value<int> id,
      Value<String> serverId,
      Value<String> itemId,
      Value<String> eventType,
      Value<int> positionMs,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
    });

class $$PendingReportsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingReportsTable> {
  $$PendingReportsTableFilterComposer({
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

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingReportsTable> {
  $$PendingReportsTableOrderingComposer({
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

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingReportsTable> {
  $$PendingReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingReportsTable,
          PendingReport,
          $$PendingReportsTableFilterComposer,
          $$PendingReportsTableOrderingComposer,
          $$PendingReportsTableAnnotationComposer,
          $$PendingReportsTableCreateCompanionBuilder,
          $$PendingReportsTableUpdateCompanionBuilder,
          (
            PendingReport,
            BaseReferences<_$AppDatabase, $PendingReportsTable, PendingReport>,
          ),
          PendingReport,
          PrefetchHooks Function()
        > {
  $$PendingReportsTableTableManager(
    _$AppDatabase db,
    $PendingReportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingReportsCompanion(
                id: id,
                serverId: serverId,
                itemId: itemId,
                eventType: eventType,
                positionMs: positionMs,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverId,
                required String itemId,
                required String eventType,
                required int positionMs,
                required String payloadJson,
                required DateTime createdAt,
              }) => PendingReportsCompanion.insert(
                id: id,
                serverId: serverId,
                itemId: itemId,
                eventType: eventType,
                positionMs: positionMs,
                payloadJson: payloadJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingReportsTable,
      PendingReport,
      $$PendingReportsTableFilterComposer,
      $$PendingReportsTableOrderingComposer,
      $$PendingReportsTableAnnotationComposer,
      $$PendingReportsTableCreateCompanionBuilder,
      $$PendingReportsTableUpdateCompanionBuilder,
      (
        PendingReport,
        BaseReferences<_$AppDatabase, $PendingReportsTable, PendingReport>,
      ),
      PendingReport,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ServerProfilesTableTableManager get serverProfiles =>
      $$ServerProfilesTableTableManager(_db, _db.serverProfiles);
  $$CachedItemsTableTableManager get cachedItems =>
      $$CachedItemsTableTableManager(_db, _db.cachedItems);
  $$DownloadEntriesTableTableManager get downloadEntries =>
      $$DownloadEntriesTableTableManager(_db, _db.downloadEntries);
  $$QueueEntriesTableTableManager get queueEntries =>
      $$QueueEntriesTableTableManager(_db, _db.queueEntries);
  $$PendingReportsTableTableManager get pendingReports =>
      $$PendingReportsTableTableManager(_db, _db.pendingReports);
}
