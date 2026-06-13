import 'package:freezed_annotation/freezed_annotation.dart';

part 'business.freezed.dart';
part 'business.g.dart';

@freezed
abstract class Business with _$Business {
  const factory Business({
    required String id,
    required String name,
    required String category,
    required String ownerId,
    required String topicId,
    required int followerCount,
    required DateTime createdAt,
    String? description,
    String? country,
    String? city,
    String? email,
    String? phone,
    String? website,
    String? profileImageUrl,
    @Default('global') String visibility,
    @Default(true) bool contactPublic,
    @Default('approved') String approvalStatus,
    // client-side only
    bool? isFollowing,
  }) = _Business;

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'Other',
        ownerId: json['owner_id'] as String,
        topicId: json['topic_id'] as String,
        followerCount: json['follower_count'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        description: json['description'] as String?,
        country: json['country'] as String?,
        city: json['city'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        profileImageUrl: json['profile_image_url'] as String?,
        visibility: json['visibility'] as String? ?? 'global',
        contactPublic: json['contact_public'] as bool? ?? true,
        approvalStatus: json['approval_status'] as String? ?? 'approved',
      );
}
