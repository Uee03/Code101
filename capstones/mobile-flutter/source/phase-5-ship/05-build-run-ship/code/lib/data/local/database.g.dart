// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class Teams extends Table with TableInfo<Teams, Team> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Teams(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    memberCount,
    version,
    updatedAt,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<Team> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Team map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Team(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  Teams createAlias(String alias) {
    return Teams(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Team extends DataClass implements Insertable<Team> {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int version;
  final String updatedAt;
  final String payloadJson;
  const Team({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.version,
    required this.updatedAt,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['member_count'] = Variable<int>(memberCount);
    map['version'] = Variable<int>(version);
    map['updated_at'] = Variable<String>(updatedAt);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      memberCount: Value(memberCount),
      version: Value(version),
      updatedAt: Value(updatedAt),
      payloadJson: Value(payloadJson),
    );
  }

  factory Team.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Team(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      memberCount: serializer.fromJson<int>(json['member_count']),
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
      payloadJson: serializer.fromJson<String>(json['payload_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'member_count': serializer.toJson<int>(memberCount),
      'version': serializer.toJson<int>(version),
      'updated_at': serializer.toJson<String>(updatedAt),
      'payload_json': serializer.toJson<String>(payloadJson),
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? description,
    int? memberCount,
    int? version,
    String? updatedAt,
    String? payloadJson,
  }) => Team(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    memberCount: memberCount ?? this.memberCount,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  Team copyWithCompanion(TeamsCompanion data) {
    return Team(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Team(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('memberCount: $memberCount, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    memberCount,
    version,
    updatedAt,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Team &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.memberCount == this.memberCount &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt &&
          other.payloadJson == this.payloadJson);
}

class TeamsCompanion extends UpdateCompanion<Team> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<int> memberCount;
  final Value<int> version;
  final Value<String> updatedAt;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String id,
    required String name,
    required String description,
    this.memberCount = const Value.absent(),
    required int version,
    required String updatedAt,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       version = Value(version),
       updatedAt = Value(updatedAt),
       payloadJson = Value(payloadJson);
  static Insertable<Team> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? memberCount,
    Expression<int>? version,
    Expression<String>? updatedAt,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (memberCount != null) 'member_count': memberCount,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<int>? memberCount,
    Value<int>? version,
    Value<String>? updatedAt,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return TeamsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('memberCount: $memberCount, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Projects extends Table with TableInfo<Projects, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Projects(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  late final GeneratedColumn<int> archived = GeneratedColumn<int>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    key,
    name,
    description,
    archived,
    version,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  Projects createAlias(String alias) {
    return Projects(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String teamId;
  final String key;
  final String name;
  final String description;
  final int archived;
  final int version;
  final String payloadJson;
  const Project({
    required this.id,
    required this.teamId,
    required this.key,
    required this.name,
    required this.description,
    required this.archived,
    required this.version,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_id'] = Variable<String>(teamId);
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['archived'] = Variable<int>(archived);
    map['version'] = Variable<int>(version);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      teamId: Value(teamId),
      key: Value(key),
      name: Value(name),
      description: Value(description),
      archived: Value(archived),
      version: Value(version),
      payloadJson: Value(payloadJson),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      teamId: serializer.fromJson<String>(json['team_id']),
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      archived: serializer.fromJson<int>(json['archived']),
      version: serializer.fromJson<int>(json['version']),
      payloadJson: serializer.fromJson<String>(json['payload_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'team_id': serializer.toJson<String>(teamId),
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'archived': serializer.toJson<int>(archived),
      'version': serializer.toJson<int>(version),
      'payload_json': serializer.toJson<String>(payloadJson),
    };
  }

  Project copyWith({
    String? id,
    String? teamId,
    String? key,
    String? name,
    String? description,
    int? archived,
    int? version,
    String? payloadJson,
  }) => Project(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    key: key ?? this.key,
    name: name ?? this.name,
    description: description ?? this.description,
    archived: archived ?? this.archived,
    version: version ?? this.version,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      archived: data.archived.present ? data.archived.value : this.archived,
      version: data.version.present ? data.version.value : this.version,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('archived: $archived, ')
          ..write('version: $version, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teamId,
    key,
    name,
    description,
    archived,
    version,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.key == this.key &&
          other.name == this.name &&
          other.description == this.description &&
          other.archived == this.archived &&
          other.version == this.version &&
          other.payloadJson == this.payloadJson);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> teamId;
  final Value<String> key;
  final Value<String> name;
  final Value<String> description;
  final Value<int> archived;
  final Value<int> version;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.archived = const Value.absent(),
    this.version = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String teamId,
    required String key,
    required String name,
    required String description,
    this.archived = const Value.absent(),
    required int version,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teamId = Value(teamId),
       key = Value(key),
       name = Value(name),
       description = Value(description),
       version = Value(version),
       payloadJson = Value(payloadJson);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? teamId,
    Expression<String>? key,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? archived,
    Expression<int>? version,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (archived != null) 'archived': archived,
      if (version != null) 'version': version,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? teamId,
    Value<String>? key,
    Value<String>? name,
    Value<String>? description,
    Value<int>? archived,
    Value<int>? version,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      archived: archived ?? this.archived,
      version: version ?? this.version,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (archived.present) {
      map['archived'] = Variable<int>(archived.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('archived: $archived, ')
          ..write('version: $version, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tasks extends Table with TableInfo<Tasks, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tasks(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _assigneeIdMeta = const VerificationMeta(
    'assigneeId',
  );
  late final GeneratedColumn<String> assigneeId = GeneratedColumn<String>(
    'assignee_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sync_state IN (\'synced\', \'pending\', \'conflict\', \'failed\'))',
  );
  static const VerificationMeta _serverJsonMeta = const VerificationMeta(
    'serverJson',
  );
  late final GeneratedColumn<String> serverJson = GeneratedColumn<String>(
    'server_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    description,
    status,
    priority,
    assigneeId,
    dueDate,
    completedAt,
    version,
    createdAt,
    syncState,
    serverJson,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('assignee_id')) {
      context.handle(
        _assigneeIdMeta,
        assigneeId.isAcceptableOrUnknown(data['assignee_id']!, _assigneeIdMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('server_json')) {
      context.handle(
        _serverJsonMeta,
        serverJson.isAcceptableOrUnknown(data['server_json']!, _serverJsonMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      assigneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_id'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      serverJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_json'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  Tasks createAlias(String alias) {
    return Tasks(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assigneeId;
  final String? dueDate;
  final String? completedAt;
  final int version;
  final String createdAt;
  final String syncState;
  final String? serverJson;
  final String payloadJson;
  const Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.dueDate,
    this.completedAt,
    required this.version,
    required this.createdAt,
    required this.syncState,
    this.serverJson,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || assigneeId != null) {
      map['assignee_id'] = Variable<String>(assigneeId);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<String>(createdAt);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || serverJson != null) {
      map['server_json'] = Variable<String>(serverJson);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      title: Value(title),
      description: Value(description),
      status: Value(status),
      priority: Value(priority),
      assigneeId: assigneeId == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeId),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      version: Value(version),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
      serverJson: serverJson == null && nullToAbsent
          ? const Value.absent()
          : Value(serverJson),
      payloadJson: Value(payloadJson),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['project_id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      assigneeId: serializer.fromJson<String?>(json['assignee_id']),
      dueDate: serializer.fromJson<String?>(json['due_date']),
      completedAt: serializer.fromJson<String?>(json['completed_at']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      syncState: serializer.fromJson<String>(json['sync_state']),
      serverJson: serializer.fromJson<String?>(json['server_json']),
      payloadJson: serializer.fromJson<String>(json['payload_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'project_id': serializer.toJson<String>(projectId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'assignee_id': serializer.toJson<String?>(assigneeId),
      'due_date': serializer.toJson<String?>(dueDate),
      'completed_at': serializer.toJson<String?>(completedAt),
      'version': serializer.toJson<int>(version),
      'created_at': serializer.toJson<String>(createdAt),
      'sync_state': serializer.toJson<String>(syncState),
      'server_json': serializer.toJson<String?>(serverJson),
      'payload_json': serializer.toJson<String>(payloadJson),
    };
  }

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? status,
    String? priority,
    Value<String?> assigneeId = const Value.absent(),
    Value<String?> dueDate = const Value.absent(),
    Value<String?> completedAt = const Value.absent(),
    int? version,
    String? createdAt,
    String? syncState,
    Value<String?> serverJson = const Value.absent(),
    String? payloadJson,
  }) => Task(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    assigneeId: assigneeId.present ? assigneeId.value : this.assigneeId,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    syncState: syncState ?? this.syncState,
    serverJson: serverJson.present ? serverJson.value : this.serverJson,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      assigneeId: data.assigneeId.present
          ? data.assigneeId.value
          : this.assigneeId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      serverJson: data.serverJson.present
          ? data.serverJson.value
          : this.serverJson,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('dueDate: $dueDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('serverJson: $serverJson, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    description,
    status,
    priority,
    assigneeId,
    dueDate,
    completedAt,
    version,
    createdAt,
    syncState,
    serverJson,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.assigneeId == this.assigneeId &&
          other.dueDate == this.dueDate &&
          other.completedAt == this.completedAt &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState &&
          other.serverJson == this.serverJson &&
          other.payloadJson == this.payloadJson);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> status;
  final Value<String> priority;
  final Value<String?> assigneeId;
  final Value<String?> dueDate;
  final Value<String?> completedAt;
  final Value<int> version;
  final Value<String> createdAt;
  final Value<String> syncState;
  final Value<String?> serverJson;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.assigneeId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.serverJson = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String projectId,
    required String title,
    required String description,
    required String status,
    required String priority,
    this.assigneeId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    required int version,
    required String createdAt,
    required String syncState,
    this.serverJson = const Value.absent(),
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       title = Value(title),
       description = Value(description),
       status = Value(status),
       priority = Value(priority),
       version = Value(version),
       createdAt = Value(createdAt),
       syncState = Value(syncState),
       payloadJson = Value(payloadJson);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? assigneeId,
    Expression<String>? dueDate,
    Expression<String>? completedAt,
    Expression<int>? version,
    Expression<String>? createdAt,
    Expression<String>? syncState,
    Expression<String>? serverJson,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (assigneeId != null) 'assignee_id': assigneeId,
      if (dueDate != null) 'due_date': dueDate,
      if (completedAt != null) 'completed_at': completedAt,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (serverJson != null) 'server_json': serverJson,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? title,
    Value<String>? description,
    Value<String>? status,
    Value<String>? priority,
    Value<String?>? assigneeId,
    Value<String?>? dueDate,
    Value<String?>? completedAt,
    Value<int>? version,
    Value<String>? createdAt,
    Value<String>? syncState,
    Value<String?>? serverJson,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      serverJson: serverJson ?? this.serverJson,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (assigneeId.present) {
      map['assignee_id'] = Variable<String>(assigneeId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (serverJson.present) {
      map['server_json'] = Variable<String>(serverJson.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('dueDate: $dueDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('serverJson: $serverJson, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Comments extends Table with TableInfo<Comments, Comment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Comments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    authorId,
    authorName,
    body,
    createdAt,
    syncState,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Comment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Comment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Comment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  Comments createAlias(String alias) {
    return Comments(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Comment extends DataClass implements Insertable<Comment> {
  final String id;
  final String taskId;
  final String authorId;
  final String authorName;
  final String body;
  final String createdAt;
  final String syncState;
  final String payloadJson;
  const Comment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.syncState,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['author_id'] = Variable<String>(authorId);
    map['author_name'] = Variable<String>(authorName);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<String>(createdAt);
    map['sync_state'] = Variable<String>(syncState);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  CommentsCompanion toCompanion(bool nullToAbsent) {
    return CommentsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      authorId: Value(authorId),
      authorName: Value(authorName),
      body: Value(body),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
      payloadJson: Value(payloadJson),
    );
  }

  factory Comment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Comment(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['task_id']),
      authorId: serializer.fromJson<String>(json['author_id']),
      authorName: serializer.fromJson<String>(json['author_name']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      syncState: serializer.fromJson<String>(json['sync_state']),
      payloadJson: serializer.fromJson<String>(json['payload_json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'task_id': serializer.toJson<String>(taskId),
      'author_id': serializer.toJson<String>(authorId),
      'author_name': serializer.toJson<String>(authorName),
      'body': serializer.toJson<String>(body),
      'created_at': serializer.toJson<String>(createdAt),
      'sync_state': serializer.toJson<String>(syncState),
      'payload_json': serializer.toJson<String>(payloadJson),
    };
  }

  Comment copyWith({
    String? id,
    String? taskId,
    String? authorId,
    String? authorName,
    String? body,
    String? createdAt,
    String? syncState,
    String? payloadJson,
  }) => Comment(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    syncState: syncState ?? this.syncState,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  Comment copyWithCompanion(CommentsCompanion data) {
    return Comment(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Comment(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    authorId,
    authorName,
    body,
    createdAt,
    syncState,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Comment &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.authorId == this.authorId &&
          other.authorName == this.authorName &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState &&
          other.payloadJson == this.payloadJson);
}

class CommentsCompanion extends UpdateCompanion<Comment> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> authorId;
  final Value<String> authorName;
  final Value<String> body;
  final Value<String> createdAt;
  final Value<String> syncState;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const CommentsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.authorId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommentsCompanion.insert({
    required String id,
    required String taskId,
    required String authorId,
    required String authorName,
    required String body,
    required String createdAt,
    required String syncState,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       authorId = Value(authorId),
       authorName = Value(authorName),
       body = Value(body),
       createdAt = Value(createdAt),
       syncState = Value(syncState),
       payloadJson = Value(payloadJson);
  static Insertable<Comment> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? authorId,
    Expression<String>? authorName,
    Expression<String>? body,
    Expression<String>? createdAt,
    Expression<String>? syncState,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (authorId != null) 'author_id': authorId,
      if (authorName != null) 'author_name': authorName,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommentsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? authorId,
    Value<String>? authorName,
    Value<String>? body,
    Value<String>? createdAt,
    Value<String>? syncState,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return CommentsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('authorId: $authorId, ')
          ..write('authorName: $authorName, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Outbox extends Table with TableInfo<Outbox, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Outbox(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'create_task\', \'update_task\', \'complete_task\', \'create_comment\'))',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (state IN (\'pending\', \'in_flight\', \'failed\', \'conflict\'))',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastProblemTypeMeta = const VerificationMeta(
    'lastProblemType',
  );
  late final GeneratedColumn<String> lastProblemType = GeneratedColumn<String>(
    'last_problem_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _problemJsonMeta = const VerificationMeta(
    'problemJson',
  );
  late final GeneratedColumn<String> problemJson = GeneratedColumn<String>(
    'problem_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _serverJsonMeta = const VerificationMeta(
    'serverJson',
  );
  late final GeneratedColumn<String> serverJson = GeneratedColumn<String>(
    'server_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    id,
    kind,
    entityId,
    parentId,
    payload,
    baseVersion,
    state,
    attempts,
    nextAttemptAt,
    lastProblemType,
    problemJson,
    serverJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_parentIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_problem_type')) {
      context.handle(
        _lastProblemTypeMeta,
        lastProblemType.isAcceptableOrUnknown(
          data['last_problem_type']!,
          _lastProblemTypeMeta,
        ),
      );
    }
    if (data.containsKey('problem_json')) {
      context.handle(
        _problemJsonMeta,
        problemJson.isAcceptableOrUnknown(
          data['problem_json']!,
          _problemJsonMeta,
        ),
      );
    }
    if (data.containsKey('server_json')) {
      context.handle(
        _serverJsonMeta,
        serverJson.isAcceptableOrUnknown(data['server_json']!, _serverJsonMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastProblemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_problem_type'],
      ),
      problemJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}problem_json'],
      ),
      serverJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Outbox createAlias(String alias) {
    return Outbox(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int seq;
  final String id;
  final String kind;
  final String entityId;
  final String parentId;
  final String payload;
  final int? baseVersion;
  final String state;
  final int attempts;
  final int nextAttemptAt;
  final String? lastProblemType;
  final String? problemJson;
  final String? serverJson;
  final String createdAt;
  const OutboxData({
    required this.seq,
    required this.id,
    required this.kind,
    required this.entityId,
    required this.parentId,
    required this.payload,
    this.baseVersion,
    required this.state,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastProblemType,
    this.problemJson,
    this.serverJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['entity_id'] = Variable<String>(entityId);
    map['parent_id'] = Variable<String>(parentId);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    if (!nullToAbsent || lastProblemType != null) {
      map['last_problem_type'] = Variable<String>(lastProblemType);
    }
    if (!nullToAbsent || problemJson != null) {
      map['problem_json'] = Variable<String>(problemJson);
    }
    if (!nullToAbsent || serverJson != null) {
      map['server_json'] = Variable<String>(serverJson);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      id: Value(id),
      kind: Value(kind),
      entityId: Value(entityId),
      parentId: Value(parentId),
      payload: Value(payload),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      state: Value(state),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastProblemType: lastProblemType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProblemType),
      problemJson: problemJson == null && nullToAbsent
          ? const Value.absent()
          : Value(problemJson),
      serverJson: serverJson == null && nullToAbsent
          ? const Value.absent()
          : Value(serverJson),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      parentId: serializer.fromJson<String>(json['parent_id']),
      payload: serializer.fromJson<String>(json['payload']),
      baseVersion: serializer.fromJson<int?>(json['base_version']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int>(json['next_attempt_at']),
      lastProblemType: serializer.fromJson<String?>(json['last_problem_type']),
      problemJson: serializer.fromJson<String?>(json['problem_json']),
      serverJson: serializer.fromJson<String?>(json['server_json']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'entity_id': serializer.toJson<String>(entityId),
      'parent_id': serializer.toJson<String>(parentId),
      'payload': serializer.toJson<String>(payload),
      'base_version': serializer.toJson<int?>(baseVersion),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'next_attempt_at': serializer.toJson<int>(nextAttemptAt),
      'last_problem_type': serializer.toJson<String?>(lastProblemType),
      'problem_json': serializer.toJson<String?>(problemJson),
      'server_json': serializer.toJson<String?>(serverJson),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? id,
    String? kind,
    String? entityId,
    String? parentId,
    String? payload,
    Value<int?> baseVersion = const Value.absent(),
    String? state,
    int? attempts,
    int? nextAttemptAt,
    Value<String?> lastProblemType = const Value.absent(),
    Value<String?> problemJson = const Value.absent(),
    Value<String?> serverJson = const Value.absent(),
    String? createdAt,
  }) => OutboxData(
    seq: seq ?? this.seq,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    entityId: entityId ?? this.entityId,
    parentId: parentId ?? this.parentId,
    payload: payload ?? this.payload,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastProblemType: lastProblemType.present
        ? lastProblemType.value
        : this.lastProblemType,
    problemJson: problemJson.present ? problemJson.value : this.problemJson,
    serverJson: serverJson.present ? serverJson.value : this.serverJson,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      payload: data.payload.present ? data.payload.value : this.payload,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastProblemType: data.lastProblemType.present
          ? data.lastProblemType.value
          : this.lastProblemType,
      problemJson: data.problemJson.present
          ? data.problemJson.value
          : this.problemJson,
      serverJson: data.serverJson.present
          ? data.serverJson.value
          : this.serverJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('parentId: $parentId, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastProblemType: $lastProblemType, ')
          ..write('problemJson: $problemJson, ')
          ..write('serverJson: $serverJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    id,
    kind,
    entityId,
    parentId,
    payload,
    baseVersion,
    state,
    attempts,
    nextAttemptAt,
    lastProblemType,
    problemJson,
    serverJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.entityId == this.entityId &&
          other.parentId == this.parentId &&
          other.payload == this.payload &&
          other.baseVersion == this.baseVersion &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastProblemType == this.lastProblemType &&
          other.problemJson == this.problemJson &&
          other.serverJson == this.serverJson &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> id;
  final Value<String> kind;
  final Value<String> entityId;
  final Value<String> parentId;
  final Value<String> payload;
  final Value<int?> baseVersion;
  final Value<String> state;
  final Value<int> attempts;
  final Value<int> nextAttemptAt;
  final Value<String?> lastProblemType;
  final Value<String?> problemJson;
  final Value<String?> serverJson;
  final Value<String> createdAt;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.entityId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.payload = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastProblemType = const Value.absent(),
    this.problemJson = const Value.absent(),
    this.serverJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String id,
    required String kind,
    required String entityId,
    required String parentId,
    required String payload,
    this.baseVersion = const Value.absent(),
    required String state,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastProblemType = const Value.absent(),
    this.problemJson = const Value.absent(),
    this.serverJson = const Value.absent(),
    required String createdAt,
  }) : id = Value(id),
       kind = Value(kind),
       entityId = Value(entityId),
       parentId = Value(parentId),
       payload = Value(payload),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? entityId,
    Expression<String>? parentId,
    Expression<String>? payload,
    Expression<int>? baseVersion,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastProblemType,
    Expression<String>? problemJson,
    Expression<String>? serverJson,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (entityId != null) 'entity_id': entityId,
      if (parentId != null) 'parent_id': parentId,
      if (payload != null) 'payload': payload,
      if (baseVersion != null) 'base_version': baseVersion,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastProblemType != null) 'last_problem_type': lastProblemType,
      if (problemJson != null) 'problem_json': problemJson,
      if (serverJson != null) 'server_json': serverJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? id,
    Value<String>? kind,
    Value<String>? entityId,
    Value<String>? parentId,
    Value<String>? payload,
    Value<int?>? baseVersion,
    Value<String>? state,
    Value<int>? attempts,
    Value<int>? nextAttemptAt,
    Value<String?>? lastProblemType,
    Value<String?>? problemJson,
    Value<String?>? serverJson,
    Value<String>? createdAt,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      entityId: entityId ?? this.entityId,
      parentId: parentId ?? this.parentId,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastProblemType: lastProblemType ?? this.lastProblemType,
      problemJson: problemJson ?? this.problemJson,
      serverJson: serverJson ?? this.serverJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastProblemType.present) {
      map['last_problem_type'] = Variable<String>(lastProblemType.value);
    }
    if (problemJson.present) {
      map['problem_json'] = Variable<String>(problemJson.value);
    }
    if (serverJson.present) {
      map['server_json'] = Variable<String>(serverJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('entityId: $entityId, ')
          ..write('parentId: $parentId, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastProblemType: $lastProblemType, ')
          ..write('problemJson: $problemJson, ')
          ..write('serverJson: $serverJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CachedPages extends Table with TableInfo<CachedPages, CachedPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CachedPages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageKeyMeta = const VerificationMeta(
    'pageKey',
  );
  late final GeneratedColumn<String> pageKey = GeneratedColumn<String>(
    'page_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _idsMeta = const VerificationMeta('ids');
  late final GeneratedColumn<String> ids = GeneratedColumn<String>(
    'ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nextCursorMeta = const VerificationMeta(
    'nextCursor',
  );
  late final GeneratedColumn<String> nextCursor = GeneratedColumn<String>(
    'next_cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [pageKey, ids, nextCursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page_key')) {
      context.handle(
        _pageKeyMeta,
        pageKey.isAcceptableOrUnknown(data['page_key']!, _pageKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pageKeyMeta);
    }
    if (data.containsKey('ids')) {
      context.handle(
        _idsMeta,
        ids.isAcceptableOrUnknown(data['ids']!, _idsMeta),
      );
    } else if (isInserting) {
      context.missing(_idsMeta);
    }
    if (data.containsKey('next_cursor')) {
      context.handle(
        _nextCursorMeta,
        nextCursor.isAcceptableOrUnknown(data['next_cursor']!, _nextCursorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pageKey};
  @override
  CachedPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPage(
      pageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_key'],
      )!,
      ids: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ids'],
      )!,
      nextCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_cursor'],
      ),
    );
  }

  @override
  CachedPages createAlias(String alias) {
    return CachedPages(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CachedPage extends DataClass implements Insertable<CachedPage> {
  final String pageKey;
  final String ids;
  final String? nextCursor;
  const CachedPage({required this.pageKey, required this.ids, this.nextCursor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page_key'] = Variable<String>(pageKey);
    map['ids'] = Variable<String>(ids);
    if (!nullToAbsent || nextCursor != null) {
      map['next_cursor'] = Variable<String>(nextCursor);
    }
    return map;
  }

  CachedPagesCompanion toCompanion(bool nullToAbsent) {
    return CachedPagesCompanion(
      pageKey: Value(pageKey),
      ids: Value(ids),
      nextCursor: nextCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(nextCursor),
    );
  }

  factory CachedPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPage(
      pageKey: serializer.fromJson<String>(json['page_key']),
      ids: serializer.fromJson<String>(json['ids']),
      nextCursor: serializer.fromJson<String?>(json['next_cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page_key': serializer.toJson<String>(pageKey),
      'ids': serializer.toJson<String>(ids),
      'next_cursor': serializer.toJson<String?>(nextCursor),
    };
  }

  CachedPage copyWith({
    String? pageKey,
    String? ids,
    Value<String?> nextCursor = const Value.absent(),
  }) => CachedPage(
    pageKey: pageKey ?? this.pageKey,
    ids: ids ?? this.ids,
    nextCursor: nextCursor.present ? nextCursor.value : this.nextCursor,
  );
  CachedPage copyWithCompanion(CachedPagesCompanion data) {
    return CachedPage(
      pageKey: data.pageKey.present ? data.pageKey.value : this.pageKey,
      ids: data.ids.present ? data.ids.value : this.ids,
      nextCursor: data.nextCursor.present
          ? data.nextCursor.value
          : this.nextCursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPage(')
          ..write('pageKey: $pageKey, ')
          ..write('ids: $ids, ')
          ..write('nextCursor: $nextCursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pageKey, ids, nextCursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPage &&
          other.pageKey == this.pageKey &&
          other.ids == this.ids &&
          other.nextCursor == this.nextCursor);
}

class CachedPagesCompanion extends UpdateCompanion<CachedPage> {
  final Value<String> pageKey;
  final Value<String> ids;
  final Value<String?> nextCursor;
  final Value<int> rowid;
  const CachedPagesCompanion({
    this.pageKey = const Value.absent(),
    this.ids = const Value.absent(),
    this.nextCursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPagesCompanion.insert({
    required String pageKey,
    required String ids,
    this.nextCursor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pageKey = Value(pageKey),
       ids = Value(ids);
  static Insertable<CachedPage> custom({
    Expression<String>? pageKey,
    Expression<String>? ids,
    Expression<String>? nextCursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pageKey != null) 'page_key': pageKey,
      if (ids != null) 'ids': ids,
      if (nextCursor != null) 'next_cursor': nextCursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPagesCompanion copyWith({
    Value<String>? pageKey,
    Value<String>? ids,
    Value<String?>? nextCursor,
    Value<int>? rowid,
  }) {
    return CachedPagesCompanion(
      pageKey: pageKey ?? this.pageKey,
      ids: ids ?? this.ids,
      nextCursor: nextCursor ?? this.nextCursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pageKey.present) {
      map['page_key'] = Variable<String>(pageKey.value);
    }
    if (ids.present) {
      map['ids'] = Variable<String>(ids.value);
    }
    if (nextCursor.present) {
      map['next_cursor'] = Variable<String>(nextCursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPagesCompanion(')
          ..write('pageKey: $pageKey, ')
          ..write('ids: $ids, ')
          ..write('nextCursor: $nextCursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncLeases extends Table with TableInfo<SyncLeases, SyncLease> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncLeases(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _expiresMeta = const VerificationMeta(
    'expires',
  );
  late final GeneratedColumn<int> expires = GeneratedColumn<int>(
    'expires',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [name, owner, expires];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_leases';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLease> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner')) {
      context.handle(
        _ownerMeta,
        owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('expires')) {
      context.handle(
        _expiresMeta,
        expires.isAcceptableOrUnknown(data['expires']!, _expiresMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  SyncLease map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLease(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      owner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner'],
      )!,
      expires: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires'],
      )!,
    );
  }

  @override
  SyncLeases createAlias(String alias) {
    return SyncLeases(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncLease extends DataClass implements Insertable<SyncLease> {
  final String name;
  final String owner;
  final int expires;
  const SyncLease({
    required this.name,
    required this.owner,
    required this.expires,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['owner'] = Variable<String>(owner);
    map['expires'] = Variable<int>(expires);
    return map;
  }

  SyncLeasesCompanion toCompanion(bool nullToAbsent) {
    return SyncLeasesCompanion(
      name: Value(name),
      owner: Value(owner),
      expires: Value(expires),
    );
  }

  factory SyncLease.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLease(
      name: serializer.fromJson<String>(json['name']),
      owner: serializer.fromJson<String>(json['owner']),
      expires: serializer.fromJson<int>(json['expires']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'owner': serializer.toJson<String>(owner),
      'expires': serializer.toJson<int>(expires),
    };
  }

  SyncLease copyWith({String? name, String? owner, int? expires}) => SyncLease(
    name: name ?? this.name,
    owner: owner ?? this.owner,
    expires: expires ?? this.expires,
  );
  SyncLease copyWithCompanion(SyncLeasesCompanion data) {
    return SyncLease(
      name: data.name.present ? data.name.value : this.name,
      owner: data.owner.present ? data.owner.value : this.owner,
      expires: data.expires.present ? data.expires.value : this.expires,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLease(')
          ..write('name: $name, ')
          ..write('owner: $owner, ')
          ..write('expires: $expires')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, owner, expires);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLease &&
          other.name == this.name &&
          other.owner == this.owner &&
          other.expires == this.expires);
}

class SyncLeasesCompanion extends UpdateCompanion<SyncLease> {
  final Value<String> name;
  final Value<String> owner;
  final Value<int> expires;
  final Value<int> rowid;
  const SyncLeasesCompanion({
    this.name = const Value.absent(),
    this.owner = const Value.absent(),
    this.expires = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncLeasesCompanion.insert({
    required String name,
    required String owner,
    required int expires,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       owner = Value(owner),
       expires = Value(expires);
  static Insertable<SyncLease> custom({
    Expression<String>? name,
    Expression<String>? owner,
    Expression<int>? expires,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (owner != null) 'owner': owner,
      if (expires != null) 'expires': expires,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncLeasesCompanion copyWith({
    Value<String>? name,
    Value<String>? owner,
    Value<int>? expires,
    Value<int>? rowid,
  }) {
    return SyncLeasesCompanion(
      name: name ?? this.name,
      owner: owner ?? this.owner,
      expires: expires ?? this.expires,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (expires.present) {
      map['expires'] = Variable<int>(expires.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLeasesCompanion(')
          ..write('name: $name, ')
          ..write('owner: $owner, ')
          ..write('expires: $expires, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Teams teams = Teams(this);
  late final Projects projects = Projects(this);
  late final Index projectsTeam = Index(
    'projects_team',
    'CREATE INDEX projects_team ON projects (team_id)',
  );
  late final Tasks tasks = Tasks(this);
  late final Index tasksProject = Index(
    'tasks_project',
    'CREATE INDEX tasks_project ON tasks (project_id, created_at DESC, id DESC)',
  );
  late final Comments comments = Comments(this);
  late final Index commentsTask = Index(
    'comments_task',
    'CREATE INDEX comments_task ON comments (task_id, created_at)',
  );
  late final Outbox outbox = Outbox(this);
  late final Index outboxReady = Index(
    'outbox_ready',
    'CREATE INDEX outbox_ready ON outbox (state, next_attempt_at)',
  );
  late final Index outboxEntity = Index(
    'outbox_entity',
    'CREATE INDEX outbox_entity ON outbox (entity_id, seq)',
  );
  late final AppSettings appSettings = AppSettings(this);
  late final CachedPages cachedPages = CachedPages(this);
  late final SyncLeases syncLeases = SyncLeases(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    teams,
    projects,
    projectsTeam,
    tasks,
    tasksProject,
    comments,
    commentsTask,
    outbox,
    outboxReady,
    outboxEntity,
    appSettings,
    cachedPages,
    syncLeases,
  ];
}

typedef $TeamsCreateCompanionBuilder = TeamsCompanion Function({
  required String id,
  required String name,
  required String description,
  Value<int> memberCount,
  required int version,
  required String updatedAt,
  required String payloadJson,
  Value<int> rowid,
});
typedef $TeamsUpdateCompanionBuilder = TeamsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> description,
  Value<int> memberCount,
  Value<int> version,
  Value<String> updatedAt,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $TeamsFilterComposer extends Composer<_$AppDatabase, Teams> {
  $TeamsFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $TeamsOrderingComposer extends Composer<_$AppDatabase, Teams> {
  $TeamsOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TeamsAnnotationComposer extends Composer<_$AppDatabase, Teams> {
  $TeamsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $TeamsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Teams,
          Team,
          $TeamsFilterComposer,
          $TeamsOrderingComposer,
          $TeamsAnnotationComposer,
          $TeamsCreateCompanionBuilder,
          $TeamsUpdateCompanionBuilder,
          (Team, BaseReferences<_$AppDatabase, Teams, Team>),
          Team,
          PrefetchHooks Function()
        > {
  $TeamsTableManager(_$AppDatabase db, Teams table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TeamsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TeamsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TeamsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion(
                id: id,
                name: name,
                description: description,
                memberCount: memberCount,
                version: version,
                updatedAt: updatedAt,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                Value<int> memberCount = const Value.absent(),
                required int version,
                required String updatedAt,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion.insert(
                id: id,
                name: name,
                description: description,
                memberCount: memberCount,
                version: version,
                updatedAt: updatedAt,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Teams, Team>(table),
                  BaseReferences<_$AppDatabase, Teams, Team>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TeamsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Teams,
      Team,
      $TeamsFilterComposer,
      $TeamsOrderingComposer,
      $TeamsAnnotationComposer,
      $TeamsCreateCompanionBuilder,
      $TeamsUpdateCompanionBuilder,
      (Team, BaseReferences<_$AppDatabase, Teams, Team>),
      Team,
      PrefetchHooks Function()
    >;
typedef $ProjectsCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String teamId,
  required String key,
  required String name,
  required String description,
  Value<int> archived,
  required int version,
  required String payloadJson,
  Value<int> rowid,
});
typedef $ProjectsUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> teamId,
  Value<String> key,
  Value<String> name,
  Value<String> description,
  Value<int> archived,
  Value<int> version,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $ProjectsFilterComposer extends Composer<_$AppDatabase, Projects> {
  $ProjectsFilterComposer({
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

  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $ProjectsOrderingComposer extends Composer<_$AppDatabase, Projects> {
  $ProjectsOrderingComposer({
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

  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ProjectsAnnotationComposer extends Composer<_$AppDatabase, Projects> {
  $ProjectsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $ProjectsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Projects,
          Project,
          $ProjectsFilterComposer,
          $ProjectsOrderingComposer,
          $ProjectsAnnotationComposer,
          $ProjectsCreateCompanionBuilder,
          $ProjectsUpdateCompanionBuilder,
          (Project, BaseReferences<_$AppDatabase, Projects, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $ProjectsTableManager(_$AppDatabase db, Projects table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProjectsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProjectsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProjectsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> archived = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                teamId: teamId,
                key: key,
                name: name,
                description: description,
                archived: archived,
                version: version,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teamId,
                required String key,
                required String name,
                required String description,
                Value<int> archived = const Value.absent(),
                required int version,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                teamId: teamId,
                key: key,
                name: name,
                description: description,
                archived: archived,
                version: version,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Projects, Project>(table),
                  BaseReferences<_$AppDatabase, Projects, Project>(
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

typedef $ProjectsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Projects,
      Project,
      $ProjectsFilterComposer,
      $ProjectsOrderingComposer,
      $ProjectsAnnotationComposer,
      $ProjectsCreateCompanionBuilder,
      $ProjectsUpdateCompanionBuilder,
      (Project, BaseReferences<_$AppDatabase, Projects, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $TasksCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String projectId,
  required String title,
  required String description,
  required String status,
  required String priority,
  Value<String?> assigneeId,
  Value<String?> dueDate,
  Value<String?> completedAt,
  required int version,
  required String createdAt,
  required String syncState,
  Value<String?> serverJson,
  required String payloadJson,
  Value<int> rowid,
});
typedef $TasksUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> title,
  Value<String> description,
  Value<String> status,
  Value<String> priority,
  Value<String?> assigneeId,
  Value<String?> dueDate,
  Value<String?> completedAt,
  Value<int> version,
  Value<String> createdAt,
  Value<String> syncState,
  Value<String?> serverJson,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $TasksFilterComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksFilterComposer({
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

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $TasksOrderingComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksOrderingComposer({
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

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TasksAnnotationComposer extends Composer<_$AppDatabase, Tasks> {
  $TasksAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $TasksTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Tasks,
          Task,
          $TasksFilterComposer,
          $TasksOrderingComposer,
          $TasksAnnotationComposer,
          $TasksCreateCompanionBuilder,
          $TasksUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, Tasks, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $TasksTableManager(_$AppDatabase db, Tasks table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TasksFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TasksOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TasksAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> serverJson = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                projectId: projectId,
                title: title,
                description: description,
                status: status,
                priority: priority,
                assigneeId: assigneeId,
                dueDate: dueDate,
                completedAt: completedAt,
                version: version,
                createdAt: createdAt,
                syncState: syncState,
                serverJson: serverJson,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String title,
                required String description,
                required String status,
                required String priority,
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                required int version,
                required String createdAt,
                required String syncState,
                Value<String?> serverJson = const Value.absent(),
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                description: description,
                status: status,
                priority: priority,
                assigneeId: assigneeId,
                dueDate: dueDate,
                completedAt: completedAt,
                version: version,
                createdAt: createdAt,
                syncState: syncState,
                serverJson: serverJson,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Tasks, Task>(table),
                  BaseReferences<_$AppDatabase, Tasks, Task>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TasksProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Tasks,
      Task,
      $TasksFilterComposer,
      $TasksOrderingComposer,
      $TasksAnnotationComposer,
      $TasksCreateCompanionBuilder,
      $TasksUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, Tasks, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $CommentsCreateCompanionBuilder = CommentsCompanion Function({
  required String id,
  required String taskId,
  required String authorId,
  required String authorName,
  required String body,
  required String createdAt,
  required String syncState,
  required String payloadJson,
  Value<int> rowid,
});
typedef $CommentsUpdateCompanionBuilder = CommentsCompanion Function({
  Value<String> id,
  Value<String> taskId,
  Value<String> authorId,
  Value<String> authorName,
  Value<String> body,
  Value<String> createdAt,
  Value<String> syncState,
  Value<String> payloadJson,
  Value<int> rowid,
});

class $CommentsFilterComposer extends Composer<_$AppDatabase, Comments> {
  $CommentsFilterComposer({
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

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $CommentsOrderingComposer extends Composer<_$AppDatabase, Comments> {
  $CommentsOrderingComposer({
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

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CommentsAnnotationComposer extends Composer<_$AppDatabase, Comments> {
  $CommentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $CommentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Comments,
          Comment,
          $CommentsFilterComposer,
          $CommentsOrderingComposer,
          $CommentsAnnotationComposer,
          $CommentsCreateCompanionBuilder,
          $CommentsUpdateCompanionBuilder,
          (Comment, BaseReferences<_$AppDatabase, Comments, Comment>),
          Comment,
          PrefetchHooks Function()
        > {
  $CommentsTableManager(_$AppDatabase db, Comments table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CommentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CommentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CommentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommentsCompanion(
                id: id,
                taskId: taskId,
                authorId: authorId,
                authorName: authorName,
                body: body,
                createdAt: createdAt,
                syncState: syncState,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String authorId,
                required String authorName,
                required String body,
                required String createdAt,
                required String syncState,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => CommentsCompanion.insert(
                id: id,
                taskId: taskId,
                authorId: authorId,
                authorName: authorName,
                body: body,
                createdAt: createdAt,
                syncState: syncState,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Comments, Comment>(table),
                  BaseReferences<_$AppDatabase, Comments, Comment>(
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

typedef $CommentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Comments,
      Comment,
      $CommentsFilterComposer,
      $CommentsOrderingComposer,
      $CommentsAnnotationComposer,
      $CommentsCreateCompanionBuilder,
      $CommentsUpdateCompanionBuilder,
      (Comment, BaseReferences<_$AppDatabase, Comments, Comment>),
      Comment,
      PrefetchHooks Function()
    >;
typedef $OutboxCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String id,
  required String kind,
  required String entityId,
  required String parentId,
  required String payload,
  Value<int?> baseVersion,
  required String state,
  Value<int> attempts,
  Value<int> nextAttemptAt,
  Value<String?> lastProblemType,
  Value<String?> problemJson,
  Value<String?> serverJson,
  required String createdAt,
});
typedef $OutboxUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> id,
  Value<String> kind,
  Value<String> entityId,
  Value<String> parentId,
  Value<String> payload,
  Value<int?> baseVersion,
  Value<String> state,
  Value<int> attempts,
  Value<int> nextAttemptAt,
  Value<String?> lastProblemType,
  Value<String?> problemJson,
  Value<String?> serverJson,
  Value<String> createdAt,
});

class $OutboxFilterComposer extends Composer<_$AppDatabase, Outbox> {
  $OutboxFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastProblemType => $composableBuilder(
    column: $table.lastProblemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get problemJson => $composableBuilder(
    column: $table.problemJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $OutboxOrderingComposer extends Composer<_$AppDatabase, Outbox> {
  $OutboxOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastProblemType => $composableBuilder(
    column: $table.lastProblemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get problemJson => $composableBuilder(
    column: $table.problemJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OutboxAnnotationComposer extends Composer<_$AppDatabase, Outbox> {
  $OutboxAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastProblemType => $composableBuilder(
    column: $table.lastProblemType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get problemJson => $composableBuilder(
    column: $table.problemJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverJson => $composableBuilder(
    column: $table.serverJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $OutboxTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Outbox,
          OutboxData,
          $OutboxFilterComposer,
          $OutboxOrderingComposer,
          $OutboxAnnotationComposer,
          $OutboxCreateCompanionBuilder,
          $OutboxUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, Outbox, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $OutboxTableManager(_$AppDatabase db, Outbox table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OutboxFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OutboxOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OutboxAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> parentId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastProblemType = const Value.absent(),
                Value<String?> problemJson = const Value.absent(),
                Value<String?> serverJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                id: id,
                kind: kind,
                entityId: entityId,
                parentId: parentId,
                payload: payload,
                baseVersion: baseVersion,
                state: state,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastProblemType: lastProblemType,
                problemJson: problemJson,
                serverJson: serverJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String id,
                required String kind,
                required String entityId,
                required String parentId,
                required String payload,
                Value<int?> baseVersion = const Value.absent(),
                required String state,
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastProblemType = const Value.absent(),
                Value<String?> problemJson = const Value.absent(),
                Value<String?> serverJson = const Value.absent(),
                required String createdAt,
              }) => OutboxCompanion.insert(
                seq: seq,
                id: id,
                kind: kind,
                entityId: entityId,
                parentId: parentId,
                payload: payload,
                baseVersion: baseVersion,
                state: state,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastProblemType: lastProblemType,
                problemJson: problemJson,
                serverJson: serverJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Outbox, OutboxData>(table),
                  BaseReferences<_$AppDatabase, Outbox, OutboxData>(
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

typedef $OutboxProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Outbox,
      OutboxData,
      $OutboxFilterComposer,
      $OutboxOrderingComposer,
      $OutboxAnnotationComposer,
      $OutboxCreateCompanionBuilder,
      $OutboxUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, Outbox, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $AppSettingsCreateCompanionBuilder = AppSettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $AppSettingsUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $AppSettingsFilterComposer extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsFilterComposer({
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
}

class $AppSettingsOrderingComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsOrderingComposer({
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
}

class $AppSettingsAnnotationComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsAnnotationComposer({
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
}

class $AppSettingsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AppSettings,
          AppSetting,
          $AppSettingsFilterComposer,
          $AppSettingsOrderingComposer,
          $AppSettingsAnnotationComposer,
          $AppSettingsCreateCompanionBuilder,
          $AppSettingsUpdateCompanionBuilder,
          (AppSetting, BaseReferences<_$AppDatabase, AppSettings, AppSetting>),
          AppSetting,
          PrefetchHooks Function()
        > {
  $AppSettingsTableManager(_$AppDatabase db, AppSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AppSettings, AppSetting>(table),
                  BaseReferences<_$AppDatabase, AppSettings, AppSetting>(
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

typedef $AppSettingsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AppSettings,
      AppSetting,
      $AppSettingsFilterComposer,
      $AppSettingsOrderingComposer,
      $AppSettingsAnnotationComposer,
      $AppSettingsCreateCompanionBuilder,
      $AppSettingsUpdateCompanionBuilder,
      (AppSetting, BaseReferences<_$AppDatabase, AppSettings, AppSetting>),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $CachedPagesCreateCompanionBuilder = CachedPagesCompanion Function({
  required String pageKey,
  required String ids,
  Value<String?> nextCursor,
  Value<int> rowid,
});
typedef $CachedPagesUpdateCompanionBuilder = CachedPagesCompanion Function({
  Value<String> pageKey,
  Value<String> ids,
  Value<String?> nextCursor,
  Value<int> rowid,
});

class $CachedPagesFilterComposer extends Composer<_$AppDatabase, CachedPages> {
  $CachedPagesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pageKey => $composableBuilder(
    column: $table.pageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ids => $composableBuilder(
    column: $table.ids,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextCursor => $composableBuilder(
    column: $table.nextCursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $CachedPagesOrderingComposer
    extends Composer<_$AppDatabase, CachedPages> {
  $CachedPagesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pageKey => $composableBuilder(
    column: $table.pageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ids => $composableBuilder(
    column: $table.ids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextCursor => $composableBuilder(
    column: $table.nextCursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CachedPagesAnnotationComposer
    extends Composer<_$AppDatabase, CachedPages> {
  $CachedPagesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pageKey =>
      $composableBuilder(column: $table.pageKey, builder: (column) => column);

  GeneratedColumn<String> get ids =>
      $composableBuilder(column: $table.ids, builder: (column) => column);

  GeneratedColumn<String> get nextCursor => $composableBuilder(
    column: $table.nextCursor,
    builder: (column) => column,
  );
}

class $CachedPagesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CachedPages,
          CachedPage,
          $CachedPagesFilterComposer,
          $CachedPagesOrderingComposer,
          $CachedPagesAnnotationComposer,
          $CachedPagesCreateCompanionBuilder,
          $CachedPagesUpdateCompanionBuilder,
          (CachedPage, BaseReferences<_$AppDatabase, CachedPages, CachedPage>),
          CachedPage,
          PrefetchHooks Function()
        > {
  $CachedPagesTableManager(_$AppDatabase db, CachedPages table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CachedPagesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CachedPagesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CachedPagesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pageKey = const Value.absent(),
                Value<String> ids = const Value.absent(),
                Value<String?> nextCursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPagesCompanion(
                pageKey: pageKey,
                ids: ids,
                nextCursor: nextCursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pageKey,
                required String ids,
                Value<String?> nextCursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPagesCompanion.insert(
                pageKey: pageKey,
                ids: ids,
                nextCursor: nextCursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<CachedPages, CachedPage>(table),
                  BaseReferences<_$AppDatabase, CachedPages, CachedPage>(
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

typedef $CachedPagesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CachedPages,
      CachedPage,
      $CachedPagesFilterComposer,
      $CachedPagesOrderingComposer,
      $CachedPagesAnnotationComposer,
      $CachedPagesCreateCompanionBuilder,
      $CachedPagesUpdateCompanionBuilder,
      (CachedPage, BaseReferences<_$AppDatabase, CachedPages, CachedPage>),
      CachedPage,
      PrefetchHooks Function()
    >;
typedef $SyncLeasesCreateCompanionBuilder = SyncLeasesCompanion Function({
  required String name,
  required String owner,
  required int expires,
  Value<int> rowid,
});
typedef $SyncLeasesUpdateCompanionBuilder = SyncLeasesCompanion Function({
  Value<String> name,
  Value<String> owner,
  Value<int> expires,
  Value<int> rowid,
});

class $SyncLeasesFilterComposer extends Composer<_$AppDatabase, SyncLeases> {
  $SyncLeasesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncLeasesOrderingComposer extends Composer<_$AppDatabase, SyncLeases> {
  $SyncLeasesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expires => $composableBuilder(
    column: $table.expires,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncLeasesAnnotationComposer
    extends Composer<_$AppDatabase, SyncLeases> {
  $SyncLeasesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<int> get expires =>
      $composableBuilder(column: $table.expires, builder: (column) => column);
}

class $SyncLeasesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncLeases,
          SyncLease,
          $SyncLeasesFilterComposer,
          $SyncLeasesOrderingComposer,
          $SyncLeasesAnnotationComposer,
          $SyncLeasesCreateCompanionBuilder,
          $SyncLeasesUpdateCompanionBuilder,
          (SyncLease, BaseReferences<_$AppDatabase, SyncLeases, SyncLease>),
          SyncLease,
          PrefetchHooks Function()
        > {
  $SyncLeasesTableManager(_$AppDatabase db, SyncLeases table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncLeasesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncLeasesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncLeasesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> owner = const Value.absent(),
                Value<int> expires = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncLeasesCompanion(
                name: name,
                owner: owner,
                expires: expires,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String owner,
                required int expires,
                Value<int> rowid = const Value.absent(),
              }) => SyncLeasesCompanion.insert(
                name: name,
                owner: owner,
                expires: expires,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SyncLeases, SyncLease>(table),
                  BaseReferences<_$AppDatabase, SyncLeases, SyncLease>(
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

typedef $SyncLeasesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncLeases,
      SyncLease,
      $SyncLeasesFilterComposer,
      $SyncLeasesOrderingComposer,
      $SyncLeasesAnnotationComposer,
      $SyncLeasesCreateCompanionBuilder,
      $SyncLeasesUpdateCompanionBuilder,
      (SyncLease, BaseReferences<_$AppDatabase, SyncLeases, SyncLease>),
      SyncLease,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $TeamsTableManager get teams => $TeamsTableManager(_db, _db.teams);
  $ProjectsTableManager get projects =>
      $ProjectsTableManager(_db, _db.projects);
  $TasksTableManager get tasks => $TasksTableManager(_db, _db.tasks);
  $CommentsTableManager get comments =>
      $CommentsTableManager(_db, _db.comments);
  $OutboxTableManager get outbox => $OutboxTableManager(_db, _db.outbox);
  $AppSettingsTableManager get appSettings =>
      $AppSettingsTableManager(_db, _db.appSettings);
  $CachedPagesTableManager get cachedPages =>
      $CachedPagesTableManager(_db, _db.cachedPages);
  $SyncLeasesTableManager get syncLeases =>
      $SyncLeasesTableManager(_db, _db.syncLeases);
}
