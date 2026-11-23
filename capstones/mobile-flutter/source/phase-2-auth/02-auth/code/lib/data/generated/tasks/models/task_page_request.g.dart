// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_page_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskPage$Request _$TaskPage$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['items', 'page'],
    disallowNullValues: const ['items', 'page'],
  );
  return TaskPage$Request(
    items: (json['items'] as List<dynamic>)
        .map((e) => Task$Request.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: PageInfo.fromJson(json['page'] as Map<String, dynamic>),
    additionalProperties:
        TaskPage$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : TaskPage$Request._readExtras(
            TaskPage$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$TaskPage$RequestToJson(TaskPage$Request instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page.toJson(),
    };
