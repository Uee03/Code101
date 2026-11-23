// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_page_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentPage$Response _$CommentPage$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return CommentPage$Response(
    items: (json['items'] as List<dynamic>)
        .map((e) => Comment$Response.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        CommentPage$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : CommentPage$Response._readExtras(
            CommentPage$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$CommentPage$ResponseToJson(
  CommentPage$Response instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
