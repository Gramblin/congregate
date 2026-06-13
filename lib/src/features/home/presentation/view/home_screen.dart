import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/business/presentation/view/business_list_screen.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
import 'package:congregate/src/features/home/presentation/view/group_tile.dart';
import 'package:congregate/src/features/home/presentation/view/location_picker_sheet.dart';
import 'package:congregate/src/router/scaffold_with_nav_bar.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);

    return BottomNavScaffold(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _openLocationPicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  gapW4,
                  Text(
                    location.toString(),
                    style: const TextStyle(fontSize: Sizes.p14),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Communities'.hardcoded),
                Tab(text: 'Businesses'.hardcoded),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _CommunitiesTab(location: location),
              const BusinessListScreen(),
            ],
          ),
        ),
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

class _CommunitiesTab extends ConsumerWidget {
  const _CommunitiesTab({required this.location});
  final UserLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeControllerProvider);
    final controller = ref.watch(homeControllerProvider.notifier);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('❌ Error: $e')),
      data: (state) {
        final userGroups = state.userGroups;
        final joinableGroups = state.joinableGroups;

        return Scaffold(
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                onPressed: () => context.push('/join-group'),
                heroTag: 'join_group',
                icon: const Icon(Icons.login),
                label: Text('Join'.hardcoded),
              ),
              gapH8,
              FloatingActionButton.extended(
                onPressed: () => context.push('/new-group'),
                heroTag: 'create_group',
                icon: const Icon(Icons.add),
                label: Text('New'.hardcoded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await controller.refreshUserGroups();
              await controller.loadJoinableGroups();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                if (location.hasLocation)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        gapW4,
                        Text(
                          'Showing communities in ${location}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        gapW4,
                        GestureDetector(
                          onTap: () => ref
                              .read(locationProvider.notifier)
                              .clear(),
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
                  ...userGroups.map((group) => GroupTile(
                        isAdmin: group.role == 'admin',
                        isLeader: group.role == 'leader',
                        group: group,
                        hasJoined: true,
                      )),
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
                          ? 'No public communities in ${location} yet.'
                          : 'No public communities available to join.',
                    ),
                  )
                else
                  ...joinableGroups.map((group) => GroupTile(
                        isAdmin: false,
                        group: group,
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

