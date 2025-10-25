import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@Freezed(fromJson: true, toJson: true)
abstract class Group with _$Group {
  const factory Group({
    required String id,
    required String name,
    required String topicId,
    required String visibility,
    required String createdBy,
    required DateTime createdAt,
  }) = _Group;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      visibility: json['visibility'] as String,
      topicId: json['topic_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
