import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/data/group_events_repository.dart';
import 'package:congregate/src/features/group/presentation/controller/group_controller.dart';
import 'package:congregate/src/features/group_details/presentation/controllers/group_members_provider.dart';
import 'package:congregate/src/features/group_details/presentation/views/event_card.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({
    required this.groupId,
    required this.groupName,
    required this.isPublic,
    super.key,
  });

  final String groupId;
  final String groupName;
  final bool isPublic;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final members = await ref.read(groupMembersProvider(widget.groupId).future);
    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;

    if (userId != null && mounted) {
      final currentMember = members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => members.first,
      );
      setState(() {
        _isAdmin = currentMember.role == 'admin';
      });
    }
  }

  Future<void> _onRefresh() async {
    ref
      ..invalidate(groupEventsProvider(widget.groupId))
      ..invalidate(groupMembersProvider(widget.groupId));

    await Future.wait([
      ref.read(groupEventsProvider(widget.groupId).future),
      ref.read(groupMembersProvider(widget.groupId).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final asyncMembers = ref.watch(groupMembersProvider(widget.groupId));
    final asyncEvents = ref.watch(groupEventsProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => ref
                      .read(groupControllerProvider.notifier)
                      .createAndShareInvite(groupId: widget.groupId),
                ),
                IconButton(
                  onPressed: () {
                    EditGroupDetailsModalSheetRoute(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                      isPublic: widget.isPublic,
                    ).push<void>(context);
                  },
                  icon: const Icon(Icons.edit),
                ),
              ]
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateEventModalSheetRoute(
          groupId: widget.groupId,
        ).push<void>(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Prayer Event'),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: asyncMembers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (members) {
            return ListView(
              padding: const EdgeInsets.all(Sizes.p16),
              children: [
                Text(
                  'Upcoming Prayer Events'.hardcoded,
                  style: const TextStyle(
                    fontSize: Sizes.p20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH8,
                asyncEvents.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Sizes.p16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('Error loading events: $e'),
                  data: (events) {
                    if (events.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(Sizes.p16),
                        child: Text(
                          'No upcoming events. Create one!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return Column(
                      children: events
                          .map(
                            (event) => EventCard(
                              event: event,
                              groupId: widget.groupId,
                              isAdmin: _isAdmin,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const Divider(height: 32),
                Text(
                  'Members'.hardcoded,
                  style: const TextStyle(
                    fontSize: Sizes.p20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH8,
                ...(members.toList()..sort((a, b) {
                      if (a.role == 'admin' && b.role != 'admin') return -1;
                      if (a.role != 'admin' && b.role == 'admin') return 1;
                      return 0;
                    }))
                    .map(
                      (m) => ListTile(
                        leading: Icon(
                          m.role == 'admin' ? Icons.star : Icons.person_outline,
                          color: m.role == 'admin' ? Colors.amber : null,
                        ),
                        title: Text(m.displayName),
                        subtitle: Text(m.role == 'admin' ? 'Admin' : 'Member'),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}
