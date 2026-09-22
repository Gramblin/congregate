import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/ads/data/ads_repository.dart';
import 'package:congregate/src/features/ads/domain/ad.dart';
import 'package:congregate/src/features/ads/presentation/view/ad_details_screen.dart';
import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/features/business/presentation/controller/business_controller.dart';
import 'package:congregate/src/features/business/presentation/view/business_details_screen.dart';
import 'package:congregate/src/features/home/presentation/view/location_picker_sheet.dart';
import 'package:congregate/src/features/stories/data/story_provider.dart';
import 'package:congregate/src/features/stories/presentation/story_strip.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3_carousel/m3_carousel.dart';
import 'package:m3e_core/m3e_core.dart';

const Map<String, IconData> _categoryIcons = {
  'All': Icons.apps_outlined,
  'Food': Icons.restaurant_outlined,
  'Finance': Icons.account_balance_outlined,
  'Education': Icons.school_outlined,
  'Legal': Icons.gavel_outlined,
  'Tech': Icons.computer_outlined,
  'Health': Icons.local_hospital_outlined,
  'Retail': Icons.storefront_outlined,
  'Services': Icons.handyman_outlined,
  'Mentorship': Icons.people_outlined,
  'Other': Icons.category_outlined,
};

const _categories = [
  'All',
  'Food',
  'Finance',
  'Education',
  'Legal',
  'Tech',
  'Health',
  'Retail',
  'Services',
  'Mentorship',
  'Other',
];

class BusinessListScreen extends ConsumerStatefulWidget {
  const BusinessListScreen({super.key});

  @override
  ConsumerState<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends ConsumerState<BusinessListScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLocationPicker(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const LocationPickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final asyncBusinesses = ref.watch(
      businessListProvider(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: location.hasLocation ? location.toString() : 'Set location',
          icon: const Icon(Icons.location_on_outlined),
          onPressed: () => _openLocationPicker(context),
        ),
        titleSpacing: 0,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search businesses'.hardcoded,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile'.hardcoded,
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: M3EPullToRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(businessListProvider);
          ref.invalidate(adsListProvider);
          await Future.wait([
            ref.read(businessListProvider().future),
            ref
                .read(storyStripProvider(StoryKind.business).notifier)
                .refresh(),
          ]);
        },
        child: CustomScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverToBoxAdapter(
              child: StoryStrip(kind: StoryKind.business),
            ),
            SliverToBoxAdapter(
              child: _AdsCarousel(ads: ref.watch(adsListProvider)),
            ),
            SliverToBoxAdapter(
              child: _MyBusinessesSection(
                all: asyncBusinesses.asData?.value,
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => gapW8,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final selected = cat == (_selectedCategory ?? 'All');
                    return FilterChip(
                      avatar: Icon(_categoryIcons[cat], size: 16),
                      label: Text(cat),
                      selected: selected,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      onSelected: (_) => setState(
                        () => _selectedCategory = cat == 'All' ? null : cat,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (location.hasLocation)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 14),
                      gapW4,
                      Expanded(
                        child: Text(
                          'Showing in $location',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ...asyncBusinesses.when(
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: M3ELoadingIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error: $e')),
                ),
              ],
              data: (all) {
                final businesses = _query.isEmpty
                    ? all
                    : all
                          .where((b) => b.name.toLowerCase().contains(_query))
                          .toList();
                if (businesses.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
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
                      ),
                    ),
                  ];
                }
                return [
                  SliverList.builder(
                    itemCount: businesses.length,
                    itemBuilder: (_, i) =>
                        _BusinessTile(business: businesses[i]),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdsCarousel extends StatelessWidget {
  const _AdsCarousel({required this.ads});
  final AsyncValue<List<Ad>> ads;

  @override
  Widget build(BuildContext context) {
    return ads.when(
      loading: () => const SizedBox(height: 180),
      error: (_, __) => const SizedBox(height: 180),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 180,
          child: M3Carousel(
            type: .uncontained,
            heroAlignment: .center,
            freeScroll: true,
            uncontainedItemExtent: 280,
            uncontainedShrinkExtent: 280,
            onTap: (tapIndex) {
              if (tapIndex < 0 || tapIndex >= list.length) return;
              Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute(
                  builder: (_) => AdDetailsScreen(ad: list[tapIndex]),
                ),
              );
            },
            children: list
                .map(
                  (ad) => Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: ad.bannerImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ColoredBox(color: Colors.black12),
                        errorWidget: (_, __, ___) =>
                            const ColoredBox(color: Colors.black26),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 90,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xCC000000),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Text(
                          ad.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _MyBusinessesSection extends ConsumerWidget {
  const _MyBusinessesSection({required this.all});
  final List<Business>? all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (all == null) return const SizedBox.shrink();
    final userId =
        ref.watch(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) return const SizedBox.shrink();
    final mine = all!.where((b) => b.ownerId == userId).toList();
    if (mine.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16),
                gapW4,
                Text(
                  'My businesses'.hardcoded,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: mine.length,
              separatorBuilder: (_, __) => gapW8,
              itemBuilder: (_, i) => _MyBusinessCard(business: mine[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyBusinessCard extends StatelessWidget {
  const _MyBusinessCard({required this.business});
  final Business business;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
            MaterialPageRoute(
              builder: (_) => BusinessDetailsScreen(business: business),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _BusinessAvatar(
                  imageUrl: business.profileImageUrl,
                  name: business.name,
                  radius: 22,
                ),
                gapW8,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        business.name,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        business.category,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      gapH4,
                      Row(
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 12,
                            color: scheme.primary,
                          ),
                          gapW4,
                          Text(
                            'Manage'.hardcoded,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
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
            const Icon(
              Icons.notifications_active,
              size: 14,
              color: Colors.green,
            ),
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
