// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_teams_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeTeamsItem _$MeTeamsItemFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['teamId', 'name', 'role'],
    disallowNullValues: const ['teamId', 'name', 'role'],
  );
  return MeTeamsItem(
    teamId: json['teamId'] as String,
    name: json['name'] as String,
    role: MeTeamsItem._read_role(json['role']),
    additionalProperties:
        MeTeamsItem._extras(json, 'additionalProperties') == null
        ? const {}
        : MeTeamsItem._readExtras(
            MeTeamsItem._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$MeTeamsItemToJson(MeTeamsItem instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'name': instance.name,
      'role': ?MeTeamsItem._write_role(instance.role),
    };
