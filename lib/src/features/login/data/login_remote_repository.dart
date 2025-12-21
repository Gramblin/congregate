import 'dart:developer';

import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginRemoteRepository {
  LoginRemoteRepository({required this.supabaseClient, required this.clientId})
    : googleSignIn = GoogleSignIn(
        clientId:
            '1022876601447-tsunu79ppurr2if099ho7p5f09smh4pg.apps.googleusercontent.com',
      );

  final SupabaseClient supabaseClient;
  final GoogleSignIn googleSignIn;
  final String clientId;

  Future<AuthResponse?> fetchGoogleLogin() async {
    try {
      final user = await googleSignIn.signIn();
      if (user == null) {
        return null;
      }

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('No Access Token found.');
      }

      if (idToken == null) {
        throw Exception('No ID Token found.');
      }

      return supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      log('e is $e');
      throw Exception('LoginRemoteRepository Exception: $e');
    }
  }

  Future<bool> fetchSignOut() async {
    try {
      await supabaseClient.auth.signOut();
      return true;
    } catch (e) {
      throw Exception('LoginRemoteRepository Exception: $e');
    }
  }

  Future<UserProfile?> fetchUserProfile() async {
    try {
      final user = supabaseClient.auth.currentUser;

      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final userId = user.id;

      final response = await supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      final userProfile = UserProfile.fromJson(response);
      log('e is $response');

      return userProfile;
    } catch (e) {
      log('e is $e');
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<UserProfile?> updateProfile(
    String userId, {
    String? displayName,
    String? realName,
    bool? showRealName,
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

      if (updates.isEmpty) {
        throw Exception('No valid fields to update.');
      }

      final result = await supabaseClient
          .from('user_profiles')
          .upsert({
            'user_id': userId,
            ...updates,
          })
          .select()
          .maybeSingle();

      return result == null ? null : UserProfile.fromJson(result);
    } catch (e, st) {
      log('UserProfileRemoteRepository.updateProfile exception: $e\n$st');
      rethrow;
    }
  }
}

final loginRemoteRepositoryProvider = Provider<LoginRemoteRepository>((ref) {
  const clientId = String.fromEnvironment('IOS_CLIENT_ID');
  return LoginRemoteRepository(
    supabaseClient: ref.watch(supabaseProvider).client,
    clientId: clientId,
  );
});
