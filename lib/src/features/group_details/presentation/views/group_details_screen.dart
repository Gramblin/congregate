import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/data/group_events_repository.dart';
import 'package:congregate/src/features/group/data/group_remote_repository.dart';
import 'package:congregate/src/features/group_details/presentation/controllers/group_members_provider.dart';
import 'package:congregate/src/features/group_details/presentation/views/event_card.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:go_router/go_router.dart';
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
  bool _isLeader = false;

  @override
  void initState() {
    super.initState();
    _checkRoles();
  }

  Future<void> _checkRoles() async {
    final members = await ref.read(groupMembersProvider(widget.groupId).future);
    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;

    if (userId != null && mounted) {
      final myMember = members.where((m) => m.userId == userId).firstOrNull;
      setState(() {
        _isAdmin = myMember?.role == 'admin';
        _isLeader = myMember?.role == 'leader';
      });
    }
  }

  Future<void> _updateMemberRole(String targetUserId, String newRole) async {
    try {
      await ref
          .read(groupRemoteRepositoryProvider)
          .updateMemberRole(
            groupId: widget.groupId,
            targetUserId: targetUserId,
            newRole: newRole,
          );
      ref.invalidate(groupMembersProvider(widget.groupId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
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
        actions: (_isAdmin || _isLeader)
            ? [
                if (_isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () =>
                        context.push('/share-group/${widget.groupId}'),
                  ),
                  IconButton(
                    onPressed: () => context.push(
                      '/edit-group/${widget.groupId}'
                      '?name=${Uri.encodeComponent(widget.groupName)}'
                      '&public=${widget.isPublic}',
                    ),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ]
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-event/${widget.groupId}'),
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
                ...(members.toList()
                      ..sort((a, b) {
                        const order = {'admin': 0, 'leader': 1, 'member': 2};
                        return (order[a.role] ?? 2)
                            .compareTo(order[b.role] ?? 2);
                      }))
                    .map(
                      (m) => ListTile(
                        leading: Icon(
                          m.role == 'admin'
                              ? Icons.verified
                              : m.role == 'leader'
                                  ? Icons.star
                                  : Icons.person_outline,
                          color: m.role == 'admin'
                              ? Colors.amber
                              : m.role == 'leader'
                                  ? Colors.orange
                                  : null,
                        ),
                        title: Text(m.displayName),
                        subtitle: Text(m.role.capitalize()),
                        trailing: _isAdmin && m.role != 'admin'
                            ? PopupMenuButton<String>(
                                tooltip: 'Change role',
                                onSelected: (newRole) =>
                                    _updateMemberRole(m.userId, newRole),
                                itemBuilder: (_) => [
                                  if (m.role != 'leader')
                                    const PopupMenuItem(
                                      value: 'leader',
                                      child: Text('Promote to Leader'),
                                    ),
                                  if (m.role != 'member')
                                    const PopupMenuItem(
                                      value: 'member',
                                      child: Text('Demote to Member'),
                                    ),
                                ],
                              )
                            : null,
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
