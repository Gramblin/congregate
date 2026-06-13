import 'package:congregate/src/features/group/presentation/controller/group_controller.dart';
import 'package:congregate/src/features/home/domain/group.dart';
import 'package:congregate/src/features/home/presentation/controller/home_controller.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GroupTile extends ConsumerWidget {
  const GroupTile({
    required this.isAdmin,
    required this.group,
    this.isLeader = false,
    this.hasJoined = false,
    super.key,
  });

  final bool isAdmin;
  final bool isLeader;
  final bool hasJoined;
  final Group group;

  Future<void> _showLeaveConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${group.name}?'.hardcoded),
        content: Text(
          'Are you sure you want to leave this group? You will need to rejoin or be invited again to access it.'
              .hardcoded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'.hardcoded),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Leave'.hardcoded),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await ref.read(homeControllerProvider.notifier).leaveGroup(group.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left ${group.name}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: isAdmin ? Colors.yellow.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: ListTile(
        onTap: () => context.push(
          '/group/${group.id}'
          '?name=${Uri.encodeComponent(group.name)}'
          '&public=${group.isPublic}',
        ),
        leading: isAdmin
            ? const Icon(Icons.verified, color: Colors.amber)
            : isLeader
                ? const Icon(Icons.star, color: Colors.orange)
                : const Icon(Icons.group_outlined),
        title: Text(group.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.isPublic
                  ? 'Public • ${group.role?.capitalize() ?? ''}'
                  : 'Private • ${group.role?.capitalize() ?? ''}',
            ),
            if (group.city != null || group.country != null)
              Text(
                [
                  if (group.city != null) group.city!,
                  if (group.country != null) group.country!,
                ].join(', '),
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
        trailing: !hasJoined
            ? IconButton(
                icon: const Icon(Icons.login),
                onPressed: () async {
                  await ref
                      .read(homeControllerProvider.notifier)
                      .joinGroup(group.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Joined ${group.name}!')),
                    );
                  }
                },
              )
            : isAdmin
            ? IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                tooltip: 'Delete Group'.hardcoded,
                onPressed: () {
                  ref
                      .read(groupControllerProvider.notifier)
                      .removeGroup(group.id);
                },
              )
            : IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.grey,
                ),
                tooltip: 'Leave Group',
                onPressed: () => _showLeaveConfirmationDialog(context, ref),
              ),
      ),
    );
  }
}
