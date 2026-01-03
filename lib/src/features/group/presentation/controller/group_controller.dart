import 'dart:async';

import 'package:congregate/src/features/group/data/group_invitations_remote_repository.dart';
import 'package:congregate/src/features/group/data/group_membership_remote_repository.dart';
import 'package:congregate/src/features/group/data/group_remote_repository.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
import 'package:congregate/src/router/app_router.dart';
import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

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
    if (context == null || !context.mounted) return;
    if (!state.hasError) {
      context.showInformationToast(
        'Group updated successfully',
        autoDismiss: true,
      );
      unawaited(ref.read(homeControllerProvider.notifier).refresh());
    } else {
      context.showInformationToast(
        'Failed to update group: ${state.error}',
      );
    }
  }

  Future<void> joinGroup(String groupId) async {
    state = const AsyncLoading();

    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final repo = ref.read(groupMembershipRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.joinGroup(groupId: groupId, userId: userId),
    );

    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> leaveGroup(String groupId) async {
    state = const AsyncLoading();

    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final repo = ref.read(groupMembershipRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.leaveGroup(groupId: groupId, userId: userId),
    );

    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> joinGroupViaInvite(String inviteCode) async {
    state = const AsyncLoading();

    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final repo = ref.read(groupMembershipRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.joinGroupViaInvite(inviteCode: inviteCode, userId: userId),
    );

    final context = rootNavigatorKey.currentContext;
    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
      if (context != null && context.mounted) {
        context.pop();
      }
    }
  }

  Future<void> requestToJoinGroup(String groupId) async {
    state = const AsyncLoading();

    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final repo = ref.read(groupMembershipRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.requestToJoinGroup(groupId: groupId, userId: userId),
    );

    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> approveJoinRequest({
    required String groupId,
    required String requestUserId,
  }) async {
    state = const AsyncLoading();

    final adminUserId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (adminUserId == null) throw Exception('User not logged in');

    final repo = ref.read(groupMembershipRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.approveJoinRequest(
        groupId: groupId,
        requestUserId: requestUserId,
        adminUserId: adminUserId,
      ),
    );

    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestUserId,
  }) async {
    state = const AsyncLoading();

    final adminUserId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (adminUserId == null) throw Exception('User not logged in');

    final repo = ref.read(groupMembershipRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.rejectJoinRequest(
        groupId: groupId,
        requestUserId: requestUserId,
        adminUserId: adminUserId,
      ),
    );

    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String memberUserId,
  }) async {
    state = const AsyncLoading();

    final adminUserId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (adminUserId == null) throw Exception('User not logged in');

    final repo = ref.read(groupMembershipRepositoryProvider);

    state = await AsyncValue.guard(
      () => repo.removeMember(
        groupId: groupId,
        memberUserId: memberUserId,
        adminUserId: adminUserId,
      ),
    );

    if (!state.hasError) {
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> createAndShareInvite({required String groupId}) async {
    final repo = ref.read(groupInvitationsRepositoryProvider);

    final invitation = await repo.createInvitation(
      groupId: groupId,
    );

    final inviteLink = 'congregate://invite/${invitation.inviteCode}';

    // Share the link (use share_plus package)
    await SharePlus.instance.share(
      ShareParams(text: 'Join my prayer group: $inviteLink'),
    );
  }
}
