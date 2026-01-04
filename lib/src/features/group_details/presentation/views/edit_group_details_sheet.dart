import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/presentation/controller/group_controller.dart';
import 'package:congregate/src/router/congregate_bottom_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditGroupDetailsSheet extends ConsumerStatefulWidget {
  const EditGroupDetailsSheet({
    required this.groupId,
    required this.groupName,
    required this.isPublic,
    super.key,
  });

  final String groupId;
  final String groupName;
  final bool isPublic;

  @override
  ConsumerState<EditGroupDetailsSheet> createState() =>
      _EditGroupDetailsSheetState();
}

class _EditGroupDetailsSheetState extends ConsumerState<EditGroupDetailsSheet> {
  late bool _isPublic;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(groupControllerProvider.notifier)
        .updateGroup(
          name: _nameController.text,
          isPublic: _isPublic,
          groupId: widget.groupId,
        );
  }

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.groupName);
    _isPublic = widget.isPublic;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CongregateBottomSheet(
      children: [
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Group Info'.hardcoded,
                        style: const TextStyle(
                          fontSize: Sizes.p20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      gapH16,
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      gapH16,
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
                      gapH16,
                      ElevatedButton(
                        onPressed: _saveChanges,
                        child: Row(
                          children: [
                            const Icon(Icons.save),
                            gapW16,
                            Text('Save'.hardcoded),
                          ],
                        ),
                      ),
                      gapH32,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
