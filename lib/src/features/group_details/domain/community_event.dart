import 'package:congregate/src/features/group_details/domain/group_event.dart';

class CommunityEvent {
  const CommunityEvent({
    required this.id,
    required this.groupId,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    this.description,
    this.place,
    this.note,
    this.eventDatetime,
    this.sponsors = const [],
  });

  final String id;
  final String groupId;
  final String title;
  final String createdBy;
  final DateTime createdAt;
  final String? description;
  final String? place;
  final String? note;
  final DateTime? eventDatetime;
  final List<EventSponsor> sponsors;

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    final sponsorRows =
        json['community_event_sponsors'] as List<dynamic>? ?? [];
    final sponsors = sponsorRows.map((s) {
      final biz = s['businesses'] as Map<String, dynamic>?;
      return EventSponsor(
        businessId: s['business_id'] as String,
        businessName: biz?['name'] as String? ?? '',
        profileImageUrl: biz?['profile_image_url'] as String?,
      );
    }).toList();

    return CommunityEvent(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      place: json['place'] as String?,
      note: json['note'] as String?,
      eventDatetime: json['event_datetime'] != null
          ? DateTime.parse(json['event_datetime'] as String)
          : null,
      sponsors: sponsors,
    );
  }
}
