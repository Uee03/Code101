// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEntry _$AuditEntryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'occurredAt',
      'actorId',
      'action',
      'entityType',
      'entityId',
      'details',
    ],
    disallowNullValues: const [
      'id',
      'occurredAt',
      'action',
      'entityType',
      'entityId',
      'details',
    ],
  );
  return AuditEntry(
    id: AuditEntry._read_id(json['id']),
    occurredAt: AuditEntry._read_occurredAt(json['occurredAt']),
    actorId: json['actorId'] as String?,
    action: AuditEntry._read_action(json['action']),
    entityType: AuditEntry._read_entityType(json['entityType']),
    entityId: json['entityId'] as String,
    details: json['details'] as Map<String, dynamic>,
    additionalProperties:
        AuditEntry._extras(json, 'additionalProperties') == null
        ? const {}
        : AuditEntry._readExtras(
            AuditEntry._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AuditEntryToJson(AuditEntry instance) =>
    <String, dynamic>{
      'id': ?AuditEntry._write_id(instance.id),
      'occurredAt': ?AuditEntry._write_occurredAt(instance.occurredAt),
      'actorId': instance.actorId,
      'action': ?AuditEntry._write_action(instance.action),
      'entityType': ?AuditEntry._write_entityType(instance.entityType),
      'entityId': instance.entityId,
      'details': instance.details,
    };
