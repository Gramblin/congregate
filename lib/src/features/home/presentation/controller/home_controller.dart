import 'package:congregate/src/features/home/data/home_remote_repository.dart';
import 'package:congregate/src/features/home/domain/home_state.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_controller.g.dart';

@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  @override
  Future<HomeState> build() async {
    final supabase = ref.watch(supabaseProvider).client;
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final repo = ref.watch(homeRemoteRepositoryProvider);

    final userGroups = await repo.fetchUserGroups(user.id);

    return HomeState(
      userGroups: userGroups,
      joinableGroups: const [],
    );
  }

  Future<void> refreshUserGroups() async {
    final supabase = ref.watch(supabaseProvider).client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final repo = ref.watch(homeRemoteRepositoryProvider);

    state = const AsyncLoading();
    final value = await AsyncValue.guard(() async {
      final userGroups = await repo.fetchUserGroups(user.id);
      return state.value!.copyWith(userGroups: userGroups);
    });

    state = value;
  }

  Future<void> loadJoinableGroups() async {
    final supabase = ref.watch(supabaseProvider).client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final repo = ref.watch(homeRemoteRepositoryProvider);

    // Keep the UI responsive: don't change state to loading → only replace joinableGroups
    final result = await AsyncValue.guard(
      () => repo.fetchJoinableGroups(user.id),
    );

    result.when(
      data: (groups) {
        final old = state.value;
        if (old != null) {
          state = AsyncData(
            old.copyWith(joinableGroups: groups),
          );
        }
      },
      error: (e, st) {},
      loading: () {},
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
