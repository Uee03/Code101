// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reassign_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReassignRequest _$ReassignRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['assigneeId'],
    requiredKeys: const ['assigneeId'],
  );
  return ReassignRequest(assigneeId: json['assigneeId'] as String?);
}

Map<String, dynamic> _$ReassignRequestToJson(ReassignRequest instance) =>
    <String, dynamic>{'assigneeId': instance.assigneeId};
