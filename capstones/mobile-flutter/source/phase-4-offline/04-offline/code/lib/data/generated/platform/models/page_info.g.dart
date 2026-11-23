// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageInfo _$PageInfoFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['limit', 'nextCursor'],
    disallowNullValues: const ['limit'],
  );
  return PageInfo(
    limit: PageInfo._read_limit(json['limit']),
    nextCursor: json['nextCursor'] as String?,
    additionalProperties: PageInfo._extras(json, 'additionalProperties') == null
        ? const {}
        : PageInfo._readExtras(PageInfo._extras(json, 'additionalProperties')),
  );
}

Map<String, dynamic> _$PageInfoToJson(PageInfo instance) => <String, dynamic>{
  'limit': ?PageInfo._write_limit(instance.limit),
  'nextCursor': instance.nextCursor,
};
