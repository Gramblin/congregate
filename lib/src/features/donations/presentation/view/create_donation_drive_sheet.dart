import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/donations/presentation/controller/donation_drive_controller.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kCurrencies = ['USD', 'GBP', 'EUR', 'SAR', 'AED', 'CAD', 'AUD'];

class CreateDonationDriveSheet extends ConsumerStatefulWidget {
  const CreateDonationDriveSheet({required this.groupId, super.key});
  final String groupId;

  @override
  ConsumerState<CreateDonationDriveSheet> createState() =>
      _CreateDonationDriveSheetState();
}

class _CreateDonationDriveSheetState
    extends ConsumerState<CreateDonationDriveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  String _currency = 'USD';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final goalText = _goalCtrl.text.trim();
    final drive = await ref
        .read(donationDriveProvider.notifier)
        .create(
          groupId: widget.groupId,
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          externalLink:
              _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
          goalAmount:
              goalText.isEmpty ? null : double.tryParse(goalText),
          currency: _currency,
        );
    if (drive != null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donationDriveProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(Sizes.p16),
            children: [
              Row(
                children: [
                  const Icon(Icons.volunteer_activism_outlined),
                  gapW8,
                  Text(
                    'Create Donation Drive'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              gapH16,
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Masjid Renovation Fund',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              gapH12,
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              gapH12,
              TextFormField(
                controller: _linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Donation link (optional)',
                  hintText: 'https://gofundme.com/...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              gapH12,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _goalCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Goal amount (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v.trim()) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  gapW8,
                  DropdownButton<String>(
                    value: _currency,
                    items: _kCurrencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ],
              ),
              gapH24,
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isLoading ? null : _submit,
                  icon: state.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.volunteer_activism_outlined),
                  label: Text('Create drive'.hardcoded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
