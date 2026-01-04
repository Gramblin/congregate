import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/presentation/controller/group_controller.dart';
import 'package:congregate/src/router/congregate_bottom_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isPublic = false;

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

    return CongregateBottomSheet(
      children: [
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Group name'.hardcoded,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      gapH16,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Public'.hardcoded),
                          Switch(
                            value: _isPublic,
                            onChanged: (value) {
                              setState(() => _isPublic = value);
                            },
                          ),
                        ],
                      ),
                      gapH32,
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await ref
                                .read(groupControllerProvider.notifier)
                                .createGroup(
                                  name: _nameController.text,
                                  isPublic: _isPublic,
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
                gapH32,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
