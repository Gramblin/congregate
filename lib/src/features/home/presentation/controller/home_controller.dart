import 'package:congregate/src/features/group/data/group_membership_remote_repository.dart';
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

  Future<void> joinGroup(String groupId) async {
    final supabase = ref.read(supabaseProvider).client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final homeRepository = ref.read(homeRemoteRepositoryProvider);
    final groupMembershipRepository = ref.read(
      groupMembershipRepositoryProvider,
    );

    // 1. Insert into group_members
    await groupMembershipRepository.joinGroup(
      groupId: groupId,
      userId: user.id,
    );

    // 2. Refresh user groups + joinable groups
    final updatedUserGroups = await homeRepository.fetchUserGroups(user.id);
    final updatedJoinableGroups = await homeRepository.fetchJoinableGroups(
      user.id,
    );

    // 3. Update UI state
    state = AsyncData(
      HomeState(
        userGroups: updatedUserGroups,
        joinableGroups: updatedJoinableGroups,
      ),
    );
  }

  Future<void> leaveGroup(String groupId) async {
    final supabase = ref.read(supabaseProvider).client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final groupMembershipRepo = ref.read(groupMembershipRepositoryProvider);
    final homeRepo = ref.read(homeRemoteRepositoryProvider);

    // 1. Leave the group
    await groupMembershipRepo.leaveGroup(groupId: groupId, userId: user.id);

    // 2. Reload both lists
    final updatedUserGroups = await homeRepo.fetchUserGroups(user.id);
    final updatedJoinableGroups = await homeRepo.fetchJoinableGroups(user.id);

    // 3. Update state
    state = AsyncData(
      HomeState(
        userGroups: updatedUserGroups,
        joinableGroups: updatedJoinableGroups,
      ),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
