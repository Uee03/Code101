// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment$Response _$Comment$ResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'taskId', 'author', 'body', 'createdAt'],
    disallowNullValues: const ['id', 'taskId', 'author', 'body', 'createdAt'],
  );
  return Comment$Response(
    id: json['id'] as String,
    taskId: json['taskId'] as String,
    author: UserSummary.fromJson(json['author'] as Map<String, dynamic>),
    body: json['body'] as String,
    createdAt: Comment$Response._read_createdAt(json['createdAt']),
    additionalProperties:
        Comment$Response._extras(json, 'additionalProperties') == null
        ? const {}
        : Comment$Response._readExtras(
            Comment$Response._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Comment$ResponseToJson(Comment$Response instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskId': instance.taskId,
      'author': instance.author.toJson(),
      'body': instance.body,
      'createdAt': ?Comment$Response._write_createdAt(instance.createdAt),
    };
