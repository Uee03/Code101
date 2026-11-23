// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_page_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamPage$Request _$TeamPage$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return TeamPage$Request(
    items: (json['items'] as List<dynamic>)
        .map((e) => Team$Request.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        TeamPage$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : TeamPage$Request._readExtras(
            TeamPage$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TeamPage$RequestToJson(TeamPage$Request instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
