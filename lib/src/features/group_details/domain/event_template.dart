import 'package:uuid/uuid.dart';

class EventTemplate {
  const EventTemplate({
    required this.id,
    required this.name,
    required this.prayerPlace,
    this.note,
    this.latitude,
    this.longitude,
  });

  factory EventTemplate.create({
    required String prayerPlace,
    String? note,
    double? latitude,
    double? longitude,
  }) => EventTemplate(
    id: const Uuid().v4(),
    name: prayerPlace,
    prayerPlace: prayerPlace,
    note: note,
    latitude: latitude,
    longitude: longitude,
  );

  factory EventTemplate.fromJson(Map<String, dynamic> json) => EventTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    prayerPlace: json['prayerPlace'] as String,
    note: json['note'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  final String id;
  final String name;
  final String prayerPlace;
  final String? note;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'prayerPlace': prayerPlace,
    if (note != null) 'note': note,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}
