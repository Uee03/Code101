// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team$Request _$Team$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'description'],
    disallowNullValues: const ['name', 'description'],
  );
  return Team$Request(
    name: json['name'] as String,
    description: json['description'] as String,
    additionalProperties:
        Team$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : Team$Request._readExtras(
            Team$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Team$RequestToJson(Team$Request instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
    };
