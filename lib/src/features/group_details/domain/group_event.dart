import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_event.freezed.dart';
part 'group_event.g.dart';

@freezed
abstract class GroupEvent with _$GroupEvent {
  const factory GroupEvent({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'prayer_type') required String prayerType,
    @JsonKey(name: 'prayer_time') required String prayerTime,
    @JsonKey(name: 'prayer_place') required String prayerPlace,
    @JsonKey(name: 'event_date') required String eventDate,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _GroupEvent;

  factory GroupEvent.fromJson(Map<String, dynamic> json) =>
      _$GroupEventFromJson(json);
}

enum PrayerType {
  fajr('Fajr'),
  dhuhr('Dhuhr'),
  asr('Asr'),
  maghrib('Maghrib'),
  isha('Isha'),
  nafl('Nafl'),
  taraweeh('Taraweeh')
  ;

  const PrayerType(this.displayName);
  final String displayName;

  String get value => name;
}
