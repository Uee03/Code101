// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Problem _$ProblemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'title', 'status'],
    disallowNullValues: const [
      'type',
      'title',
      'status',
      'detail',
      'instance',
      'traceId',
      'code',
    ],
  );
  return Problem(
    type: json['type'] as String,
    title: json['title'] as String,
    status: Problem._read_status(json['status']),
    detail: json['detail'] as String?,
    instance: json['instance'] as String?,
    traceId: json['traceId'] as String?,
    code: json['code'] as String?,
    additionalProperties: Problem._extras(json, 'additionalProperties') == null
        ? const {}
        : Problem._readExtras(Problem._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$ProblemToJson(Problem instance) => <String, dynamic>{
  'type': instance.type,
  'title': instance.title,
  'status': ?Problem._write_status(instance.status),
  'detail': ?instance.detail,
  'instance': ?instance.instance,
  'traceId': ?instance.traceId,
  'code': ?instance.code,
};
