import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _realNameCtrl = TextEditingController();
  bool _showRealName = true;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _realNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _showRealName
        ? _realNameCtrl.text.trim()
        : _displayNameCtrl.text.trim();

    await ref.read(userProfileProvider.notifier).createProfile(
          displayName: displayName,
          realName: _realNameCtrl.text.trim().isEmpty
              ? null
              : _realNameCtrl.text.trim(),
          showRealName: _showRealName,
        );

    if (mounted) {
      const RecoveryTokenRoute().pushReplacement(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(userProfileProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Sizes.p16),
          children: [
            gapH16,
            SwitchListTile(
              title: const Text('Show my real name publicly'),
              subtitle: Text(
                _showRealName
                    ? 'Group members will see your real name'
                    : 'Group members will see your display name',
              ),
              value: _showRealName,
              onChanged: (v) => setState(() => _showRealName = v),
              contentPadding: EdgeInsets.zero,
            ),
            gapH24,
            TextFormField(
              controller: _realNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Real name',
                hintText: 'e.g. Abdullah Al-Farsi',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: _showRealName
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? 'Real name is required' : null
                  : null,
            ),
            if (!_showRealName) ...[
              gapH16,
              TextFormField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'e.g. Abu Bakr',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Display name is required' : null,
              ),
            ],
            gapH32,
            FilledButton(
              onPressed: isLoading ? null : _save,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
