import 'package:freezed_annotation/freezed_annotation.dart';

part 'ad.freezed.dart';
part 'ad.g.dart';

@freezed
abstract class Ad with _$Ad {
  const factory Ad({
    required String id,
    required String title,
    required String bannerImageUrl,
    required String htmlContent,
    required bool isActive,
    required int sortOrder,
    required DateTime createdAt,
    String? businessId,
    String? linkUrl,
    DateTime? startsAt,
    DateTime? endsAt,
  }) = _Ad;

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
        id: json['id'] as String,
        title: json['title'] as String,
        bannerImageUrl: json['banner_image_url'] as String,
        htmlContent: json['html_content'] as String,
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        businessId: json['business_id'] as String?,
        linkUrl: json['link_url'] as String?,
        startsAt: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'] as String)
            : null,
        endsAt: json['ends_at'] != null
            ? DateTime.parse(json['ends_at'] as String)
            : null,
      );
}
