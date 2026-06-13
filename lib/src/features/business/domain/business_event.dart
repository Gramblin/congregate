import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_event.freezed.dart';
part 'business_event.g.dart';

@freezed
abstract class BusinessEvent with _$BusinessEvent {
  const factory BusinessEvent({
    required String id,
    required String businessId,
    required String title,
    required String createdBy,
    required DateTime createdAt,
    String? description,
    String? imageUrl,
    @Default('event') String type,
    double? price,
    DateTime? startAt,
    DateTime? endAt,
  }) = _BusinessEvent;

  factory BusinessEvent.fromJson(Map<String, dynamic> json) => BusinessEvent(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        title: json['title'] as String,
        createdBy: json['created_by'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        type: json['type'] as String? ?? 'event',
        price: (json['price'] as num?)?.toDouble(),
        startAt: json['start_at'] != null
            ? DateTime.parse(json['start_at'] as String)
            : null,
        endAt: json['end_at'] != null
            ? DateTime.parse(json['end_at'] as String)
            : null,
      );
}
