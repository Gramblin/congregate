import 'dart:async';

import 'package:congregate/src/features/group/data/fcm_notifications_remote_repository.dart';
import 'package:congregate/src/features/group/data/group_events_repository.dart';
import 'package:congregate/src/features/group/domain/event_attendee.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_event_controller.g.dart';

@Riverpod(keepAlive: true)
class GroupEventController extends _$GroupEventController {
  @override
  FutureOr<void> build() => null;

  /// Create event and send notification
  Future<void> createEventAndNotify({
    required String groupId,
    required String prayerType,
    required String prayerTime,
    required String prayerPlace,
    required DateTime eventDate,
    String? note, // Add this optional parameter
  }) async {
    state = const AsyncLoading();

    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    state = await AsyncValue.guard(() async {
      // 1. Create the event in database
      final repo = ref.read(groupEventsRepositoryProvider);
      final event = await repo.createEvent(
        groupId: groupId,
        userId: userId,
        prayerType: prayerType,
        prayerTime: prayerTime,
        prayerPlace: prayerPlace,
        eventDate: eventDate,
        note: note, // Pass the note
      );

      // 2. Auto-mark creator as attending
      await repo.markAttendance(
        eventId: event.id,
        userId: userId,
        status: 'going',
      );

      // 3. Send FCM notification via edge function
      final fcmService = ref.read(fcmNotificationRemoteRepositoryProvider);
      await fcmService.sendPrayerEventNotification(
        groupId: groupId,
        prayerType: prayerType,
        prayerTime: prayerTime,
        eventId: event.id,
        prayerPlace: prayerPlace,
        eventDate: eventDate,
        note: note, // Pass the note
      );

      // 4. Refresh the events list (check if still mounted)
      if (ref.mounted) {
        ref.invalidate(groupEventsProvider(groupId));
      }
    });
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId, String groupId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(groupEventsRepositoryProvider);
      await repo.deleteEvent(eventId);

      // Check if mounted after async operation
      if (ref.mounted) {
        ref.invalidate(groupEventsProvider(groupId));
      }
    });
  }
}

@riverpod
Future<List<EventAttendee>> eventAttendees(Ref ref, String eventId) async {
  final repo = ref.watch(groupEventsRepositoryProvider);
  return repo.getEventAttendeesList(eventId);
}
