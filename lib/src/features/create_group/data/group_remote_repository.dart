// ignore_for_file: avoid_dynamic_calls

import 'dart:developer';

import 'package:congregate/src/features/group_details/domain/group_member.dart';
import 'package:congregate/src/features/home/domain/group.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'group_remote_repository.g.dart';

class GroupRemoteRepository {
  GroupRemoteRepository(this.client);
  final SupabaseClient client;

  Future<Group> createGroup({
    required String name,
    required bool isPublic,
    required String userId,
  }) async {
    try {
      final groupId = const Uuid().v4();
      final topicId = 'group_$groupId';

      final response = await client
          .from('groups')
          .insert({
            'id': groupId,
            'name': name,
            'is_public': isPublic,
            'topic_id': topicId,
            'created_by': userId,
          })
          .select()
          .single();

      return Group.fromJson(response);
    } catch (e) {
      log('$e');
      throw Exception('GroupRemoteRepository Exception: $e');
    }
  }

  Future<bool> deleteGroup({required String groupId}) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final result = await client
          .from('groups')
          .delete()
          .eq('id', groupId)
          .select(); // return all deleted rows

      if (result.isEmpty) {
        throw Exception('No group deleted (maybe not owner or invalid id)');
      }

      return true;
    } catch (e, st) {
      log('GroupRemoteRepository.deleteGroup exception: $e\n$st');
      rethrow;
    }
  }

  Future<Group> updateGroup({
    required String groupId,
    String? name,
    bool? isPublic,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
      }
      if (isPublic != null) {
        updates['is_public'] = isPublic;
      }

      if (updates.isEmpty) {
        throw Exception('No fields to update');
      }

      final result = await client
          .from('groups')
          .update(updates)
          .eq('id', groupId)
          .select()
          .maybeSingle();

      if (result == null) {
        throw Exception(
          'Group not found or you do not have permission to update it',
        );
      }

      return Group.fromJson(result);
    } catch (e, st) {
      log('GroupRemoteRepository.updateGroup exception: $e\n$st');
      rethrow;
    }
  }

  Future<List<GroupMember>> fetchGroupMembers(String groupId) async {
    try {
      final response = await client
          .from('group_members')
          .select(
            'user_id, role, user_profiles(display_name, real_name, show_real_name)',
          )
          .eq('group_id', groupId);

      return (response as List<dynamic>).map((row) {
        final profile = row['user_profiles'] as Map<String, dynamic>?;

        final showRealName = profile?['show_real_name'] as bool? ?? false;

        final displayName = showRealName
            ? (profile?['real_name'] as String? ??
                  profile?['display_name'] as String? ??
                  'Unknown')
            : (profile?['display_name'] as String? ?? 'Unknown');

        return GroupMember(
          userId: row['user_id'] as String,
          role: row['role'] as String,
          displayName: displayName,
        );
      }).toList();
    } catch (e, st) {
      log(
        'GroupDetailsRemoteRepository.fetchGroupMembers ERROR: $e\n$st',
      );
      throw Exception('Failed to fetch group members: $e');
    }
  }
}

@Riverpod(keepAlive: true)
GroupRemoteRepository groupRemoteRepository(Ref ref) {
  return GroupRemoteRepository(ref.watch(supabaseProvider).client);
}
