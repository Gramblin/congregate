import 'package:congregate/src/features/group/data/group_remote_repository.dart';
import 'package:congregate/src/features/group_details/domain/group_member.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_members_provider.g.dart';

@riverpod
Future<List<GroupMember>> groupMembers(Ref ref, String groupId) async {
  final repo = ref.watch(groupRemoteRepositoryProvider);
  return repo.fetchGroupMembers(groupId);
}
