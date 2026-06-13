import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/features/business/presentation/controller/business_controller.dart';
import 'package:congregate/src/features/business/presentation/view/business_details_screen.dart';
import 'package:congregate/src/features/business/presentation/view/create_business_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _categoryIcons = {
  'All':        Icons.apps_outlined,
  'Food':       Icons.restaurant_outlined,
  'Finance':    Icons.account_balance_outlined,
  'Education':  Icons.school_outlined,
  'Legal':      Icons.gavel_outlined,
  'Tech':       Icons.computer_outlined,
  'Health':     Icons.local_hospital_outlined,
  'Retail':     Icons.storefront_outlined,
  'Services':   Icons.handyman_outlined,
  'Mentorship': Icons.people_outlined,
  'Other':      Icons.category_outlined,
};

const _categories = [
  'All', 'Food', 'Finance', 'Education', 'Legal',
  'Tech', 'Health', 'Retail', 'Services', 'Mentorship', 'Other',
];

class BusinessListScreen extends ConsumerStatefulWidget {
  const BusinessListScreen({super.key});

  @override
  ConsumerState<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends ConsumerState<BusinessListScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final asyncBusinesses = ref.watch(
      businessListProvider(category: _selectedCategory == 'All' ? null : _selectedCategory),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CreateBusinessSheet(),
        ),
        icon: const Icon(Icons.add_business_outlined),
        label: Text('Register'.hardcoded),
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => gapW8,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == (_selectedCategory ?? 'All');
                return FilterChip(
                  avatar: Icon(
                    _categoryIcons[cat],
                    size: 16,
                  ),
                  label: Text(cat),
                  selected: selected,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  onSelected: (_) => setState(() =>
                      _selectedCategory = cat == 'All' ? null : cat),
                );
              },
            ),
          ),
          if (location.hasLocation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 14),
                  gapW4,
                  Text(
                    'Showing in $location',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: asyncBusinesses.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (businesses) {
                if (businesses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store_outlined, size: 48),
                        gapH16,
                        Text(
                          location.hasLocation
                              ? 'No businesses in $location yet.'
                              : 'No businesses yet.',
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(businessListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: businesses.length,
                    itemBuilder: (_, i) =>
                        _BusinessTile(business: businesses[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessTile extends ConsumerWidget {
  const _BusinessTile({required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDetailsScreen(business: business),
        ),
      ),
      leading: _BusinessAvatar(
        imageUrl: business.profileImageUrl,
        name: business.name,
        radius: 24,
      ),
      title: Text(business.name),
      subtitle: Text(
        [
          business.category,
          if (business.city != null) business.city!,
          if (business.country != null) business.country!,
        ].join(' · '),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 14),
          Text(
            '${business.followerCount}',
            style: const TextStyle(fontSize: 11),
          ),
          if (business.isFollowing == true)
            const Icon(Icons.notifications_active, size: 14, color: Colors.green),
        ],
      ),
    );
  }
}

class _BusinessAvatar extends StatelessWidget {
  const _BusinessAvatar({
    required this.name,
    this.imageUrl,
    this.radius = 20,
  });
  final String? imageUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: radius * 0.8),
      ),
    );
  }
}
