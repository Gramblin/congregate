import 'dart:developer';

import 'package:congregate/src/features/home/domain/group.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'home_remote_repository.g.dart';

class HomeRemoteRepository {
  HomeRemoteRepository(this._client);
  final SupabaseClient _client;

  Future<List<Group>> fetchUserGroups(String userId) async {
    try {
      final response = await _client
          .from('group_members')
          .select('groups(*), role')
          .eq('user_id', userId);

      final rawGroups = response as List;

      return rawGroups.map((row) {
        final groupJson = row['groups'] as Map<String, dynamic>;
        final role = row['role'] as String;

        return Group.fromJson(groupJson).copyWith(role: role);
      }).toList();
    } catch (e) {
      log('eee $e');
      throw Exception('HomeRemoteRepository Exception: $e');
    }
  }

  Future<List<Group>> fetchJoinableGroups(String userId) async {
    try {
      // 1) Fetch groups the user is already in
      final memberRows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final memberIds = memberRows
          .map<String>((row) => row['group_id'] as String)
          .toList();

      // 2) Fetch all public groups
      final publicRows = await _client
          .from('groups')
          .select()
          .eq('is_public', true);

      // 3) Remove the ones the user already joined
      final joinable = publicRows.where(
        (row) => !memberIds.contains(row['id']),
      );

      // 4) Convert to model
      return joinable.map(Group.fromJson).toList();
    } catch (e, st) {
      log('HomeRemoteRepository.fetchJoinableGroups Error: $e\n$st');
      throw Exception('HomeRemoteRepository Exception: $e');
    }
  }

  Future<void> joinGroup(String groupId, String userId) async {
    try {
      await _client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member',
        'show_real_name': false,
      });
    } catch (e) {
      log('HomeRemoteRepository.joinGroup Error: $e');
      throw Exception('Failed to join group: $e');
    }
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e) {
      log('HomeRemoteRepository.leaveGroup Error: $e');
      throw Exception('Failed to leave group: $e');
    }
  }
}

@Riverpod(keepAlive: true)
HomeRemoteRepository homeRemoteRepository(Ref ref) {
  final client = ref.watch(supabaseProvider);
  return HomeRemoteRepository(client.client);
}
