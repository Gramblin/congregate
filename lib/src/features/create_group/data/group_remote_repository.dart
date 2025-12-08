import 'dart:developer';

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

      // Insert will auto-add user as admin via trigger
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
}

@Riverpod(keepAlive: true)
GroupRemoteRepository groupRemoteRepository(Ref ref) {
  return GroupRemoteRepository(ref.watch(supabaseProvider).client);
}
