import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/login/data/recovery_repository.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  ConsumerState<AccountRecoveryScreen> createState() =>
      _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState
    extends ConsumerState<AccountRecoveryScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(recoveryRepositoryProvider)
          .recoverAccount(_controller.text.trim());

      // Reload profile for the recovered user
      await ref.read(userProfileProvider.notifier).refreshProfile();

      if (mounted) {
        context.showInformationToast('Account recovered successfully!');
        const HomeRoute().go(context);
      }
    } on Exception catch (e) {
      if (mounted) {
        context.showInformationToast(
          e.toString().replaceFirst('Exception: ', ''),
          error: SuccessTypeEnum.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recover account')),
      body: Padding(
        padding: const EdgeInsets.all(Sizes.p24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your recovery key',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              gapH8,
              Text(
                'Paste the key you saved when you first set up your account.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              gapH24,
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Recovery key',
                  hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your recovery key';
                  }
                  final normalized =
                      v.trim().replaceAll(RegExp(r'[\s\-]'), '');
                  if (normalized.length != 32) {
                    return 'Key must be 32 characters (dashes are ok)';
                  }
                  return null;
                },
              ),
              gapH32,
              FilledButton(
                onPressed: _isLoading ? null : _recover,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Recover account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
