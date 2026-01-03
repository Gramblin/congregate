import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_event_attendee.freezed.dart';
part 'group_event_attendee.g.dart';

@freezed
abstract class GroupEventAttendee with _$GroupEventAttendee {
  const factory GroupEventAttendee({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'user_id') required String userId,
    required String status,
    @JsonKey(name: 'responded_at') DateTime? respondedAt,
    @JsonKey(name: 'user_profiles') Map<String, dynamic>? userProfile,
  }) = _GroupEventAttendee;

  factory GroupEventAttendee.fromJson(Map<String, dynamic> json) =>
      _$GroupEventAttendeeFromJson(json);
}

enum AttendanceStatus {
  going('going', 'Going'),
  notGoing('not_going', 'Not Going'),
  maybe('maybe', 'Maybe')
  ;

  const AttendanceStatus(this.value, this.displayName);
  final String value;
  final String displayName;
}
