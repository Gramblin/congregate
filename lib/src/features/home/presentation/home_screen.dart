import 'package:congregate/src/features/create_group/presentation/controller/group_controller.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
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
        title: const Text('My Groups'),
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
                // --------------------------
                // 🔹 USER GROUPS SECTION
                // --------------------------
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your Groups',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                if (userGroups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('You’re not in any groups yet.'),
                  )
                else
                  ...userGroups.map((group) {
                    return ListTile(
                      title: Text(group.name),
                      subtitle: Text(group.isPublic ? 'Public' : 'Private'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          ref
                              .read(groupControllerProvider.notifier)
                              .removeGroup(group.id);
                        },
                      ),
                    );
                  }),

                const Divider(height: 40),

                // --------------------------
                // 🔹 JOINABLE GROUPS SECTION
                // --------------------------
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Joinable Groups',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                if (joinableGroups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('No public groups available to join.'),
                  )
                else
                  ...joinableGroups.map((group) {
                    return ListTile(
                      title: Text(group.name),
                      subtitle: const Text('Public'),
                      trailing: IconButton(
                        icon: const Icon(Icons.login),
                        onPressed: () {
                          // ref
                          //     .read(groupControllerProvider.notifier)
                          //     .joinGroup(group.id);
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          const CreateGroupRoute().push<void>(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
