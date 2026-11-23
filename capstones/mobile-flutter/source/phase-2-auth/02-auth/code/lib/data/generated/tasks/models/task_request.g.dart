// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task$Request _$Task$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'title',
      'description',
      'status',
      'priority',
      'assigneeId',
      'dueDate',
    ],
    disallowNullValues: const ['title', 'description', 'status', 'priority'],
  );
  return Task$Request(
    title: json['title'] as String,
    description: json['description'] as String,
    status: Task$Request._read_status(json['status']),
    priority: Task$Request._read_priority(json['priority']),
    assigneeId: json['assigneeId'] as String?,
    dueDate: json['dueDate'] as String?,
    additionalProperties:
        Task$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : Task$Request._readExtras(
            Task$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Task$RequestToJson(Task$Request instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'status': ?Task$Request._write_status(instance.status),
      'priority': ?Task$Request._write_priority(instance.priority),
      'assigneeId': instance.assigneeId,
      'dueDate': instance.dueDate,
    };
