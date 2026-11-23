// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_page_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentPage$Request _$CommentPage$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return CommentPage$Request(
    items: (json['items'] as List<dynamic>)
        .map((e) => Comment$Request.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        CommentPage$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : CommentPage$Request._readExtras(
            CommentPage$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$CommentPage$RequestToJson(
  CommentPage$Request instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
