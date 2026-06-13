import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/utils/city_picker_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  ConsumerState<LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final _countrySearch = TextEditingController();
  String? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedCity;

  List<(String, String)> get _filtered {
    final q = _countrySearch.text.toLowerCase();
    if (q.isEmpty) return kCountries;
    return kCountries
        .where((c) => c.$2.toLowerCase().contains(q) || c.$1.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationProvider);
    _selectedCountryCode = loc.country;
    _selectedCountry = loc.country != null
        ? kCountries
            .where((c) => c.$1 == loc.country)
            .map((c) => c.$2)
            .firstOrNull
        : null;
    _selectedCity = loc.city;
    _countrySearch.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _countrySearch.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCountryCode == null) return;
    await ref.read(locationProvider.notifier).setLocation(
          country: _selectedCountryCode!,
          city: _selectedCity,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined),
                    gapW8,
                    Text(
                      'Set your location'.hardcoded,
                      style: const TextStyle(
                        fontSize: Sizes.p16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCountryCode != null)
                      TextButton(
                        onPressed: _save,
                        child: Text('Save'.hardcoded),
                      ),
                  ],
                ),
              ),
              if (_selectedCountry != null) ...[
                ListTile(
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
                      context, ref, _selectedCountryCode!,
                    );
                    if (city != null) setState(() => _selectedCity = city);
                  },
                ),
                const Divider(height: 1),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _countrySearch,
                  decoration: InputDecoration(
                    hintText: 'Search country'.hardcoded,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final (code, name) = _filtered[i];
                    final selected = code == _selectedCountryCode;
                    return ListTile(
                      title: Text(name),
                      leading: Text(
                        code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: selected,
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      trailing: selected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => setState(() {
                        _selectedCountryCode = code;
                        _selectedCountry = name;
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
