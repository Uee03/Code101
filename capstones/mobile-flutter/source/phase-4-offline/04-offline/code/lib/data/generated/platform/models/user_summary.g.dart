// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSummary _$UserSummaryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'username', 'displayName'],
    disallowNullValues: const ['id', 'username', 'displayName'],
  );
  return UserSummary(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['displayName'] as String,
    additionalProperties:
        UserSummary._extras(json, 'additionalProperties') == null
        ? const {}
        : UserSummary._readExtras(
            UserSummary._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$UserSummaryToJson(UserSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
    };
