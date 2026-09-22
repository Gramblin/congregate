import 'dart:io';

import 'package:congregate/src/features/login/presentation/controller/login_controller.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(loginControllerProvider, (_, next) {
      if (next is AsyncError) {
        context.showInformationToast(
          next.error.toString(),
          error: SuccessTypeEnum.error,
        );
      }
    });

    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState is AsyncLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Welcome to Congregate',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (isLoading) const CircularProgressIndicator(),
              if (!isLoading) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => ref
                        .read(loginControllerProvider.notifier)
                        .signInWithGoogle(),
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => ref
                          .read(loginControllerProvider.notifier)
                          .signInWithApple(),
                      icon: const Icon(Icons.apple),
                      label: const Text('Continue with Apple'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(loginControllerProvider.notifier)
                        .signInAnonymously(),
                    child: const Text('Continue as guest'),
                  ),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    const AccountRecoveryRoute().push<void>(context),
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('Recover existing account'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
