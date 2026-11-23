// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPage _$UserPageFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return UserPage(
    items: (json['items'] as List<dynamic>)
        .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties: UserPage._extras(json, 'additionalProperties') == null
        ? const {}
        : UserPage._readExtras(UserPage._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$UserPageToJson(UserPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
