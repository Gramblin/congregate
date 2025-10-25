import 'package:congregate/src/features/create_group/presentation/controller/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _visibility = 'private';

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      groupControllerProvider,
      (prev, next) {
        if (next is AsyncError) {
          debugPrint('Group creation failed: ${next.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create group: ${next.error}')),
          );
        }
      },
    );

    final controller = ref.watch(groupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: const InputDecoration(labelText: 'Visibility'),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _visibility = value);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await ref
                        .read(groupControllerProvider.notifier)
                        .createGroup(
                          name: _nameController.text,
                          visibility: _visibility,
                        );
                  }
                },
                child: controller.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
