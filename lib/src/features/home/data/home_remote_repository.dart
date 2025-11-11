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
          .select('groups(*)')
          .eq('user_id', userId);

      final rawGroups = response as List;

      return rawGroups
          .map((e) => Group.fromJson(e['groups'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('HomeRemoteRepository Exception: $e');
    }
  }
}

@Riverpod(keepAlive: true)
HomeRemoteRepository homeRemoteRepository(Ref ref) {
  final client = ref.watch(supabaseProvider);
  return HomeRemoteRepository(client.client);
}
