import 'dart:developer';

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/login/data/recovery_repository.dart';
import 'package:congregate/src/features/login/presentation/controller/login_controller.dart';
import 'package:congregate/src/features/profile/data/profile_stats_repository.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/router/scaffold_with_nav_bar.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
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

    return BottomNavScaffold(child: Scaffold(
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
          if (_realNameController.text.isEmpty) {
            _realNameController.text = profile.realName ?? '';
          }

          final shareLink = 'https://congregate.app/profile/${profile.userId}';

          final userId = ref.watch(supabaseProvider).client.auth.currentUser?.id;
          final statsAsync = userId != null
              ? ref.watch(userStatsProvider(userId))
              : null;

          return Padding(
            padding: const EdgeInsets.all(Sizes.p16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Impact Level ---
                  if (statsAsync != null)
                    statsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => _LevelCard(stats: stats),
                    ),
                  if (statsAsync != null) gapH24,
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
                  gapH24,
                  const Divider(),
                  gapH8,
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.key_outlined),
                    title: const Text('Recovery key'),
                    subtitle: const Text(
                      'Generate a new key to recover your account after reinstall',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRecoveryKeySheet(context),
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
    ));
  }

  Future<void> _showRecoveryKeySheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RecoveryKeySheet(ref: ref),
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.stats});
  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final level = stats.level;
    final nextAt = level.nextLevelAt();
    final progress = nextAt == -1
        ? 1.0
        : (stats.eventsAttended - level.min) /
            (nextAt - level.min).clamp(1, 999999);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  level.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${level.number} · ${level.title}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.p16,
                        ),
                      ),
                      Text(
                        level.subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            gapH12,
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              borderRadius: BorderRadius.circular(4),
            ),
            gapH8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatChip(
                  icon: Icons.event_available,
                  label: '${stats.eventsAttended} prayers joined',
                ),
                _StatChip(
                  icon: Icons.group_outlined,
                  label: '${stats.communitiesJoined} communities',
                ),
              ],
            ),
            if (nextAt != -1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${nextAt - stats.eventsAttended} more to reach ${CommunityLevel.values[level.number].title}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        gapW4,
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
