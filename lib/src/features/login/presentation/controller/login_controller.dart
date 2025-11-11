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

@Riverpod(keepAlive: true)
String? userId(Ref ref) {
  return ref.watch(supabaseProvider).client.auth.currentUser?.id;
}

@Riverpod(keepAlive: true)
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
      ref.invalidate(routerProvider);
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

  void setUpAuthListener() {
    ref.read(supabaseProvider).client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (data.session?.accessToken != null && !Platform.isMacOS) {
        await closeInAppWebView();
      }
      if (data.event == AuthChangeEvent.signedIn) {
        // await getAndCacheUserProfile();
      }
    });
  }
}
