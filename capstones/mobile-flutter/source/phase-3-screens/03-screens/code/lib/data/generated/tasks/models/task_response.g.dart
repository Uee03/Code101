// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task$Response _$Task$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'projectId',
      'title',
      'description',
      'status',
      'priority',
      'assigneeId',
      'dueDate',
      'completedAt',
      'createdBy',
      'version',
      'createdAt',
      'updatedAt',
    ],
    disallowNullValues: const [
      'id',
      'projectId',
      'title',
      'description',
      'status',
      'priority',
      'createdBy',
      'version',
      'createdAt',
      'updatedAt',
    ],
  );
  return Task$Response(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    status: Task$Response._read_status(json['status']),
    priority: Task$Response._read_priority(json['priority']),
    assigneeId: json['assigneeId'] as String?,
    dueDate: json['dueDate'] as String?,
    completedAt: Task$Response._read_completedAt(json['completedAt']),
    createdBy: json['createdBy'] as String,
    version: Task$Response._read_version(json['version']),
    createdAt: Task$Response._read_createdAt(json['createdAt']),
    updatedAt: Task$Response._read_updatedAt(json['updatedAt']),
    additionalProperties:
        Task$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : Task$Response._readExtras(
            Task$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Task$ResponseToJson(Task$Response instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'title': instance.title,
      'description': instance.description,
      'status': ?Task$Response._write_status(instance.status),
      'priority': ?Task$Response._write_priority(instance.priority),
      'assigneeId': instance.assigneeId,
      'dueDate': instance.dueDate,
      'completedAt': Task$Response._write_completedAt(instance.completedAt),
      'createdBy': instance.createdBy,
      'version': ?Task$Response._write_version(instance.version),
      'createdAt': ?Task$Response._write_createdAt(instance.createdAt),
      'updatedAt': ?Task$Response._write_updatedAt(instance.updatedAt),
    };
