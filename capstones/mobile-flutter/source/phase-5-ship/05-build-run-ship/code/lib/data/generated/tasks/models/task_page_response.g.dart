// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_page_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskPage$Response _$TaskPage$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return TaskPage$Response(
    items: (json['items'] as List<dynamic>)
        .map((e) => Task$Response.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        TaskPage$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : TaskPage$Response._readExtras(
            TaskPage$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TaskPage$ResponseToJson(TaskPage$Response instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
