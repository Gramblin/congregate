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

  Future<List<Group>> fetchJoinableGroups(
    String userId, {
    String? country,
    String? city,
  }) async {
    try {
      final memberRows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final memberIds = memberRows
          .map<String>((row) => row['group_id'] as String)
          .toList();

      var query = _client
          .from('groups')
          .select()
          .eq('is_public', true)
          .eq('approval_status', 'approved');

      if (country != null) query = query.eq('country', country);
      if (city != null && city.isNotEmpty) query = query.eq('city', city);

      final publicRows = await query;

      final joinable = publicRows.where(
        (row) => !memberIds.contains(row['id']),
      );

      return joinable.map(Group.fromJson).toList();
    } catch (e, st) {
      log('HomeRemoteRepository.fetchJoinableGroups Error: $e\n$st');
      throw Exception('HomeRemoteRepository Exception: $e');
    }
  }

  /// Upcoming events from all groups the user has joined, sorted by time.
  Future<List<Map<String, dynamic>>> fetchUserFeedEvents(String userId) async {
    try {
      final memberRows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (memberRows as List)
          .map<String>((r) => r['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) return [];

      final rows = await _client
          .from('group_events')
          .select('*, groups(id, name)')
          .inFilter('group_id', groupIds)
          .gte('prayer_datetime', DateTime.now().toUtc().toIso8601String())
          .order('prayer_datetime');

      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      log('HomeRemoteRepository.fetchUserFeedEvents error: $e\n$st');
      throw Exception('HomeRemoteRepository Exception: $e');
    }
  }
}

@Riverpod(keepAlive: true)
HomeRemoteRepository homeRemoteRepository(Ref ref) {
  final client = ref.watch(supabaseProvider);
  return HomeRemoteRepository(client.client);
}
