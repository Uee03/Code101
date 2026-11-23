// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_page_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectPage$Request _$ProjectPage$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return ProjectPage$Request(
    items: (json['items'] as List<dynamic>)
        .map((e) => Project$Request.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        ProjectPage$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : ProjectPage$Request._readExtras(
            ProjectPage$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ProjectPage$RequestToJson(
  ProjectPage$Request instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
