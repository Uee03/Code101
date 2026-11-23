// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_problem_errors_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationProblemErrorsItem _$ValidationProblemErrorsItemFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['pointer', 'detail'],
    disallowNullValues: const ['pointer', 'detail'],
  );
  return ValidationProblemErrorsItem(
    pointer: json['pointer'] as String,
    detail: json['detail'] as String,
    additionalProperties:
        ValidationProblemErrorsItem._extras(json, 'additionalProperties') ==
            null
        ? const {}
        : ValidationProblemErrorsItem._readExtras(
            ValidationProblemErrorsItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ValidationProblemErrorsItemToJson(
  ValidationProblemErrorsItem instance,
) => <String, dynamic>{'pointer': instance.pointer, 'detail': instance.detail};
