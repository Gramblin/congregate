import 'package:congregate/src/features/create_group/presentation/controller/group_controller.dart';
import 'package:congregate/src/features/group_details/presentation/controllers/group_members_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({
    required this.groupId,
    required this.groupName,
    required this.isPublic,
    super.key,
  });

  final String groupId;
  final String groupName;
  final bool isPublic;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  late TextEditingController _nameController;
  late bool _isPublic;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.groupName);
    _isPublic = widget.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Call your repository/controller method to update the group
      await ref
          .read(groupControllerProvider.notifier)
          .updateGroup(
            name: _nameController.text,
            isPublic: _isPublic,
            groupId: widget.groupId,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncMembers = ref.watch(
      groupMembersProvider(widget.groupId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: asyncMembers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('❌ $e')),
        data: (members) {
          final admins = members.where((m) => m.role == 'admin').toList();
          final regularUsers = members
              .where((m) => m.role == 'member')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Group Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Public'),
                        Switch(
                          value: _isPublic,
                          onChanged: (value) =>
                              setState(() => _isPublic = value),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                  ],
                ),
              ),

              // Admins section
              const Text(
                'Admins',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...admins.map(
                (m) => ListTile(
                  leading: const Icon(Icons.verified, color: Colors.amber),
                  title: Text(m.displayName),
                  subtitle: const Text('Group Admin'),
                ),
              ),
              const SizedBox(height: 16),

              // Members section
              const Text(
                'Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...regularUsers.map(
                (m) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(m.displayName),
                  subtitle: const Text('Member'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
