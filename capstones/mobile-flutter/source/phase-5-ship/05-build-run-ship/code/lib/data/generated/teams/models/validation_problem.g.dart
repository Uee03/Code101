// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_problem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationProblem _$ValidationProblemFromJson(Map<String, dynamic> json) {
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
      'errors',
    ],
  );
  return ValidationProblem(
    type: json['type'] as String,
    title: json['title'] as String,
    status: ValidationProblem._read_status(json['status']),
    detail: json['detail'] as String?,
    instance: json['instance'] as String?,
    traceId: json['traceId'] as String?,
    code: json['code'] as String?,
    errors: (json['errors'] as List<dynamic>?)
        ?.map(
          (e) =>
              ValidationProblemErrorsItem.fromJson(e as Map<String, dynamic>),
        )
        .toList(),
    additionalProperties:
        ValidationProblem._extras(json, 'additionalProperties') == null
        ? const {}
        : ValidationProblem._readExtras(
            ValidationProblem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ValidationProblemToJson(ValidationProblem instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'status': ?ValidationProblem._write_status(instance.status),
      'detail': ?instance.detail,
      'instance': ?instance.instance,
      'traceId': ?instance.traceId,
      'code': ?instance.code,
      'errors': ?instance.errors?.map((e) => e.toJson()).toList(),
    };
