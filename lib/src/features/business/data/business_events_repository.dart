import 'dart:developer';
import 'dart:io';

import 'package:congregate/src/features/business/domain/business_event.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'business_events_repository.g.dart';

class BusinessEventsRepository {
  BusinessEventsRepository(this._client);
  final SupabaseClient _client;

  Future<List<BusinessEvent>> fetchEvents(String businessId) async {
    try {
      final rows = await _client
          .from('business_events')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => BusinessEvent.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      log('BusinessEventsRepository.fetchEvents error: $e\n$st');
      rethrow;
    }
  }

  Future<BusinessEvent> createEvent({
    required String businessId,
    required String title,
    String type = 'event',
    String? description,
    double? price,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('business_events')
        .insert({
          'business_id': businessId,
          'title': title,
          'type': type,
          'created_by': userId,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (startAt != null) 'start_at': startAt.toUtc().toIso8601String(),
          if (endAt != null) 'end_at': endAt.toUtc().toIso8601String(),
        })
        .select()
        .single();
    return BusinessEvent.fromJson(row);
  }

  Future<String> uploadEventImage({
    required String businessId,
    required String eventId,
    required File image,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$businessId/events/$eventId.jpg';
    await _client.storage
        .from('business-images')
        .upload(
          path,
          image,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('business-images').getPublicUrl(path);
    await _client
        .from('business_events')
        .update({'image_url': url})
        .eq('id', eventId);
    return url;
  }

  Future<void> deleteEvent(String eventId) async {
    await _client.from('business_events').delete().eq('id', eventId);
  }
}

@Riverpod(keepAlive: true)
BusinessEventsRepository businessEventsRepository(Ref ref) {
  return BusinessEventsRepository(ref.watch(supabaseProvider).client);
}

@riverpod
Future<List<BusinessEvent>> businessEvents(Ref ref, String businessId) {
  return ref.watch(businessEventsRepositoryProvider).fetchEvents(businessId);
}
