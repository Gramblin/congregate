import 'dart:math' as math;

import 'package:congregate/src/features/group/domain/group_invitation.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'group_invitations_remote_repository.g.dart';

class GroupInvitationsRepository {
  GroupInvitationsRepository(this.client);
  final SupabaseClient client;

  /// Generate a random invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random.secure();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Create a new group invitation
  Future<GroupInvitation> createInvitation({
    required String groupId,
    int maxUses = 1, // Default to single-use
    DateTime? expiresAt,
  }) async {
    try {
      // Validate max uses
      if (maxUses < 1) {
        throw Exception('Max uses must be at least 1');
      }

      // Generate unique invite code
      String inviteCode;
      var isUnique = false;

      do {
        inviteCode = _generateInviteCode();
        final existing = await client
            .from('group_invitations')
            .select('id')
            .eq('invite_code', inviteCode)
            .maybeSingle();
        isUnique = existing == null;
      } while (!isUnique);

      final userId = client.auth.currentUser!.id;

      final response = await client
          .from('group_invitations')
          .insert({
            'group_id': groupId,
            'invite_code': inviteCode,
            'created_by': userId,
            'single_use': maxUses == 1, // Automatically set based on maxUses
            'expires_at': expiresAt?.toUtc().toIso8601String(),
            'max_uses': maxUses,
            'is_active': true,
          })
          .select()
          .single();

      return GroupInvitation.fromJson(response);
    } catch (e, st) {
      print('GroupInvitationsRepository.createInvitation error: $e\n$st');
      throw Exception('Failed to create invitation: $e');
    }
  }

  /// Get invitation by code
  Future<GroupInvitation?> getInvitationByCode(String inviteCode) async {
    try {
      final response = await client
          .from('group_invitations')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (response == null) return null;
      return GroupInvitation.fromJson(response);
    } catch (e, st) {
      print('GroupInvitationsRepository.getInvitationByCode error: $e\n$st');
      return null;
    }
  }

  /// Accept invitation and join group
  Future<void> acceptInvitation({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Get the invitation
      final invitation = await getInvitationByCode(inviteCode);
      if (invitation == null) {
        throw Exception('Invalid invitation code');
      }

      // Validate invitation
      if (invitation.isActive != true) {
        throw Exception('This invitation is no longer active');
      }

      if (invitation.expiresAt != null &&
          invitation.expiresAt!.isBefore(DateTime.now())) {
        throw Exception('This invitation has expired');
      }

      // Check if single-use and already used
      if ((invitation.singleUse ?? false) && invitation.usedBy != null) {
        throw Exception('This invitation has already been used');
      }

      // Check max uses
      if (invitation.maxUses != null &&
          (invitation.currentUses ?? 0) >= invitation.maxUses!) {
        throw Exception('This invitation has reached its maximum uses');
      }

      // Check if user is already a member
      final existingMember = await client
          .from('group_members')
          .select('user_id')
          .eq('group_id', invitation.groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this group');
      }

      // First, update the invitation BEFORE adding user to group
      print('Updating invitation before adding user...');
      print(
        'Invitation details: single_use=${invitation.singleUse}, current_uses=${invitation.currentUses}',
      );

      if (invitation.singleUse ?? false) {
        // Mark as used by this user and deactivate
        print('Updating single-use invitation...');
        final updateResult = await client
            .from('group_invitations')
            .update({
              'used_by': userId,
              'current_uses': (invitation.currentUses ?? 0) + 1,
              'is_active': false,
            })
            .eq('invite_code', inviteCode)
            .select();

        print('Update result: $updateResult');

        if (updateResult.isEmpty) {
          throw Exception('Failed to mark invitation as used');
        }
      } else {
        // Increment usage count
        print('Updating multi-use invitation...');
        final newCount = (invitation.currentUses ?? 0) + 1;
        final updates = <String, dynamic>{
          'current_uses': newCount,
        };

        if (invitation.maxUses != null && newCount >= invitation.maxUses!) {
          updates['is_active'] = false;
        }

        final updateResult = await client
            .from('group_invitations')
            .update(updates)
            .eq('invite_code', inviteCode)
            .select();

        print('Update result: $updateResult');

        if (updateResult.isEmpty) {
          throw Exception('Failed to update invitation usage');
        }
      }

      // Now add user to group
      print('Adding user to group...');
      await client.from('group_members').insert({
        'group_id': invitation.groupId,
        'user_id': userId,
        'role': 'member',
      });

      // Subscribe to FCM topic
      final groupData = await client
          .from('groups')
          .select('topic_id')
          .eq('id', invitation.groupId)
          .single();

      if (groupData['topic_id'] != null) {
        try {
          await FirebaseMessaging.instance.subscribeToTopic(
            groupData['topic_id'] as String,
          );
          print('Subscribed to group topic: ${groupData['topic_id']}');
        } catch (e) {
          print('Failed to subscribe to FCM topic: $e');
        }
      }
    } catch (e, st) {
      print('GroupInvitationsRepository.acceptInvitation error: $e\n$st');
      rethrow;
    }
  }

  /// Get all active invitations for a group (admin only)
  Future<List<GroupInvitation>> getGroupInvitations(String groupId) async {
    try {
      final response = await client
          .from('group_invitations')
          .select()
          .eq('group_id', groupId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GroupInvitation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      print('GroupInvitationsRepository.getGroupInvitations error: $e\n$st');
      throw Exception('Failed to fetch invitations: $e');
    }
  }

  /// Deactivate an invitation
  Future<void> deactivateInvitation(String invitationId) async {
    try {
      await client
          .from('group_invitations')
          .update({'is_active': false})
          .eq('id', invitationId);
    } catch (e, st) {
      print('GroupInvitationsRepository.deactivateInvitation error: $e\n$st');
      throw Exception('Failed to deactivate invitation: $e');
    }
  }
}

@Riverpod(keepAlive: true)
GroupInvitationsRepository groupInvitationsRepository(Ref ref) {
  return GroupInvitationsRepository(ref.watch(supabaseProvider).client);
}
