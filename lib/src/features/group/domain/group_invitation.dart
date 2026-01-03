import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_invitation.freezed.dart';
part 'group_invitation.g.dart';

@freezed
abstract class GroupInvitation with _$GroupInvitation {
  const factory GroupInvitation({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'invite_code') required String inviteCode,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'max_uses') int? maxUses,
    @JsonKey(name: 'current_uses') int? currentUses,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'is_active') bool? isActive,
    @JsonKey(name: 'single_use') bool? singleUse,
    @JsonKey(name: 'used_by') String? usedBy,
  }) = _GroupInvitation;

  factory GroupInvitation.fromJson(Map<String, dynamic> json) =>
      _$GroupInvitationFromJson(json);
}
