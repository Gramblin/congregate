// ignore_for_file: unused_result

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
    required DateTime prayerDateTime,
    required String prayerPlace,
    String? note,
    double? latitude,
    double? longitude,
    List<String> sponsorBusinessIds = const [],
  }) async {
    state = const AsyncLoading();

    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) throw Exception('User not logged in');
    if (groupId.isEmpty) throw Exception('groupId is empty — route parameter missing');

    print('🔵 Starting createEventAndNotify');
    print('🔵 groupId: "$groupId"');
    print('🔵 userId: "$userId"');
    print('🔵 Prayer DateTime: $prayerDateTime');

    state = await AsyncValue.guard(() async {
      try {
        // 1. Create the event in database
        print('🔵 Step 1: Creating event in database...');
        final repo = ref.read(groupEventsRepositoryProvider);
        final event = await repo.createEvent(
          groupId: groupId,
          userId: userId,
          prayerType: prayerType,
          prayerDateTime: prayerDateTime,
          prayerPlace: prayerPlace,
          note: note,
          latitude: latitude,
          longitude: longitude,
          sponsorBusinessIds: sponsorBusinessIds,
        );
        print('✅ Event created: ${event.id}');

        // 2. Auto-mark creator as attending
        print('🔵 Step 2: Marking attendance...');
        await repo.markAttendance(
          eventId: event.id,
          userId: userId,
          status: 'going',
        );
        print('✅ Attendance marked');

        // 3. Send FCM notification via edge function (non-fatal)
        print('🔵 Step 3: Sending notification...');
        try {
          final fcmService = ref.read(fcmNotificationRemoteRepositoryProvider);
          await fcmService.sendPrayerEventNotification(
            groupId: groupId,
            prayerType: prayerType,
            prayerDateTime: prayerDateTime,
            eventId: event.id,
            prayerPlace: prayerPlace,
            note: note,
          );
          print('✅ Notification sent');
        } on Exception catch (e) {
          print('⚠️ Notification failed (non-fatal): $e');
        }

        // 4. Refresh the events list
        if (ref.mounted) {
          await ref.refresh(groupEventsProvider(groupId).future);
        }
        print('✅ Events list refreshed');
      } catch (e, stack) {
        print('❌ Error in createEventAndNotify: $e');
        print('❌ Stack trace: $stack');
        rethrow;
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
