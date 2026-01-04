import 'dart:developer';

import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'fcm_notifications_remote_repository.g.dart';

class FcmNotificationsRemoteRepository {
  FcmNotificationsRemoteRepository(this.client);

  final SupabaseClient client;

  Future<void> sendPrayerEventNotification({
    required String groupId,
    required String prayerType,
    required String eventId,
    required String prayerTime,
    required String prayerPlace,
    required DateTime eventDate,
    String? note, // Add this optional parameter
  }) async {
    try {
      final response = await client.functions.invoke(
        'send-prayer-notification',
        body: {
          'groupId': groupId,
          'prayerType': prayerType,
          'eventId': eventId,
          'prayerTime': prayerTime,
          'prayerPlace': prayerPlace,
          'eventDate': eventDate.toIso8601String(),
          if (note != null) 'note': note, // Include note if present
        },
      );

      if (response.status != 200) {
        log('Failed to send notification: ${response.data}');
        throw Exception('Failed to send notification: ${response.data}');
      }

      log('✅ Notification sent successfully via edge function');
    } catch (e, st) {
      log('FcmNotificationService.sendPrayerEventNotification error: $e\n$st');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FcmNotificationsRemoteRepository fcmNotificationRemoteRepository(Ref ref) {
  return FcmNotificationsRemoteRepository(ref.watch(supabaseProvider).client);
}
