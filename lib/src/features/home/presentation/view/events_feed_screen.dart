import 'dart:math' as math;

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group_details/domain/group_event.dart';
import 'package:congregate/src/features/group_details/presentation/views/event_card.dart';
import 'package:congregate/src/features/home/data/home_remote_repository.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'events_feed_screen.g.dart';

class FeedItem {
  const FeedItem({
    required this.event,
    required this.groupId,
    required this.groupName,
    this.distanceKm,
  });
  final GroupEvent event;
  final String groupId;
  final String groupName;
  final double? distanceKm;
}

@riverpod
Future<Position?> userPosition(Ref ref) async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition();
  } on Exception {
    return null;
  }
}

double? _distanceKm(
  double? eLat, double? eLon,
  double? uLat, double? uLon,
) {
  if (eLat == null || eLon == null || uLat == null || uLon == null) return null;
  const r = 6371.0;
  final dLat = (eLat - uLat) * math.pi / 180;
  final dLon = (eLon - uLon) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(uLat * math.pi / 180) *
          math.cos(eLat * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String _fmtDist(double km) =>
    km < 1 ? '${(km * 1000).round()} m away' : '${km.toStringAsFixed(1)} km away';

@riverpod
Future<List<FeedItem>> userFeedEvents(Ref ref) async {
  final userId = ref.watch(supabaseProvider).client.auth.currentUser?.id;
  if (userId == null) return [];

  final rows = await ref.watch(homeRemoteRepositoryProvider).fetchUserFeedEvents(userId);
  final pos = await ref.watch(userPositionProvider.future);

  final items = rows.map((row) {
    final g = row['groups'] as Map<String, dynamic>?;
    final event = GroupEvent.fromJson(row);
    return FeedItem(
      event: event,
      groupId: g?['id'] as String? ?? '',
      groupName: g?['name'] as String? ?? 'Unknown group',
      distanceKm: _distanceKm(
        event.latitude, event.longitude,
        pos?.latitude, pos?.longitude,
      ),
    );
  }).toList();

  items.sort((a, b) {
    final da = a.distanceKm;
    final db = b.distanceKm;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return a.event.prayerDateTime.compareTo(b.event.prayerDateTime);
  });

  return items;
}

class EventsFeedScreen extends ConsumerWidget {
  const EventsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(userFeedEventsProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Prayer Events'),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Re-sort by location',
              onPressed: () {
                ref
                  ..invalidate(userPositionProvider)
                  ..invalidate(userFeedEventsProvider);
              },
            ),
          ],
        ),
        body: asyncEvents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy_outlined, size: 64),
                    gapH16,
                    Text(
                      'No upcoming events',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    gapH8,
                    Text(
                      'Join a group and create a prayer event to see it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref
                  ..invalidate(userPositionProvider)
                  ..invalidate(userFeedEventsProvider);
                await ref.read(userFeedEventsProvider.future);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Sizes.p16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 4,
                          bottom: 2,
                          top: index == 0 ? 0 : 12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              item.groupName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            if (item.distanceKm != null) ...[
                              gapW8,
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              gapW4,
                              Text(
                                _fmtDist(item.distanceKm!),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      EventCard(
                        event: item.event,
                        groupId: item.groupId,
                        isAdmin: false,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      );
  }
}
