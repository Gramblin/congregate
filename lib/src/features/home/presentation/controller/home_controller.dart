import 'package:congregate/src/features/home/data/home_remote_repository.dart';
import 'package:congregate/src/features/home/domain/group.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_controller.g.dart';

@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  @override
  Future<List<Group>> build() async {
    final user = ref.watch(supabaseProvider).client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final repo = ref.watch(homeRemoteRepositoryProvider);
    return repo.fetchUserGroups(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
