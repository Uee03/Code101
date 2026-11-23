// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_put.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberPut _$MemberPutFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const ['role'],
    requiredKeys: const ['role'],
    disallowNullValues: const ['role'],
  );
  return MemberPut(role: MemberPut._read_role(json['role']));
}

Map<String, dynamic> _$MemberPutToJson(MemberPut instance) => <String, dynamic>{
  'role': ?MemberPut._write_role(instance.role),
};
