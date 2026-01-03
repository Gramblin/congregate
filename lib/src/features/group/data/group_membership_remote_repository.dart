import 'dart:developer';

import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'group_membership_remote_repository.g.dart';

class GroupMembershipRepository {
  GroupMembershipRepository(this.client, this.messaging);
  final SupabaseClient client;
  final FirebaseMessaging messaging;

  /// Join a group and subscribe to its FCM topic
  Future<void> joinGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Get the group's topic_id
      final groupData = await client
          .from('groups')
          .select('topic_id')
          .eq('id', groupId)
          .maybeSingle();

      if (groupData == null) {
        throw Exception('Group not found');
      }

      final topicId = groupData['topic_id'] as String;

      // Add user to group_members table
      await client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
      });

      // Subscribe to FCM topic
      try {
        await messaging.subscribeToTopic(topicId);
        log('User $userId subscribed to topic: $topicId');
      } on Exception catch (e) {
        log('Failed to subscribe to FCM topic: $e');
        // User is already in group, just log the error
      }
    } catch (e, st) {
      log('GroupMembershipRepository.joinGroup exception: $e\n$st');
      rethrow;
    }
  }

  /// Leave a group and unsubscribe from its FCM topic
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Get the group's topic_id and creator before leaving
      final groupData = await client
          .from('groups')
          .select('topic_id, created_by')
          .eq('id', groupId)
          .maybeSingle();

      if (groupData == null) {
        throw Exception('Group not found');
      }

      // Prevent group creator from leaving
      if (groupData['created_by'] == userId) {
        throw Exception(
          'Group creators cannot leave. Delete the group instead.',
        );
      }

      final topicId = groupData['topic_id'] as String;

      // Remove user from group_members
      await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      // Unsubscribe from FCM topic
      try {
        await messaging.unsubscribeFromTopic(topicId);
        log('User $userId unsubscribed from topic: $topicId');
      } on Exception catch (e) {
        log('Failed to unsubscribe from FCM topic: $e');
        // Don't throw - user is already removed from group
      }
    } catch (e, st) {
      log('GroupMembershipRepository.leaveGroup exception: $e\n$st');
      rethrow;
    }
  }

  /// Validate invite code and join the group
  Future<void> joinGroupViaInvite({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Validate invite and get groupId
      final groupId = await validateInviteCode(inviteCode);

      // Check if user is already a member
      final existingMember = await client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this group');
      }

      // Join the group (includes FCM subscription)
      await joinGroup(groupId: groupId, userId: userId);

      log('User $userId joined group $groupId via invite code');
    } on Exception catch (e, st) {
      log('GroupMembershipRepository.joinGroupViaInvite exception: $e\n$st');
      rethrow;
    }
  }

  /// Request to join a private group
  Future<void> requestToJoinGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Verify the group exists and is not public
      final groupData = await client
          .from('groups')
          .select('is_public')
          .eq('id', groupId)
          .maybeSingle();

      if (groupData == null) {
        throw Exception('Group not found');
      }

      if (groupData['is_public'] == true) {
        throw Exception('This is a public group. You can join directly.');
      }

      // Check if user is already a member
      final existingMember = await client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this group');
      }

      // Check if there's already a pending request
      final existingRequest = await client
          .from('group_join_requests')
          .select('status')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        throw Exception('You already have a pending request for this group');
      }

      // Create join request
      await client.from('group_join_requests').insert({
        'group_id': groupId,
        'user_id': userId,
        'status': 'pending',
      });

      log('User $userId requested to join group $groupId');
    } catch (e, st) {
      log('GroupMembershipRepository.requestToJoinGroup exception: $e\n$st');
      rethrow;
    }
  }

  /// Admin approves a join request and adds user to group
  Future<void> approveJoinRequest({
    required String groupId,
    required String requestUserId,
    required String adminUserId,
  }) async {
    try {
      // Verify the admin has permission
      final memberData = await client
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', adminUserId)
          .maybeSingle();

      if (memberData == null || memberData['role'] != 'admin') {
        throw Exception('Only admins can approve join requests');
      }

      // Update the join request status
      final result = await client
          .from('group_join_requests')
          .update({
            'status': 'approved',
            'reviewed_by': adminUserId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('group_id', groupId)
          .eq('user_id', requestUserId)
          .eq('status', 'pending')
          .select();

      if (result.isEmpty) {
        throw Exception('Join request not found or already processed');
      }

      // Add user to group (includes FCM subscription)
      await joinGroup(groupId: groupId, userId: requestUserId);

      log(
        'Admin $adminUserId approved user $requestUserId to join group $groupId',
      );
    } catch (e, st) {
      log('GroupMembershipRepository.approveJoinRequest exception: $e\n$st');
      rethrow;
    }
  }

  /// Admin rejects a join request
  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestUserId,
    required String adminUserId,
  }) async {
    try {
      // Verify the admin has permission
      final memberData = await client
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', adminUserId)
          .maybeSingle();

      if (memberData == null || memberData['role'] != 'admin') {
        throw Exception('Only admins can reject join requests');
      }

      // Update the join request status
      final result = await client
          .from('group_join_requests')
          .update({
            'status': 'rejected',
            'reviewed_by': adminUserId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('group_id', groupId)
          .eq('user_id', requestUserId)
          .eq('status', 'pending')
          .select();

      if (result.isEmpty) {
        throw Exception('Join request not found or already processed');
      }

      log(
        'Admin $adminUserId rejected user $requestUserId from group $groupId',
      );
    } catch (e, st) {
      log('GroupMembershipRepository.rejectJoinRequest exception: $e\n$st');
      rethrow;
    }
  }

  /// Remove a member from the group (admin action)
  Future<void> removeMember({
    required String groupId,
    required String memberUserId,
    required String adminUserId,
  }) async {
    try {
      // Verify the admin has permission
      final adminData = await client
          .from('group_members')
          .select('role')
          .eq('group_id', groupId)
          .eq('user_id', adminUserId)
          .maybeSingle();

      if (adminData == null || adminData['role'] != 'admin') {
        throw Exception('Only admins can remove members');
      }

      // Get group info
      final groupData = await client
          .from('groups')
          .select('topic_id, created_by')
          .eq('id', groupId)
          .maybeSingle();

      if (groupData == null) {
        throw Exception('Group not found');
      }

      // Prevent removing the group creator
      if (groupData['created_by'] == memberUserId) {
        throw Exception('Cannot remove the group creator');
      }

      final topicId = groupData['topic_id'] as String;

      // Unsubscribe from FCM topic first
      try {
        await messaging.unsubscribeFromTopic(topicId);
        log('Member $memberUserId unsubscribed from topic: $topicId');
      } on Exception catch (e) {
        log('Failed to unsubscribe from FCM topic: $e');
      }

      // Remove the member from database
      final result = await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', memberUserId)
          .select();

      if (result.isEmpty) {
        throw Exception('Member not found in this group');
      }

      log(
        'Admin $adminUserId removed member $memberUserId from group $groupId',
      );
    } catch (e, st) {
      log('GroupMembershipRepository.removeMember exception: $e\n$st');
      rethrow;
    }
  }

  /// Subscribe to group's FCM topic after joining
  /// Can be used standalone if needed
  Future<void> subscribeToGroupTopicAfterJoin(String groupId) async {
    try {
      final groupData = await client
          .from('groups')
          .select('topic_id')
          .eq('id', groupId)
          .maybeSingle();

      if (groupData == null) {
        throw Exception('Group not found');
      }

      final topicId = groupData['topic_id'] as String;
      await messaging.subscribeToTopic(topicId);
      log('Subscribed to topic: $topicId');
    } catch (e, st) {
      log(
        'GroupMembershipRepository.subscribeToGroupTopicAfterJoin exception: $e\n$st',
      );
      rethrow;
    }
  }

  /// Unsubscribe from group's FCM topic before leaving
  /// Can be used standalone if needed
  Future<void> unsubscribeFromGroupTopicBeforeLeave(String groupId) async {
    try {
      final groupData = await client
          .from('groups')
          .select('topic_id')
          .eq('id', groupId)
          .maybeSingle();

      if (groupData == null) {
        log('Group not found when trying to unsubscribe');
        return;
      }

      final topicId = groupData['topic_id'] as String;
      await messaging.unsubscribeFromTopic(topicId);
      log('Unsubscribed from topic: $topicId');
    } on Exception catch (e, st) {
      log(
        'GroupMembershipRepository.unsubscribeFromGroupTopicBeforeLeave exception: $e\n$st',
      );
      // Don't rethrow - just log
    }
  }

  /// Validate invite code and return group_id if valid
  Future<String> validateInviteCode(String inviteCode) async {
    try {
      final inviteData = await client
          .from('group_invitations')
          .select('group_id, is_active, expires_at')
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (inviteData == null) {
        throw Exception('Invalid invite code');
      }

      if (inviteData['is_active'] != true) {
        throw Exception('This invite code is no longer active');
      }

      // Check if invite has expired
      final expiresAt = inviteData['expires_at'] as String?;
      if (expiresAt != null) {
        final expiryDate = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiryDate)) {
          throw Exception('This invite code has expired');
        }
      }

      return inviteData['group_id'] as String;
    } catch (e, st) {
      log('GroupMembershipRepository.validateInviteCode exception: $e\n$st');
      rethrow;
    }
  }

  /// Sync user's FCM topic subscriptions with their group memberships
  /// Call this on app startup or when FCM token is refreshed
  Future<void> syncTopicSubscriptions(String userId) async {
    try {
      // Get all groups the user is a member of
      final memberships = await client
          .from('group_members')
          .select('groups!inner(topic_id)')
          .eq('user_id', userId);

      // Subscribe to all group topics
      for (final membership in memberships) {
        final topicId = membership['groups']['topic_id'] as String;
        try {
          await messaging.subscribeToTopic(topicId);
          log('Synced subscription to topic: $topicId');
        } on Exception catch (e) {
          log('Failed to sync subscription to topic $topicId: $e');
        }
      }

      log('Synced ${memberships.length} topic subscriptions for user $userId');
    } catch (e, st) {
      log(
        'GroupMembershipRepository.syncTopicSubscriptions exception: $e\n$st',
      );
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
GroupMembershipRepository groupMembershipRepository(Ref ref) {
  return GroupMembershipRepository(
    ref.watch(supabaseProvider).client,
    FirebaseMessaging.instance,
  );
}
