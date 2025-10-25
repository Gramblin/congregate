import 'package:congregate/src/features/create_group/presentation/controller/group_controller.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroups = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: asyncGroups.when(
        data: (groups) => groups.isEmpty
            ? const Center(child: Text("You're not in any groups yet."))
            : ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    title: Text(group.name),
                    subtitle: Text(group.visibility),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        ref
                            .read(groupControllerProvider.notifier)
                            .removeGroup(group.id);
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          return Center(child: Text('❌ Error: $e'));
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
