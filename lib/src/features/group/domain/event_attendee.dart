// lib/src/features/group_details/domain/event_attendee.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_attendee.freezed.dart';
part 'event_attendee.g.dart';

@freezed
abstract class EventAttendee with _$EventAttendee {
  const factory EventAttendee({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'user_id') required String userId,
    required String status,
    @JsonKey(name: 'responded_at') required DateTime respondedAt,
    @JsonKey(name: 'displayName') String? displayName,
  }) = _EventAttendee;

  factory EventAttendee.fromJson(Map<String, dynamic> json) =>
      _$EventAttendeeFromJson(json);
}
