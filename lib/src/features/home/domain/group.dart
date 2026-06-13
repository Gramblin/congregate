import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@Freezed(fromJson: true, toJson: true)
abstract class Group with _$Group {
  const factory Group({
    required String id,
    required String name,
    required String topicId,
    @JsonKey(name: 'is_public') required bool isPublic,
    required String createdBy,
    required DateTime createdAt,
    String? role,
    String? country,
    String? city,
    String? description,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      isPublic: json['is_public'] as bool? ?? false,
      topicId: json['topic_id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      role: json['role'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      description: json['description'] as String?,
    );
  }
}
