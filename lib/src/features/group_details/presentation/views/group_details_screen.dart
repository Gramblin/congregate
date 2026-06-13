import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/donations/data/donation_drives_repository.dart';
import 'package:congregate/src/features/donations/domain/donation_drive.dart';
import 'package:congregate/src/features/donations/presentation/controller/donation_drive_controller.dart';
import 'package:congregate/src/features/donations/presentation/view/create_donation_drive_sheet.dart';
import 'package:congregate/src/features/group/data/group_events_repository.dart';
import 'package:congregate/src/features/group/data/group_remote_repository.dart';
import 'package:congregate/src/features/group_details/data/community_events_repository.dart';
import 'package:congregate/src/features/group_details/domain/community_event.dart';
import 'package:congregate/src/features/group_details/presentation/controllers/group_members_provider.dart';
import 'package:congregate/src/features/group_details/presentation/views/create_community_event_sheet.dart';
import 'package:congregate/src/features/group_details/presentation/views/event_card.dart';
import 'package:congregate/src/features/profile/data/profile_stats_repository.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
      ..invalidate(groupMembersProvider(widget.groupId))
      ..invalidate(donationDrivesProvider(widget.groupId))
      ..invalidate(communityEventsProvider(widget.groupId));

    await Future.wait([
      ref.read(groupEventsProvider(widget.groupId).future),
      ref.read(groupMembersProvider(widget.groupId).future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final asyncMembers = ref.watch(groupMembersProvider(widget.groupId));
    final asyncEvents = ref.watch(groupEventsProvider(widget.groupId));
    final asyncDrives = ref.watch(donationDrivesProvider(widget.groupId));
    final asyncImpact = ref.watch(communityImpactProvider(widget.groupId));
    final asyncCommunityEvents =
        ref.watch(communityEventsProvider(widget.groupId));

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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAdmin) ...[
            FloatingActionButton.extended(
              heroTag: 'donation_drive',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    CreateDonationDriveSheet(groupId: widget.groupId),
              ),
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: const Text('Donation Drive'),
            ),
            gapH8,
            FloatingActionButton.extended(
              heroTag: 'community_event',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    CreateCommunityEventSheet(groupId: widget.groupId),
              ),
              icon: const Icon(Icons.event_outlined),
              label: const Text('Create Event'),
            ),
            gapH8,
          ],
          FloatingActionButton.extended(
            heroTag: 'prayer_event',
            onPressed: () => context.push('/create-event/${widget.groupId}'),
            icon: const Icon(Icons.mosque_outlined),
            label: const Text('Prayer Event'),
          ),
        ],
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
                // Community events
                asyncCommunityEvents.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cEvents) {
                    if (cEvents.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events'.hardcoded,
                          style: const TextStyle(
                            fontSize: Sizes.p20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        gapH8,
                        ...cEvents.map(
                          (e) => _CommunityEventCard(
                            event: e,
                            isAdminOrLeader: _isAdmin || _isLeader,
                            groupId: widget.groupId,
                          ),
                        ),
                        const Divider(height: 32),
                      ],
                    );
                  },
                ),
                // Donation drives
                asyncDrives.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (drives) {
                    if (drives.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.volunteer_activism_outlined,
                              size: 20,
                            ),
                            gapW8,
                            Text(
                              'Donation Drives'.hardcoded,
                              style: const TextStyle(
                                fontSize: Sizes.p20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        gapH8,
                        ...drives.map(
                          (d) => _DonationDriveCard(
                            drive: d,
                            isAdmin: _isAdmin,
                            groupId: widget.groupId,
                          ),
                        ),
                        const Divider(height: 32),
                      ],
                    );
                  },
                ),
                // Community impact strip
                asyncImpact.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (impact) => Padding(
                    padding: const EdgeInsets.only(bottom: Sizes.p12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ImpactStat(
                          icon: Icons.mosque_outlined,
                          value: impact.totalEvents,
                          label: 'Prayers',
                        ),
                        _ImpactStat(
                          icon: Icons.people_outlined,
                          value: impact.totalMembers,
                          label: 'Members',
                        ),
                        _ImpactStat(
                          icon: Icons.volunteer_activism_outlined,
                          value: impact.activeDonations,
                          label: 'Drives',
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
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

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        gapH4,
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: Sizes.p16),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _DonationDriveCard extends ConsumerWidget {
  const _DonationDriveCard({
    required this.drive,
    required this.isAdmin,
    required this.groupId,
  });
  final DonationDrive drive;
  final bool isAdmin;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.p8),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.volunteer_activism_outlined,
                  color: Colors.green,
                  size: 18,
                ),
                gapW8,
                Expanded(
                  child: Text(
                    drive.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Sizes.p16,
                    ),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Close drive',
                    onPressed: () => ref
                        .read(donationDriveProvider.notifier)
                        .deactivate(drive.id, groupId),
                  ),
              ],
            ),
            if (drive.description != null) ...[
              gapH4,
              Text(drive.description!),
            ],
            if (drive.goalAmount != null) ...[
              gapH4,
              Text(
                'Goal: ${drive.currency} ${drive.goalAmount!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
            if (drive.externalLink != null) ...[
              gapH8,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      launchUrl(Uri.parse(drive.externalLink!)),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Donate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommunityEventCard extends ConsumerWidget {
  const _CommunityEventCard({
    required this.event,
    required this.isAdminOrLeader,
    required this.groupId,
  });
  final CommunityEvent event;
  final bool isAdminOrLeader;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('d MMM y · HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: Sizes.p8),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18),
                gapW8,
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Sizes.p16,
                    ),
                  ),
                ),
                if (isAdminOrLeader)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      await ref
                          .read(communityEventsRepositoryProvider)
                          .delete(event.id);
                      ref.invalidate(communityEventsProvider(groupId));
                    },
                  ),
              ],
            ),
            if (event.description != null) ...[
              gapH4,
              Text(event.description!),
            ],
            if (event.place != null) ...[
              gapH4,
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14),
                gapW4,
                Text(event.place!, style: const TextStyle(fontSize: 12)),
              ]),
            ],
            if (event.eventDatetime != null) ...[
              gapH4,
              Row(children: [
                const Icon(Icons.access_time, size: 14),
                gapW4,
                Text(
                  fmt.format(event.eventDatetime!.toLocal()),
                  style: const TextStyle(fontSize: 12),
                ),
              ]),
            ],
            if (event.sponsors.isNotEmpty) ...[
              gapH8,
              Wrap(
                spacing: 6,
                children: event.sponsors.map((s) => Chip(
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: s.profileImageUrl != null
                      ? CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            s.profileImageUrl!,
                          ),
                        )
                      : const Icon(Icons.store_outlined, size: 14),
                  label: Text(
                    s.businessName,
                    style: const TextStyle(fontSize: 11),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
