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
    required DateTime prayerDateTime,
    required String eventId,
    required String prayerPlace,
    String? note,
  }) async {
    final response = await client.functions.invoke(
      'send-prayer-notification',
      body: {
        'groupId': groupId,
        'prayerType': prayerType,
        'prayerDateTime': prayerDateTime
            .toUtc()
            .toIso8601String(), // Send as UTC ISO string
        'eventId': eventId,
        'prayerPlace': prayerPlace,
        if (note != null) 'note': note,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to send notification');
    }
  }
}

@Riverpod(keepAlive: true)
FcmNotificationsRemoteRepository fcmNotificationRemoteRepository(Ref ref) {
  return FcmNotificationsRemoteRepository(ref.watch(supabaseProvider).client);
}
