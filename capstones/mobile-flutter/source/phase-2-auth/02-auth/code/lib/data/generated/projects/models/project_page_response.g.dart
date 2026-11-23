// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_page_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectPage$Response _$ProjectPage$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return ProjectPage$Response(
    items: (json['items'] as List<dynamic>)
        .map((e) => Project$Response.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        ProjectPage$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : ProjectPage$Response._readExtras(
            ProjectPage$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$ProjectPage$ResponseToJson(
  ProjectPage$Response instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'page': instance.page.toJson(),
};
