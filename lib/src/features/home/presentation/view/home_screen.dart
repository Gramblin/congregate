import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
import 'package:congregate/src/features/home/presentation/view/group_tile.dart';
import 'package:congregate/src/features/login/presentation/controller/login_controller.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeControllerProvider);
    final controller = ref.watch(homeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Congregate'),
        leading: IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => const ProfileRoute().push<void>(context),
          tooltip: 'Account'.hardcoded,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.waving_hand_outlined),
            onPressed: ref.read(loginControllerProvider.notifier).signOut,
            tooltip: 'Sign out'.hardcoded,
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('❌ Error: $e')),
        data: (state) {
          final userGroups = state.userGroups;
          final joinableGroups = state.joinableGroups;

          return RefreshIndicator(
            onRefresh: () async {
              await controller.refreshUserGroups();
              await controller.loadJoinableGroups();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Padding(
                  padding: const EdgeInsets.all(Sizes.p16),
                  child: Text(
                    'Your Groups'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (userGroups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Sizes.p16,
                      vertical: Sizes.p8,
                    ),
                    child: Text('You’re not in any groups yet.'),
                  )
                else
                  ...userGroups.map((group) {
                    final isAdmin = group.role == 'admin';
                    return GroupTile(
                      isAdmin: isAdmin,
                      group: group,
                      hasJoined: true,
                    );
                  }),
                const Divider(height: 40),
                Padding(
                  padding: const EdgeInsets.all(Sizes.p16),
                  child: Text(
                    'Available Groups'.hardcoded,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (joinableGroups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Sizes.p16,
                      vertical: Sizes.p8,
                    ),
                    child: Text('No public groups available to join.'),
                  )
                else
                  ...joinableGroups.map((group) {
                    return GroupTile(isAdmin: false, group: group);
                  }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () =>
                const JoinGroupModalSheetRoute().push<void>(context),
            heroTag: 'join_group',
            icon: const Icon(Icons.login),
            label: Text('Join group'.hardcoded),
          ),
          gapH8,
          FloatingActionButton.extended(
            onPressed: () =>
                const CreateGroupModalSheetRoute().push<void>(context),
            heroTag: 'create_group',
            icon: const Icon(Icons.add),
            label: Text('New group'.hardcoded),
          ),
        ],
      ),
    );
  }
}
