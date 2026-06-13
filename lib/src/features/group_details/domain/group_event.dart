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
    @JsonKey(name: 'prayer_datetime') required DateTime prayerDateTime,
    @JsonKey(name: 'prayer_place') required String prayerPlace,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'note') String? note,
    double? latitude,
    double? longitude,
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
  taraweeh('Taraweeh'),
  tahajjud('Tahajjud'),
  dhuhrAsr('Dhuhr+Asr'),
  maghribIsha('Maghrib+Isha');

  const PrayerType(this.displayName);
  final String displayName;

  String get value => displayName;

  bool get isCombined => this == dhuhrAsr || this == maghribIsha;
}
