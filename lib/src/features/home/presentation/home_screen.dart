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
                    final isAdmin = group.role == 'admin';

                    return Container(
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.yellow.withOpacity(0.15) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        onTap: () {
                          GroupDetailsRoute(
                            groupId: group.id,
                            groupName: group.name,
                            isPublic: group.isPublic,
                          ).push<void>(context);
                        },
                        leading: isAdmin
                            ? const Icon(Icons.verified, color: Colors.amber)
                            : const Icon(Icons.group_outlined),

                        title: Text(group.name),
                        subtitle: Text(
                          group.isPublic
                              ? 'Public • ${group.role}'
                              : 'Private • ${group.role}',
                        ),

                        trailing: isAdmin
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Group',
                                onPressed: () {
                                  ref
                                      .read(groupControllerProvider.notifier)
                                      .removeGroup(group.id);
                                },
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.grey,
                                ),
                                tooltip: 'Leave Group',
                                onPressed: () async {
                                  await ref
                                      .read(homeControllerProvider.notifier)
                                      .leaveGroup(group.id);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Left ${group.name}'),
                                    ),
                                  );
                                },
                              ),
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
                        onPressed: () async {
                          await ref
                              .read(homeControllerProvider.notifier)
                              .joinGroup(group.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Joined ${group.name}!')),
                          );
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
