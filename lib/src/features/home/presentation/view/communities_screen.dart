import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
import 'package:congregate/src/features/home/presentation/view/group_tile.dart';
import 'package:congregate/src/features/home/presentation/view/location_picker_sheet.dart';
import 'package:congregate/src/features/stories/data/story_provider.dart';
import 'package:congregate/src/features/stories/presentation/story_strip.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final asyncState = ref.watch(homeControllerProvider);
    final controller = ref.watch(homeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: location.hasLocation ? location.toString() : 'Set location',
          icon: const Icon(Icons.location_on_outlined),
          onPressed: () => _openLocationPicker(context),
        ),
        titleSpacing: 0,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search communities'.hardcoded,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile'.hardcoded,
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('❌ Error: $e')),
        data: (state) {
          final userGroups = _query.isEmpty
              ? state.userGroups
              : state.userGroups
                    .where((g) => g.name.toLowerCase().contains(_query))
                    .toList();
          final joinableGroups = _query.isEmpty
              ? state.joinableGroups
              : state.joinableGroups
                    .where((g) => g.name.toLowerCase().contains(_query))
                    .toList();

          return M3EPullToRefreshIndicator(
            onRefresh: () async {
              await controller.refreshUserGroups();
              await controller.loadJoinableGroups();
            },
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const StoryStrip(kind: StoryKind.community),
                if (location.hasLocation)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        gapW4,
                        Expanded(
                          child: Text(
                            'Showing communities in $location',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        gapW4,
                        GestureDetector(
                          onTap: () =>
                              ref.read(locationProvider.notifier).clear(),
                          child: Text(
                            'Clear'.hardcoded,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(Sizes.p16),
                  child: Text(
                    'Your Communities'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (userGroups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Sizes.p16,
                      vertical: Sizes.p8,
                    ),
                    child: Text("You're not in any communities yet."),
                  )
                else
                  ...userGroups.map(
                    (group) => GroupTile(
                      isAdmin: group.role == 'admin',
                      isLeader: group.role == 'leader',
                      group: group,
                      hasJoined: true,
                    ),
                  ),
                const Divider(height: 40),
                Padding(
                  padding: const EdgeInsets.all(Sizes.p16),
                  child: Text(
                    'Discover Communities'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (joinableGroups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sizes.p16,
                      vertical: Sizes.p8,
                    ),
                    child: Text(
                      location.hasLocation
                          ? 'No public communities in $location yet.'
                          : 'No public communities available to join.',
                    ),
                  )
                else
                  ...joinableGroups.map(
                    (group) => GroupTile(
                      isAdmin: false,
                      group: group,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openLocationPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const LocationPickerSheet(),
    );
  }
}
