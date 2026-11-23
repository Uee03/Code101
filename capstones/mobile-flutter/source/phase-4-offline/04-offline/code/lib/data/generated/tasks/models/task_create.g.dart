// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskCreate _$TaskCreateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'title',
      'description',
      'priority',
      'assigneeId',
      'dueDate',
    ],
    requiredKeys: const ['title'],
    disallowNullValues: const ['title', 'description', 'priority'],
  );
  return TaskCreate(
    title: json['title'] as String,
    description: TaskCreate._presentValue(json, 'description') == null
        ? ""
        : TaskCreate._read_description(
            TaskCreate._presentValue(json, 'description') as Object,
          ),
    priority: TaskCreate._read_priority(json['priority']),
    assigneeId: json['assigneeId'] as String?,
    dueDate: json['dueDate'] as String?,
  );
}

Map<String, dynamic> _$TaskCreateToJson(TaskCreate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': ?TaskCreate._write_description(instance.description),
      'priority': ?TaskCreate._write_priority(instance.priority),
      'assigneeId': ?instance.assigneeId,
      'dueDate': ?instance.dueDate,
    };
