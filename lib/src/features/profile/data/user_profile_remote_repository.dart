import 'dart:developer';

import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_profile_remote_repository.g.dart';

@Riverpod(keepAlive: true)
UserProfileRemoteRepository userProfileRemoteRepository(Ref ref) {
  return UserProfileRemoteRepository(ref.watch(supabaseProvider).client);
}

class UserProfileRemoteRepository {
  UserProfileRemoteRepository(this.supabaseClient);
  final SupabaseClient supabaseClient;

  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final response = await supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } on Exception catch (e, st) {
      log('UserProfileRemoteRepository.fetchProfile exception: $e\n$st');
      return null;
    }
  }

  Future<UserProfile> createProfile({
    required String userId,
    required String displayName,
    String? realName,
    bool showRealName = false,
    String? country,
    String? city,
  }) async {
    try {
      final result = await supabaseClient
          .from('user_profiles')
          .insert({
            'user_id': userId,
            'display_name': displayName,
            'real_name': realName,
            'show_real_name': showRealName,
            if (country != null) 'country': country,
            if (city != null) 'city': city,
          })
          .select()
          .single();

      return UserProfile.fromJson(result);
    } catch (e, st) {
      log('UserProfileRemoteRepository.createProfile exception: $e\n$st');
      rethrow;
    }
  }

  Future<UserProfile?> updateProfile(
    String userId, {
    String? displayName,
    String? realName,
    bool? showRealName,
    String? country,
    String? city,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (displayName != null && displayName.trim().isNotEmpty) {
        updates['display_name'] = displayName;
      }
      if (realName != null && realName.trim().isNotEmpty) {
        updates['real_name'] = realName;
      }
      if (showRealName != null) {
        updates['show_real_name'] = showRealName;
      }
      if (country != null) updates['country'] = country;
      if (city != null) updates['city'] = city;

      if (updates.isEmpty) {
        throw Exception('No valid fields to update.');
      }

      final result = await supabaseClient
          .from('user_profiles')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      return UserProfile.fromJson(result);
    } catch (e, st) {
      log('UserProfileRemoteRepository.updateProfile exception: $e\n$st');
      rethrow;
    }
  }
}
