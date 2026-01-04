import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/presentation/controller/group_controller.dart';
import 'package:congregate/src/router/congregate_bottom_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharePrivateGroupSheet extends ConsumerStatefulWidget {
  const SharePrivateGroupSheet({
    required this.groupId,
    super.key,
  });

  final String groupId;

  @override
  ConsumerState<SharePrivateGroupSheet> createState() =>
      _SharePrivateGroupSheetState();
}

class _SharePrivateGroupSheetState
    extends ConsumerState<SharePrivateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController(text: '5');

  Future<void> _createAndShareInvite() async {
    if (!_formKey.currentState!.validate()) return;

    // Call the controller method
    final limit = int.parse(_limitController.text.trim());
    await ref
        .read(groupControllerProvider.notifier)
        .createAndShareInvite(
          groupId: widget.groupId,
          maxUses: limit,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite created and ready to share!'.hardcoded),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupControllerProvider);

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
                Text(
                  'Share Group Invite'.hardcoded,
                  style: const TextStyle(
                    fontSize: Sizes.p20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH16,
                Text(
                  'Create an invite link to share with friends'.hardcoded,
                  style: TextStyle(
                    fontSize: Sizes.p14,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                gapH24,
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum number of people'.hardcoded,
                        style: const TextStyle(
                          fontSize: Sizes.p16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      gapH8,
                      TextFormField(
                        controller: _limitController,
                        decoration: const InputDecoration(
                          labelText: 'Number of invites',
                          hintText: 'e.g., 5',
                          prefixIcon: Icon(Icons.people),
                          helperText:
                              'How many people can use this invite link',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a number';
                          }
                          final number = int.tryParse(value.trim());
                          if (number == null || number <= 0) {
                            return 'Please enter a valid number greater than 0';
                          }
                          if (number > 100) {
                            return 'Maximum limit is 100';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                gapH24,
                Row(
                  spacing: Sizes.p12,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text('Cancel'.hardcoded),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.isLoading
                            ? null
                            : _createAndShareInvite,
                        child: state.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Create Invite'.hardcoded),
                      ),
                    ),
                  ],
                ),
                gapH16,
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }
}
