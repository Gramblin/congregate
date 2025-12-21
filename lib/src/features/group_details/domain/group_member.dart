import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String userId,
    required String role,
    required String displayName,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
