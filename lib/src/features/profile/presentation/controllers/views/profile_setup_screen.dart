import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/login/presentation/controller/login_controller.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final displayNameCtrl = TextEditingController();
  final realNameCtrl = TextEditingController();
  bool showRealName = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        leading: BackButton(
          onPressed: () {
            ref.read(loginControllerProvider.notifier).signOut();
            context.pop();
          },
        ),
      ),
      body: profileAsync.when(
        data: (_) => Padding(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Column(
            children: [
              TextField(
                controller: displayNameCtrl,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              gapH16,
              TextField(
                controller: realNameCtrl,
                decoration: const InputDecoration(labelText: 'Real name'),
              ),
              gapH16,
              SwitchListTile(
                title: const Text('Show real name publicly'),
                value: showRealName,
                onChanged: (v) => setState(() => showRealName = v),
              ),
              gapH32,
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(userProfileProvider.notifier)
                      .updateProfile(
                        displayName: displayNameCtrl.text,
                        realName: realNameCtrl.text,
                        showRealName: showRealName,
                      );

                  if (context.mounted) {
                    const HomeRoute().pushReplacement(context);
                  }
                },
                child: const Text('Save & Continue'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
