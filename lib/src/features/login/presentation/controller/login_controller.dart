import 'dart:convert';
import 'dart:io';

import 'package:congregate/src/features/login/data/login_remote_repository.dart';
import 'package:congregate/src/router/app_router.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

part 'login_controller.g.dart';

@riverpod
Stream<AuthState> userStream(Ref ref) {
  return ref.watch(supabaseProvider).client.auth.onAuthStateChange;
}

@riverpod
String? userId(Ref ref) {
  return ref.watch(supabaseProvider).client.auth.currentUser?.id;
}

@riverpod
class LoginController extends _$LoginController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> logInUsingGoogle() async {
    state = const AsyncLoading();
    final repository = ref.read(loginRemoteRepositoryProvider);
    setUpAuthListener();
    await ref.read(preferencesProvider).remove('user_profile');

    final result = await AsyncValue.guard(repository.fetchGoogleLogin);
    ref.read(userIdProvider);
    if (!result.hasError) {
      state = const AsyncData(null);
    } else {
      state = AsyncError(result.error!, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    final repository = ref.read(loginRemoteRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(repository.fetchSignOut);
    if (!result.hasError) {
      await ref.read(preferencesProvider).remove('user_profile');
      ref.read(routerProvider).refresh();
      state = const AsyncValue.data(null);
    } else {
      state = AsyncError(result.error!, StackTrace.current);
    }
  }

  Future<void> updateUserProfile({
    String? username,
    String? countryCode,
    bool showToast = true,
  }) async {
    final user = ref.read(supabaseProvider).client.auth.currentUser;
    if (user == null) throw Exception('User is not logged in.');

    final repository = ref.read(loginRemoteRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => repository.updateProfile(
        user.id,
        username: username,
        countryCode: countryCode,
      ),
    );

    final context = rootNavigatorKey.currentContext;
    if (!result.hasError) {
      state = const AsyncValue.data(null);
      if (context != null && context.mounted && showToast) {
        // Show success toast if needed
      }
    } else {
      if (context != null && context.mounted) {
        state = AsyncError(result.error!, StackTrace.current);
        // Show error toast if needed
      }
    }
  }

  void setUpAuthListener() {
    ref.read(supabaseProvider).client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (data.session?.accessToken != null && !Platform.isMacOS) {
        await closeInAppWebView();
      }
      if (data.event == AuthChangeEvent.signedIn) {
        await getAndCacheUserProfile();
      }
    });
  }

  Future<void> getAndCacheUserProfile() async {
    state = const AsyncLoading();
    final repository = ref.read(loginRemoteRepositoryProvider);
    final userProfileResult = await AsyncValue.guard(
      repository.fetchUserProfile,
    );
    if (!userProfileResult.hasError && userProfileResult.value != null) {
      // await cacheUserProfile(userProfileResult.value);
      state = const AsyncValue.data(null);
      ref.read(routerProvider).refresh();
    } else {
      state = AsyncError(userProfileResult.error!, StackTrace.current);
    }
  }

  Future<void> cacheUserProfile(UserProfile profile) async {
    ref.read(userProfileProvider.notifier).state = profile;
    final prefs = ref.read(preferencesProvider);
    final jsonString = jsonEncode(profile);
    await prefs.setString('user_profile', jsonString);
  }
}

@riverpod
class UserProfile extends _$UserProfile {
  @override
  UserProfile? build() => throw UnimplementedError();
}
