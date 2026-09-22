import 'package:congregate/src/features/login/data/login_remote_repository.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/router/app_router.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();

    final repository = ref.read(loginRemoteRepositoryProvider);
    await ref.read(userProfileProvider.notifier).clearCache();

    final result = await AsyncValue.guard(repository.signInAnonymously);

    if (!result.hasError) {
      await ref.read(userProfileProvider.notifier).refreshProfile();
      state = const AsyncData(null);
      ref.invalidate(routerProvider);
    } else {
      state = AsyncError(result.error!, StackTrace.current);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();

    final repository = ref.read(loginRemoteRepositoryProvider);
    await ref.read(userProfileProvider.notifier).clearCache();

    final result = await AsyncValue.guard(repository.signInWithGoogle);

    if (!result.hasError) {
      await ref.read(userProfileProvider.notifier).refreshProfile();
      state = const AsyncData(null);
      ref.invalidate(routerProvider);
    } else {
      state = AsyncError(result.error!, StackTrace.current);
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();

    final repository = ref.read(loginRemoteRepositoryProvider);
    await ref.read(userProfileProvider.notifier).clearCache();

    final result = await AsyncValue.guard(repository.signInWithApple);

    if (!result.hasError) {
      await ref.read(userProfileProvider.notifier).refreshProfile();
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
}
