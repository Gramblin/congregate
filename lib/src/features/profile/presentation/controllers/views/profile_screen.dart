import 'dart:developer';

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/login/data/recovery_repository.dart';
import 'package:congregate/src/features/login/presentation/controller/login_controller.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _displayNameController;

  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'.hardcoded),
        actions: [
          if (_hasChanges && !_isSaving)
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Save'.hardcoded,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: ref.read(loginControllerProvider.notifier).signOut,
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }

          if (_displayNameController.text.isEmpty) {
            _displayNameController.text = profile.displayName;
          }

          final shareLink = 'https://congregate.app/profile/${profile.userId}';

          return Padding(
            padding: const EdgeInsets.all(Sizes.p16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Display Name ---
                  Text(
                    'Display Name'.hardcoded,
                    style: context.textTheme.titleMedium,
                  ),
                  gapH8,
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter display name'.hardcoded,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                  gapH16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Dark mode'.hardcoded,
                          style: context.textTheme.bodyLarge,
                        ),
                      ),
                      Switch.adaptive(
                        value: ref.watch(themeModeProvider) == ThemeMode.dark,
                        onChanged: (_) =>
                            ref.read(themeModeProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                  gapH32,
                  // --- Share Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Sizes.p16,
                          horizontal: Sizes.p24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Sizes.p12),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Check out my Congregate profile: $shareLink',
                            ),
                          );
                        } on Exception catch (_) {
                          await Clipboard.setData(
                            ClipboardData(text: shareLink),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile link copied!'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: Text('Share Profile'.hardcoded),
                    ),
                  ),
                  if (_isSaving) ...[
                    gapH16,
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(userProfileProvider.notifier)
          .updateProfile(
            displayName: _displayNameController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
      setState(() {
        _hasChanges = false;
      });
    } on Exception catch (e, st) {
      log('saveChanges error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _RecoveryKeySheet extends StatefulWidget {
  const _RecoveryKeySheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_RecoveryKeySheet> createState() => _RecoveryKeySheetState();
}

class _RecoveryKeySheetState extends State<_RecoveryKeySheet> {
  String? _token;
  bool _hasCopied = false;
  bool _isLoading = false;

  Future<void> _generate() async {
    setState(() { _isLoading = true; _hasCopied = false; _token = null; });
    try {
      final token = await widget.ref
          .read(recoveryRepositoryProvider)
          .generateAndSaveToken();
      if (mounted) setState(() { _token = token; _isLoading = false; });
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _copy() async {
    if (_token == null) return;
    await Clipboard.setData(ClipboardData(text: _token!));
    if (mounted) setState(() => _hasCopied = true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.key_outlined),
              gapW12,
              Text(
                'Recovery key',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          gapH16,
          Text(
            'Generate a new key to save. This replaces your previous key '
            '— the old one will stop working immediately.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          gapH24,
          if (_token != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                _token!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            gapH12,
            OutlinedButton.icon(
              onPressed: _copy,
              icon: Icon(_hasCopied ? Icons.check : Icons.copy_outlined),
              label: Text(_hasCopied ? 'Copied!' : 'Copy key'),
            ),
            gapH8,
            Text(
              'Save this now — it cannot be shown again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            gapH16,
          ],
          FilledButton(
            onPressed: _isLoading ? null : _generate,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_token == null ? 'Generate key' : 'Generate new key'),
          ),
        ],
      ),
    );
  }
}

