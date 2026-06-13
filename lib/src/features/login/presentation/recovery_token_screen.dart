import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/login/data/recovery_repository.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown once after profile setup. Generates and displays the user's
/// recovery token. They must explicitly confirm they've saved it.
class RecoveryTokenScreen extends ConsumerStatefulWidget {
  const RecoveryTokenScreen({super.key});

  @override
  ConsumerState<RecoveryTokenScreen> createState() =>
      _RecoveryTokenScreenState();
}

class _RecoveryTokenScreenState extends ConsumerState<RecoveryTokenScreen> {
  String? _token;
  bool _hasCopied = false;
  bool _confirmed = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _generate();
    });
  }

  Future<void> _generate() async {
    try {
      final token = await ref
          .read(recoveryRepositoryProvider)
          .generateAndSaveToken();
      if (mounted) setState(() { _token = token; _isLoading = false; });
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
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

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Save your recovery key'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(Sizes.p24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: () async {
                      setState(() { _isLoading = true; _error = null; });
                      await _generate();
                    })
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Sizes.p16),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(Sizes.p12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colorScheme.onErrorContainer,
                              ),
                              gapW12,
                              Expanded(
                                child: Text(
                                  'This key is shown ONCE and cannot be recovered. '
                                  'Save it somewhere safe (e.g. your notes app).',
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        gapH32,
                        Text(
                          'Your recovery key',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        gapH12,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Sizes.p20,
                            vertical: Sizes.p24,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(Sizes.p12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            _token ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        gapH16,
                        OutlinedButton.icon(
                          onPressed: _copy,
                          icon: Icon(
                            _hasCopied ? Icons.check : Icons.copy_outlined,
                          ),
                          label: Text(_hasCopied ? 'Copied!' : 'Copy to clipboard'),
                        ),
                        gapH32,
                        CheckboxListTile(
                          value: _confirmed,
                          onChanged: (v) =>
                              setState(() => _confirmed = v ?? false),
                          title: const Text(
                            'I have saved my recovery key in a safe place',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _confirmed
                              ? () => const HomeRoute().go(context)
                              : null,
                          child: const Text('Continue to app'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to generate key: $error'),
          gapH16,
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
