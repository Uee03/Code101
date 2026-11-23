// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskUpdate _$TaskUpdateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'title',
      'description',
      'status',
      'priority',
      'assigneeId',
      'dueDate',
    ],
    disallowNullValues: const ['title', 'description', 'status', 'priority'],
  );
  return TaskUpdate(
    title: json['title'] as String?,
    description: json['description'] as String?,
    status: TaskUpdate._read_status(json['status']),
    priority: TaskUpdate._read_priority(json['priority']),
    assigneeId: json['assigneeId'] as String?,
    dueDate: json['dueDate'] as String?,
  );
}

Map<String, dynamic> _$TaskUpdateToJson(TaskUpdate instance) =>
    <String, dynamic>{
      'title': ?instance.title,
      'description': ?instance.description,
      'status': ?TaskUpdate._write_status(instance.status),
      'priority': ?TaskUpdate._write_priority(instance.priority),
      'assigneeId': ?instance.assigneeId,
      'dueDate': ?instance.dueDate,
    };
