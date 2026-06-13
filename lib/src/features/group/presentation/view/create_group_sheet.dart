import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/presentation/controller/group_controller.dart';
import 'package:congregate/src/router/congregate_bottom_sheet.dart';
import 'package:congregate/src/utils/city_picker_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPublic = false;
  String? _selectedCountryCode;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationProvider);
    _selectedCountryCode = loc.country;
    _selectedCity = loc.city;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(
      groupControllerProvider,
      (prev, next) {
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create group: ${next.error}')),
          );
        }
      },
    );

    final controller = ref.watch(groupControllerProvider);

    final countryName = _selectedCountryCode != null
        ? kCountries
            .where((c) => c.$1 == _selectedCountryCode)
            .map((c) => c.$2)
            .firstOrNull ?? _selectedCountryCode!
        : null;

    return CongregateBottomSheet(
      children: [
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Community'.hardcoded,
                  style: const TextStyle(
                    fontSize: Sizes.p20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH16,
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Community name'.hardcoded,
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      gapH12,
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Description (optional)'.hardcoded,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      gapH12,
                      // Country picker (required)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.flag_outlined,
                          color: _selectedCountryCode == null
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        title: Text(
                          countryName ?? 'Select country *'.hardcoded,
                          style: _selectedCountryCode == null
                              ? TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                )
                              : null,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: _pickCountry,
                      ),
                      if (_selectedCountryCode != null) ...[
                        gapH4,
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_city_outlined),
                          title: Text(_selectedCity ?? 'Select city (optional)'.hardcoded),
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
                              context, ref, _selectedCountryCode!,
                            );
                            if (city != null) setState(() => _selectedCity = city);
                          },
                        ),
                      ],
                      gapH12,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Public community'.hardcoded),
                          Switch(
                            value: _isPublic,
                            onChanged: (v) => setState(() => _isPublic = v),
                          ),
                        ],
                      ),
                      gapH24,
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: controller.isLoading ? null : _submit,
                          child: controller.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Create community'.hardcoded),
                        ),
                      ),
                    ],
                  ),
                ),
                gapH16,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CountryPickerSheet(selected: _selectedCountryCode),
    );
    if (result != null) {
      setState(() {
        _selectedCountryCode = result;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountryCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a country')),
      );
      return;
    }
    await ref.read(groupControllerProvider.notifier).createGroup(
          name: _nameController.text.trim(),
          isPublic: _isPublic,
          country: _selectedCountryCode,
          city: _selectedCity,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
        );
  }
}

class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({this.selected});
  final String? selected;

  @override
  State<CountryPickerSheet> createState() => CountryPickerSheetState();
}

class CountryPickerSheetState extends State<CountryPickerSheet> {
  final _search = TextEditingController();

  List<(String, String)> get _filtered {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return kCountries;
    return kCountries
        .where((c) =>
            c.$2.toLowerCase().contains(q) || c.$1.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final (code, name) = _filtered[i];
                return ListTile(
                  leading: Text(
                    code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  title: Text(name),
                  selected: code == widget.selected,
                  onTap: () => Navigator.pop(context, code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
