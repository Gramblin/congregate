import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/router/congregate_bottom_sheet.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinGroupSheet extends ConsumerStatefulWidget {
  const JoinGroupSheet({super.key});

  @override
  ConsumerState<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends ConsumerState<JoinGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join a private group'.hardcoded,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                gapH16,
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _inviteCodeController,
                        decoration: InputDecoration(
                          labelText: 'Invite code'.hardcoded,
                          hintText: 'Enter the invite code'.hardcoded,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an invite code'.hardcoded;
                          }
                          return null;
                        },
                      ),
                      gapH32,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Navigator.of(context).pop();
                              GroupInviteRoute(
                                inviteCode: _inviteCodeController.text.trim(),
                              ).push<void>(context);
                            }
                          },
                          child: Text('Join'.hardcoded),
                        ),
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
