// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberPage _$MemberPageFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return MemberPage(
    items: (json['items'] as List<dynamic>)
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        MemberPage._extras(json, 'additionalProperties') == null
        ? const {}
        : MemberPage._readExtras(
            MemberPage._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$MemberPageToJson(MemberPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
