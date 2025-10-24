import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:congregate/src/features/login/data/login_remote_repository.dart';
import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/router/app_router.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginController extends Notifier<AsyncValue<void>> {
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
    log('message $username ${countryCode}s ');
    final user = ref.read(supabaseProvider).client.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

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
      // await cacheUserProfile(result.value);

      if (context != null && context.mounted && showToast) {
        // final message = (username != null && countryCode == null)
        //     ? LocaleKeys.usernameUpdated.tr()
        //     : (countryCode != null && username == null)
        //     ? LocaleKeys.countryUpdated.tr()
        //     : LocaleKeys.profileUpdated.tr();

        // context.showInformationToast(message.hardcoded, autoDismiss: true);
      }
    } else {
      log('errrrr is $result');
      if (context != null && context.mounted) {
        state = AsyncError(result.error!, StackTrace.current);
        // context.showSnackbar(LocaleKeys.anErrorOcurredLabel.tr());
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
    final jsonString = jsonEncode(profile.toJson());
    await prefs.setString('user_profile', jsonString);
  }
}

final userStream = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseProvider).client.auth.onAuthStateChange,
);

final userIdProvider = StateProvider<String?>((ref) {
  return ref.watch(supabaseProvider).client.auth.currentUser?.id;
});

final loginControllerProvider =
    NotifierProvider<LoginController, AsyncValue<void>>(LoginController.new);

final userProfileProvider = StateProvider<UserProfile?>(
  (ref) => throw UnimplementedError(),
);
