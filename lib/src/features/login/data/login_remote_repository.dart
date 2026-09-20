import 'dart:developer';

import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginRemoteRepository {
  LoginRemoteRepository({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  static const _iosClientId =
      '1022876601447-g80h3ai35gcvu8qh44v6p8a6gl6r2srl.apps.googleusercontent.com';
  static const _webClientId =
      '1022876601447-tsunu79ppurr2if099ho7p5f09smh4pg.apps.googleusercontent.com';

  Future<AuthResponse> signInAnonymously() async {
    try {
      return await supabaseClient.auth.signInAnonymously();
    } catch (e) {
      throw Exception('signInAnonymously failed: $e');
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: _iosClientId,
        serverClientId: _webClientId,
      );

      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('Missing Google ID token');
      }
      if (accessToken == null) {
        throw Exception('Missing Google access token');
      }

      return await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      throw Exception('signInWithGoogle failed: $e');
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

      final response = await supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      log('fetchUserProfile error: $e');
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
          .upsert({'user_id': userId, ...updates})
          .select()
          .maybeSingle();

      return result == null ? null : UserProfile.fromJson(result);
    } catch (e, st) {
      log('LoginRemoteRepository.updateProfile exception: $e\n$st');
      rethrow;
    }
  }
}

final loginRemoteRepositoryProvider = Provider<LoginRemoteRepository>((ref) {
  return LoginRemoteRepository(
    supabaseClient: ref.watch(supabaseProvider).client,
  );
});
