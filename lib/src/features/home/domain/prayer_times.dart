import 'package:congregate/src/features/group_details/domain/group_event.dart';

class PrayerTimes {
  const PrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  DateTime? timeFor(PrayerType type) => switch (type) {
        PrayerType.fajr => fajr,
        PrayerType.dhuhr => dhuhr,
        PrayerType.asr => asr,
        PrayerType.maghrib => maghrib,
        PrayerType.isha => isha,
        _ => null,
      };

  bool hasPassed(PrayerType type) {
    final t = timeFor(type);
    return t != null && DateTime.now().isAfter(t);
  }

  /// Next prayer that hasn't started yet. Null if all have passed (use fajr tomorrow).
  PrayerType? get nextPrayer {
    final now = DateTime.now();
    for (final t in [
      (PrayerType.fajr, fajr),
      (PrayerType.dhuhr, dhuhr),
      (PrayerType.asr, asr),
      (PrayerType.maghrib, maghrib),
      (PrayerType.isha, isha),
    ]) {
      if (now.isBefore(t.$2)) return t.$1;
    }
    return null; // all passed — caller should use fajr for tomorrow
  }

  factory PrayerTimes.fromApiTimings(
    Map<String, dynamic> timings,
    DateTime date,
  ) {
    DateTime parse(String key) {
      final parts = (timings[key] as String).split(':');
      return DateTime(
        date.year, date.month, date.day,
        int.parse(parts[0]), int.parse(parts[1]),
      );
    }

    return PrayerTimes(
      fajr: parse('Fajr'),
      dhuhr: parse('Dhuhr'),
      asr: parse('Asr'),
      maghrib: parse('Maghrib'),
      isha: parse('Isha'),
    );
  }

  Map<String, dynamic> toJson() => {
        'fajr': fajr.toIso8601String(),
        'dhuhr': dhuhr.toIso8601String(),
        'asr': asr.toIso8601String(),
        'maghrib': maghrib.toIso8601String(),
        'isha': isha.toIso8601String(),
      };

  factory PrayerTimes.fromJson(Map<String, dynamic> json) => PrayerTimes(
        fajr: DateTime.parse(json['fajr'] as String),
        dhuhr: DateTime.parse(json['dhuhr'] as String),
        asr: DateTime.parse(json['asr'] as String),
        maghrib: DateTime.parse(json['maghrib'] as String),
        isha: DateTime.parse(json['isha'] as String),
      );
}
