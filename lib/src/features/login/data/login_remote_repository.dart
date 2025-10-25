import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginRemoteRepository {
  LoginRemoteRepository({required this.supabaseClient, required this.clientId})
    : googleSignIn = GoogleSignIn(
        clientId:
            '1022876601447-3p7l1qu23p52u0phmkhth0oa4ui8i3go.apps.googleusercontent.com',
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

      // final response = await supabaseClient
      //     .from(TableTitleConstants.profile)
      //     .select()
      //     .eq('id', userId)
      //     .single();

      // final userProfile = UserProfile.fromJson(response);

      // return userProfile;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
    return null;
  }

  Future<UserProfile?> updateProfile(
    String userId, {
    String? username,
    String? countryCode,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (username != null && username.trim().isNotEmpty) {
        updates['username'] = username;
      }

      if (countryCode != null && countryCode.trim().isNotEmpty) {
        updates['country_code'] = countryCode;
      }

      if (updates.isEmpty) {
        throw Exception('No valid fields to update.');
      }

      // await supabaseClient
      //     .from(TableTitleConstants.profile)
      //     .update(updates)
      //     .eq('id', userId);

      // return await fetchUserProfile();
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to update profile: $e');
    }
    return null;
  }
}

final loginRemoteRepositoryProvider = Provider<LoginRemoteRepository>((ref) {
  const clientId = String.fromEnvironment('IOS_CLIENT_ID');
  return LoginRemoteRepository(
    supabaseClient: ref.watch(supabaseProvider).client,
    clientId: clientId,
  );
});
