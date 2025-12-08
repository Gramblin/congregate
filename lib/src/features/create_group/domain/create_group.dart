import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_group.freezed.dart';
part 'create_group.g.dart';

@freezed
abstract class CreateGroup with _$CreateGroup {
  const factory CreateGroup({
    required String name,
    required bool isPublic,
  }) = _CreateGroup;

  factory CreateGroup.fromJson(Map<String, dynamic> json) =>
      _$CreateGroupFromJson(json);
}
