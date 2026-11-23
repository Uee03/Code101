// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment$Request _$Comment$RequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['author', 'body'],
    disallowNullValues: const ['author', 'body'],
  );
  return Comment$Request(
    author: UserSummary.fromJson(json['author'] as Map<String, dynamic>),
    body: json['body'] as String,
    additionalProperties:
        Comment$Request._extras(json, 'additionalProperties') == null
        ? const {}
        : Comment$Request._readExtras(
            Comment$Request._extras(json, 'additionalProperties'),
          ),
  );
}

Map<String, dynamic> _$Comment$RequestToJson(Comment$Request instance) =>
    <String, dynamic>{
      'author': instance.author.toJson(),
      'body': instance.body,
    };
