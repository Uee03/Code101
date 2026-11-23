// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditPage _$AuditPageFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return AuditPage(
    items: (json['items'] as List<dynamic>)
        .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        AuditPage._extras(json, 'additionalProperties') == null
        ? const {}
        : AuditPage._readExtras(
            AuditPage._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$AuditPageToJson(AuditPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
