import 'dart:developer';

import 'package:congregate/src/features/group_details/domain/community_event.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'community_events_repository.g.dart';

class CommunityEventsRepository {
  CommunityEventsRepository(this._client);
  final SupabaseClient _client;

  Future<List<CommunityEvent>> fetchEvents(String groupId) async {
    try {
      final rows = await _client
          .from('community_events')
          .select(
            '*, community_event_sponsors(business_id, businesses(id, name, profile_image_url))',
          )
          .eq('group_id', groupId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => CommunityEvent.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      log('CommunityEventsRepository.fetchEvents error: $e\n$st');
      rethrow;
    }
  }

  Future<CommunityEvent> create({
    required String groupId,
    required String title,
    String? description,
    String? place,
    String? note,
    DateTime? eventDatetime,
    List<String> sponsorBusinessIds = const [],
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('community_events')
        .insert({
          'group_id': groupId,
          'title': title,
          'created_by': userId,
          if (description != null) 'description': description,
          if (place != null) 'place': place,
          if (note != null) 'note': note,
          if (eventDatetime != null)
            'event_datetime': eventDatetime.toUtc().toIso8601String(),
        })
        .select()
        .single();

    final event = CommunityEvent.fromJson(row);

    if (sponsorBusinessIds.isNotEmpty) {
      await _client.from('community_event_sponsors').insert(
        sponsorBusinessIds
            .map((bId) => {
                  'community_event_id': event.id,
                  'business_id': bId,
                })
            .toList(),
      );
    }

    return event;
  }

  Future<void> delete(String eventId) async {
    await _client.from('community_events').delete().eq('id', eventId);
  }
}

@Riverpod(keepAlive: true)
CommunityEventsRepository communityEventsRepository(Ref ref) =>
    CommunityEventsRepository(ref.watch(supabaseProvider).client);

@riverpod
Future<List<CommunityEvent>> communityEvents(Ref ref, String groupId) =>
    ref.watch(communityEventsRepositoryProvider).fetchEvents(groupId);
