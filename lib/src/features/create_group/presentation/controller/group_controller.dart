import 'dart:async';

import 'package:congregate/src/features/create_group/data/group_remote_repository.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
import 'package:congregate/src/router/app_router.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_controller.g.dart';

@Riverpod(keepAlive: true)
class GroupController extends _$GroupController {
  @override
  FutureOr<void> build() => null;

  Future<void> createGroup({
    required String name,
    required bool isPublic,
  }) async {
    state = const AsyncLoading();

    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final repo = ref.read(groupRemoteRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.createGroup(name: name, isPublic: isPublic, userId: userId),
    );

    final context = rootNavigatorKey.currentContext;
    if (!state.hasError && context != null && context.mounted) {
      unawaited(ref.read(homeControllerProvider.notifier).refresh());
      context.pop();
    }
  }

  Future<void> removeGroup(String groupId) async {
    state = const AsyncLoading();
    final repo = ref.read(groupRemoteRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repo.deleteGroup(groupId: groupId);
    });

    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    bool? isPublic,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(groupRemoteRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.updateGroup(
        groupId: groupId,
        name: name,
        isPublic: isPublic,
      ),
    );

    final context = rootNavigatorKey.currentContext;
    if (!state.hasError && context != null && context.mounted) {
      unawaited(ref.read(homeControllerProvider.notifier).refresh());
    }
  }
}
