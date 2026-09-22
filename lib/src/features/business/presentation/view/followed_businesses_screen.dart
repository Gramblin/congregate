import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/business/data/business_events_repository.dart';
import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/features/business/domain/business_event.dart';
import 'package:congregate/src/features/business/presentation/controller/business_controller.dart';
import 'package:congregate/src/features/business/presentation/view/business_details_screen.dart';
import 'package:congregate/src/features/stories/data/story_provider.dart';
import 'package:congregate/src/features/stories/domain/story_item.dart';
import 'package:congregate/src/features/stories/presentation/story_viewer_screen.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final followedBusinessesProvider =
    FutureProvider<List<Business>>((ref) async {
  final list = await ref.watch(businessListProvider().future);
  return list.where((b) => b.isFollowing == true).toList();
});

final followedBusinessesEventsProvider =
    FutureProvider<List<BusinessEvent>>((ref) async {
  final followed = await ref.watch(followedBusinessesProvider.future);
  final repo = ref.watch(businessEventsRepositoryProvider);
  final results = await Future.wait(
    followed.map((b) => repo.fetchEvents(b.id)),
  );
  final all = results.expand((e) => e).toList();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final live = all.where((e) {
    if (e.type == 'product') return false;
    final r = e.endAt ?? e.startAt;
    if (r == null) return true;
    return !r.isBefore(today);
  }).toList()
    ..sort((a, b) {
      final ax = a.startAt ?? a.createdAt;
      final bx = b.startAt ?? b.createdAt;
      return ax.compareTo(bx);
    });
  return live;
});

class FollowedBusinessesScreen extends ConsumerStatefulWidget {
  const FollowedBusinessesScreen({super.key});

  @override
  ConsumerState<FollowedBusinessesScreen> createState() =>
      _FollowedBusinessesScreenState();
}

class _FollowedBusinessesScreenState
    extends ConsumerState<FollowedBusinessesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncFollowed = ref.watch(followedBusinessesProvider);
    final asyncEvents = ref.watch(followedBusinessesEventsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.p8),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'Search followed businesses'.hardcoded,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _debounce?.cancel();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(businessListProvider);
          ref.invalidate(followedBusinessesProvider);
          ref.invalidate(followedBusinessesEventsProvider);
          await Future.wait([
            ref.read(followedBusinessesProvider.future),
            ref.read(followedBusinessesEventsProvider.future),
            ref
                .read(storyStripProvider(StoryKind.business).notifier)
                .refresh(),
          ]);
        },
        child: asyncFollowed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [Text('Error: $e')]),
          data: (followed) {
            if (followed.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      "You don't follow any businesses yet.".hardcoded,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            }
            final matchedBusinesses = _query.isEmpty
                ? followed
                : followed
                    .where((b) => b.name.toLowerCase().contains(_query))
                    .toList();
            final matchedIds = matchedBusinesses.map((b) => b.id).toSet();
            final byId = {for (final b in followed) b.id: b};

            return ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                _FollowedBusinessesStrip(businesses: matchedBusinesses),
                _FollowedStoryStrip(followedIds: matchedIds),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sizes.p16,
                    vertical: Sizes.p8,
                  ),
                  child: Text(
                    'Upcoming events'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                asyncEvents.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(Sizes.p16),
                    child: Text('Error: $e'),
                  ),
                  data: (events) {
                    final filtered = events.where((e) {
                      if (!matchedIds.contains(e.businessId)) return false;
                      if (_query.isEmpty) return true;
                      final title = e.title.toLowerCase();
                      final biz =
                          byId[e.businessId]?.name.toLowerCase() ?? '';
                      return title.contains(_query) || biz.contains(_query);
                    }).toList();
                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(Sizes.p16),
                        child: Text(
                          _query.isEmpty
                              ? 'No upcoming events.'.hardcoded
                              : 'No matches.'.hardcoded,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final e in filtered)
                          _FollowedEventCard(
                            event: e,
                            business: byId[e.businessId],
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FollowedStoryStrip extends ConsumerWidget {
  const _FollowedStoryStrip({required this.followedIds});
  final Set<String> followedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyStripProvider(StoryKind.business));
    final items = state.items
        .where((i) => followedIds.contains(i.id))
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final watched = state.watched.contains(item.id);
          return _StoryCircle(
            item: item,
            watched: watched,
            onTap: () => _open(context, items, i),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, List<StoryItem> items, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => StoryViewerScreen(
          items: items,
          initialPage: index,
          kind: StoryKind.business,
        ),
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  const _StoryCircle({
    required this.item,
    required this.watched,
    required this.onTap,
  });

  final StoryItem item;
  final bool watched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: watched
                    ? null
                    : LinearGradient(
                        colors: item.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: watched
                    ? Border.all(
                        color:
                            Theme.of(context).colorScheme.outlineVariant,
                        width: 2,
                      )
                    : null,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: item.gradient.last.withValues(alpha: 0.85),
                  child: Text(
                    item.name.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                item.name,
                style: const TextStyle(fontSize: 11, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowedEventCard extends StatelessWidget {
  const _FollowedEventCard({required this.event, required this.business});
  final BusinessEvent event;
  final Business? business;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y');
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: Sizes.p16,
        vertical: Sizes.p4,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: business == null
            ? null
            : () => Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        BusinessDetailsScreen(business: business!),
                  ),
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              CachedNetworkImage(
                imageUrl: event.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(Sizes.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (business != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: business!.profileImageUrl != null
                              ? CachedNetworkImageProvider(
                                  business!.profileImageUrl!,
                                )
                              : null,
                          child: business!.profileImageUrl == null
                              ? Text(
                                  business!.name[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        ),
                        gapW8,
                        Expanded(
                          child: Text(
                            business!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  gapH8,
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Sizes.p16,
                    ),
                  ),
                  if (event.description != null) ...[
                    gapH4,
                    Text(event.description!),
                  ],
                  if (event.startAt != null) ...[
                    gapH8,
                    Row(
                      children: [
                        const Icon(Icons.event, size: 14),
                        gapW4,
                        Text(
                          fmt.format(event.startAt!.toLocal()),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (event.endAt != null) ...[
                          const Text(' – '),
                          Text(
                            fmt.format(event.endAt!.toLocal()),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowedBusinessesStrip extends StatelessWidget {
  const _FollowedBusinessesStrip({required this.businesses});
  final List<Business> businesses;

  @override
  Widget build(BuildContext context) {
    if (businesses.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: businesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final b = businesses[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
              MaterialPageRoute(
                builder: (_) => BusinessDetailsScreen(business: b),
              ),
            ),
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: b.profileImageUrl != null
                        ? CachedNetworkImageProvider(b.profileImageUrl!)
                        : null,
                    child: b.profileImageUrl == null
                        ? Text(
                            b.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.name,
                    style: const TextStyle(fontSize: 11, height: 1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
