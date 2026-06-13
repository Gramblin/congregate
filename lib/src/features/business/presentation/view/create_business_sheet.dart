import 'dart:io';

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/business/presentation/controller/business_controller.dart';
import 'package:congregate/src/features/group/presentation/view/create_group_sheet.dart'
    show CountryPickerSheet;
import 'package:congregate/src/utils/city_picker_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const _kCategories = [
  'Food', 'Finance', 'Education', 'Legal',
  'Tech', 'Health', 'Retail', 'Services', 'Mentorship', 'Other',
];

class CreateBusinessSheet extends ConsumerStatefulWidget {
  const CreateBusinessSheet({super.key});

  @override
  ConsumerState<CreateBusinessSheet> createState() =>
      _CreateBusinessSheetState();
}

class _CreateBusinessSheetState extends ConsumerState<CreateBusinessSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  String _category = 'Other';
  String _visibility = 'global';
  bool _contactPublic = true;
  String? _countryCode;
  String? _selectedCity;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationProvider);
    _countryCode = loc.country;
    _selectedCity = loc.city;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _emailCtrl, _phoneCtrl, _websiteCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (xfile != null) setState(() => _profileImage = File(xfile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final business = await ref.read(businessFormProvider.notifier).create(
          name: _nameCtrl.text.trim(),
          category: _category,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          country: _countryCode,
          city: _selectedCity,
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
          visibility: _visibility,
          contactPublic: _contactPublic,
          profileImage: _profileImage,
        );
    if (business != null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessFormProvider);
    final countryName = _countryCode != null
        ? kCountries.where((c) => c.$1 == _countryCode).map((c) => c.$2).firstOrNull
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(Sizes.p16),
            children: [
              Text(
                'Register Business'.hardcoded,
                style: const TextStyle(
                  fontSize: Sizes.p20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              gapH16,

              // Profile image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.add_a_photo_outlined, size: 32)
                        : null,
                  ),
                ),
              ),
              gapH16,

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Business name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _kCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              gapH12,

              // Country
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: Text(countryName ?? 'Select country'.hardcoded),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CountryPickerSheet(selected: _countryCode),
                  );
                  if (result != null) setState(() => _countryCode = result);
                },
              ),
              if (_countryCode != null) ...[
                gapH4,
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_city_outlined),
                  title: Text(_selectedCity ?? 'Select city (optional)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedCity != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _selectedCity = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                  onTap: () async {
                    final city = await showCityPicker(
                      context, ref, _countryCode!,
                    );
                    if (city != null) setState(() => _selectedCity = city);
                  },
                ),
              ],
              gapH12,

              // Contact fields
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              gapH8,
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              gapH8,
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              gapH12,

              // Visibility
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Visibility'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'local', label: Text('Local')),
                      ButtonSegment(value: 'global', label: Text('Global')),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (v) =>
                        setState(() => _visibility = v.first),
                  ),
                ],
              ),
              gapH8,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public contact info'),
                subtitle: const Text('Email & phone visible to all users'),
                value: _contactPublic,
                onChanged: (v) => setState(() => _contactPublic = v),
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
                      : Text('Register business'.hardcoded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
