import 'dart:io';

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/ads/data/ads_repository.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart'
    hide ImageSource;
import 'package:image_picker/image_picker.dart';

class CreateAdSheet extends ConsumerStatefulWidget {
  const CreateAdSheet({required this.businessId, super.key});
  final String businessId;

  @override
  ConsumerState<CreateAdSheet> createState() => _CreateAdSheetState();
}

class _CreateAdSheetState extends ConsumerState<CreateAdSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _htmlCtrl = TextEditingController(
    text: '<h2>Your headline</h2>\n<p>Describe your offer here.</p>',
  );
  File? _banner;
  bool _showPreview = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _htmlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (xfile != null) setState(() => _banner = File(xfile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_banner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a banner image first')),
      );
      return;
    }
    final ad = await ref.read(adFormProvider.notifier).create(
          businessId: widget.businessId,
          title: _titleCtrl.text.trim(),
          htmlContent: _htmlCtrl.text.trim(),
          bannerImage: _banner!,
          linkUrl: _linkCtrl.text.trim().isEmpty
              ? null
              : _linkCtrl.text.trim(),
        );
    if (ad != null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adFormProvider);
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(Sizes.p16),
            children: [
              Text(
                'New Ad'.hardcoded,
                style: const TextStyle(
                  fontSize: Sizes.p20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              gapH16,

              GestureDetector(
                onTap: _pickBanner,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    image: _banner != null
                        ? DecorationImage(
                            image: FileImage(_banner!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _banner == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_outlined, size: 40),
                              Text('Add banner image'),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              gapH12,

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              gapH8,

              TextFormField(
                controller: _linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link URL (optional)',
                  hintText: 'https://…',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              gapH16,

              Row(
                children: [
                  Text(
                    'Ad body (HTML)'.hardcoded,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showPreview = !_showPreview),
                    icon: Icon(
                      _showPreview
                          ? Icons.code
                          : Icons.remove_red_eye_outlined,
                      size: 16,
                    ),
                    label: Text(_showPreview ? 'Edit' : 'Preview'),
                  ),
                ],
              ),
              gapH4,

              if (_showPreview)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  padding: const EdgeInsets.all(Sizes.p12),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HtmlWidget(_htmlCtrl.text),
                )
              else
                TextFormField(
                  controller: _htmlCtrl,
                  maxLines: 12,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        '<h2>Headline</h2>\n<p>Body copy…</p>\n<ul><li>Feature</li></ul>',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              gapH24,

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Post Ad'.hardcoded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
