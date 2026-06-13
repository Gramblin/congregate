import 'dart:io';

import 'package:congregate/src/features/business/data/business_events_repository.dart';
import 'package:congregate/src/features/business/domain/business_event.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_event_controller.g.dart';

@riverpod
class BusinessEventNotifier extends _$BusinessEventNotifier {
  @override
  FutureOr<void> build() => null;

  Future<BusinessEvent?> create({
    required String businessId,
    required String title,
    String type = 'event',
    String? description,
    double? price,
    DateTime? startAt,
    DateTime? endAt,
    File? image,
  }) async {
    state = const AsyncLoading();
    BusinessEvent? result;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(businessEventsRepositoryProvider);
      var event = await repo.createEvent(
        businessId: businessId,
        title: title,
        type: type,
        description: description,
        price: price,
        startAt: startAt,
        endAt: endAt,
      );

      if (image != null) {
        await repo.uploadEventImage(
          businessId: businessId,
          eventId: event.id,
          image: image,
        );
        final updated = await repo.fetchEvents(businessId);
        event = updated.firstWhere((e) => e.id == event.id, orElse: () => event);
      }

      result = event;

      // notify followers via edge function
      try {
        await ref.read(supabaseProvider).client.functions.invoke(
          'send-business-notification',
          body: {
            'businessId': businessId,
            'eventId': event.id,
            'title': title,
            'description': description ?? '',
            'type': type,
          },
        );
      } catch (_) {
        // notification failure is non-fatal
      }

      ref.invalidate(businessEventsProvider(businessId));
    });
    return result;
  }

  Future<void> delete(String eventId, String businessId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(businessEventsRepositoryProvider).deleteEvent(eventId);
      ref.invalidate(businessEventsProvider(businessId));
    });
  }
}
