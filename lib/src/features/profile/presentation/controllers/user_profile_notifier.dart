import 'dart:convert';

import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/features/profile/data/user_profile_remote_repository.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_profile_notifier.g.dart';

@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
  static const _cacheKey = 'cached_user_profile';

  @override
  Future<UserProfile?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return UserProfile.fromJson(json);
      } on Exception catch (_) {}
    }

    final user = ref.read(supabaseProvider).client.auth.currentUser;
    if (user == null) return null;

    final repo = ref.read(userProfileRemoteRepositoryProvider);
    final profile = await repo.fetchProfile(user.id);

    if (profile != null) {
      await _cacheProfile(profile);
    }

    return profile;
  }

  Future<void> updateProfile({
    String? displayName,
    String? realName,
    bool? showRealName,
  }) async {
    final user = ref.read(supabaseProvider).client.auth.currentUser;
    if (user == null) throw Exception('User not logged in.');

    state = const AsyncLoading();

    final repo = ref.read(userProfileRemoteRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repo.updateProfile(
        user.id,
        displayName: displayName,
        realName: realName,
        showRealName: showRealName,
      ),
    );

    if (!result.hasError && result.value != null) {
      await _cacheProfile(result.value!);
    }

    state = result;
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(profile.toJson()));
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
