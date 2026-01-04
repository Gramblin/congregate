import 'dart:developer';

import 'package:congregate/src/features/group/domain/event_attendee.dart';
import 'package:congregate/src/features/group_details/domain/group_event.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'group_events_repository.g.dart';

class GroupEventsRepository {
  GroupEventsRepository(this.client);
  final SupabaseClient client;

  Future<GroupEvent> createEvent({
    required String groupId,
    required String userId,
    required String prayerType,
    required String prayerTime,
    required String prayerPlace,
    required DateTime eventDate, // Add this parameter
  }) async {
    final response = await client
        .from('group_events')
        .insert({
          'group_id': groupId,
          'created_by': userId,
          'prayer_type': prayerType,
          'prayer_time': prayerTime,
          'prayer_place': prayerPlace,
          'event_date': eventDate.toIso8601String().split(
            'T',
          )[0], // Store as date only (YYYY-MM-DD)
        })
        .select()
        .single();

    return GroupEvent.fromJson(response);
  }

  /// Get events for a specific group
  Future<List<GroupEvent>> getGroupEvents({
    required String groupId,
    DateTime? fromDate,
  }) async {
    try {
      var query = client.from('group_events').select().eq('group_id', groupId);

      if (fromDate != null) {
        query = query.gte(
          'event_date',
          fromDate.toIso8601String().split('T')[0],
        );
      }

      final response = await query.order('event_date').order('prayer_time');

      return (response as List)
          .map((json) => GroupEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      log('GroupEventsRepository.getGroupEvents error: $e\n$st');
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await client.from('group_events').delete().eq('id', eventId);
    } catch (e, st) {
      log('GroupEventsRepository.deleteEvent error: $e\n$st');
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Update an event
  Future<GroupEvent> updateEvent({
    required String eventId,
    String? prayerType,
    String? prayerTime,
    String? prayerPlace,
    DateTime? eventDate,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (prayerType != null) updates['prayer_type'] = prayerType;
      if (prayerTime != null) updates['prayer_time'] = prayerTime;
      if (prayerPlace != null) updates['prayer_place'] = prayerPlace;
      if (eventDate != null) {
        updates['event_date'] = eventDate.toIso8601String().split('T')[0];
      }

      if (updates.isEmpty) {
        throw Exception('No fields to update');
      }

      final response = await client
          .from('group_events')
          .update(updates)
          .eq('id', eventId)
          .select()
          .single();

      return GroupEvent.fromJson(response);
    } catch (e, st) {
      log('GroupEventsRepository.updateEvent error: $e\n$st');
      throw Exception('Failed to update event: $e');
    }
  }

  /// Mark user attendance for an event
  Future<void> markAttendance({
    required String eventId,
    required String userId,
    required String status, // 'going', 'not_going', 'maybe'
  }) async {
    try {
      // Upsert with onConflict to handle duplicates
      await client.from('group_event_attendees').upsert(
        {
          'event_id': eventId,
          'user_id': userId,
          'status': status,
          'responded_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'event_id,user_id', // Update if combination exists
      );
    } catch (e, st) {
      log('GroupEventsRepository.markAttendance error: $e\n$st');
      throw Exception('Failed to mark attendance: $e');
    }
  }

  /// Get attendees for an event with user profiles
  Future<List<Map<String, dynamic>>> getEventAttendees(String eventId) async {
    try {
      final response = await client
          .from('group_event_attendees')
          .select(
            '*, user_profiles!inner(display_name, real_name, show_real_name)',
          )
          .eq('event_id', eventId)
          .order('responded_at');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      log('GroupEventsRepository.getEventAttendees error: $e\n$st');
      throw Exception('Failed to fetch attendees: $e');
    }
  }

  /// Get attendance count by status for an event
  Future<Map<String, int>> getAttendanceCount(String eventId) async {
    try {
      final response = await client
          .from('group_event_attendees')
          .select('status')
          .eq('event_id', eventId);

      final counts = <String, int>{
        'going': 0,
        'not_going': 0,
        'maybe': 0,
      };

      for (final row in response as List) {
        final status = row['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e, st) {
      log('GroupEventsRepository.getAttendanceCount error: $e\n$st');
      throw Exception('Failed to get attendance count: $e');
    }
  }

  /// Check if current user is attending an event
  Future<String?> getUserAttendanceStatus({
    required String eventId,
    required String userId,
  }) async {
    try {
      final response = await client
          .from('group_event_attendees')
          .select('status')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e, st) {
      log('GroupEventsRepository.getUserAttendanceStatus error: $e\n$st');
      return null;
    }
  }

  /// Remove user's attendance
  Future<void> removeAttendance({
    required String eventId,
    required String userId,
  }) async {
    try {
      await client
          .from('group_event_attendees')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e, st) {
      log('GroupEventsRepository.removeAttendance error: $e\n$st');
      throw Exception('Failed to remove attendance: $e');
    }
  }

  Future<List<EventAttendee>> getEventAttendeesList(String eventId) async {
    final response = await client
        .from('group_event_attendees')
        .select('*, user_profiles!inner(display_name)')
        .eq('event_id', eventId)
        .order('responded_at', ascending: false);

    return (response as List).map((json) {
      final map = Map<String, dynamic>.from(json as Map);
      map['displayName'] = json['user_profiles']['display_name'];
      return EventAttendee.fromJson(map);
    }).toList();
  }
}

@Riverpod(keepAlive: true)
GroupEventsRepository groupEventsRepository(Ref ref) {
  return GroupEventsRepository(ref.watch(supabaseProvider).client);
}

/// Provider to fetch events for a specific group
@riverpod
Future<List<GroupEvent>> groupEvents(Ref ref, String groupId) async {
  final repo = ref.watch(groupEventsRepositoryProvider);
  return repo.getGroupEvents(groupId: groupId, fromDate: DateTime.now());
}
