// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentCreate _$CommentCreateFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['body'],
    requiredKeys: const ['body'],
    disallowNullValues: const ['body'],
  );
  return CommentCreate(body: json['body'] as String);
}

Map<String, dynamic> _$CommentCreateToJson(CommentCreate instance) =>
    <String, dynamic>{'body': instance.body};
