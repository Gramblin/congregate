import 'package:congregate/src/utils/cities_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a searchable city list for [countryCode].
/// Returns the selected city string or null.
Future<String?> showCityPicker(
  BuildContext context,
  WidgetRef ref,
  String countryCode,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => CityPickerSheet(countryCode: countryCode),
  );
}

class CityPickerSheet extends ConsumerStatefulWidget {
  const CityPickerSheet({required this.countryCode, this.selected, super.key});
  final String countryCode;
  final String? selected;

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  final _search = TextEditingController();

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
    final asyncCities = ref.watch(citiesDataProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search city',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: asyncCities.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                final cities = citiesForCountry(data, widget.countryCode);
                final q = _search.text.toLowerCase();
                final filtered = q.isEmpty
                    ? cities
                    : cities
                        .where((c) => c.toLowerCase().contains(q))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No cities found'),
                  );
                }

                return ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final city = filtered[i];
                    return ListTile(
                      title: Text(city),
                      selected: city == widget.selected,
                      trailing: city == widget.selected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, city),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
