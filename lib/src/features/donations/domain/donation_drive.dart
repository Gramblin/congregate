import 'package:freezed_annotation/freezed_annotation.dart';

part 'donation_drive.freezed.dart';
part 'donation_drive.g.dart';

@freezed
abstract class DonationDrive with _$DonationDrive {
  const factory DonationDrive({
    required String id,
    required String groupId,
    required String title,
    required String createdBy,
    required DateTime createdAt,
    @Default(true) bool isActive,
    @Default('USD') String currency,
    String? description,
    String? externalLink,
    double? goalAmount,
  }) = _DonationDrive;

  factory DonationDrive.fromJson(Map<String, dynamic> json) => DonationDrive(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        title: json['title'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isActive: json['is_active'] as bool? ?? true,
        currency: json['currency'] as String? ?? 'USD',
        description: json['description'] as String?,
        externalLink: json['external_link'] as String?,
        goalAmount: (json['goal_amount'] as num?)?.toDouble(),
      );
}
