// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['status'],
    disallowNullValues: const ['status', 'version', 'database'],
  );
  return Health(
    status: Health._read_status(json['status']),
    version: json['version'] as String?,
    database: Health._read_database(json['database']),
    additionalProperties: Health._extras(json, 'additionalProperties') == null
        ? const {}
        : Health._readExtras(Health._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'status': ?Health._write_status(instance.status),
  'version': ?instance.version,
  'database': ?Health._write_database(instance.database),
};
