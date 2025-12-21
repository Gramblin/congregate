import 'dart:developer';

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
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
  late final TextEditingController _realNameController;

  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _realNameController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _realNameController.dispose();
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
          if (_realNameController.text.isEmpty) {
            _realNameController.text = profile.realName ?? '';
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
                  gapH24,
                  // --- Real Name ---
                  Text(
                    'Real Name'.hardcoded,
                    style: context.textTheme.titleMedium,
                  ),
                  gapH8,
                  TextField(
                    controller: _realNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter real name'.hardcoded,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                  gapH24,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Show my real name to others'.hardcoded,
                          style: context.textTheme.bodyLarge,
                        ),
                      ),
                      Switch.adaptive(
                        value: profile.showRealName,
                        onChanged: (value) async {
                          await ref
                              .read(userProfileProvider.notifier)
                              .updateProfile(showRealName: value);
                        },
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
            realName: _realNameController.text.trim(),
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
