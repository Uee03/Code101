// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_page_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamPage$Response _$TeamPage$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return TeamPage$Response(
    items: (json['items'] as List<dynamic>)
        .map((e) => Team$Response.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        TeamPage$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : TeamPage$Response._readExtras(
            TeamPage$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TeamPage$ResponseToJson(TeamPage$Response instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
