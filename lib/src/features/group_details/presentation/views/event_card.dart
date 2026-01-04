import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/data/group_events_repository.dart';
import 'package:congregate/src/features/group/presentation/controller/group_event_controller.dart';
import 'package:congregate/src/features/group_details/domain/group_event.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventCard extends ConsumerStatefulWidget {
  const EventCard({
    required this.event,
    required this.groupId,
    required this.isAdmin,
    super.key,
  });

  final GroupEvent event;
  final String groupId;
  final bool isAdmin;

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> {
  String? _userStatus;
  Map<String, int>? _counts;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) return;

    final repo = ref.read(groupEventsRepositoryProvider);

    final status = await repo.getUserAttendanceStatus(
      eventId: widget.event.id,
      userId: userId,
    );

    final counts = await repo.getAttendanceCount(widget.event.id);

    if (mounted) {
      setState(() {
        _userStatus = status;
        _counts = counts;
      });
    }
  }

  Future<void> _markAttendance(String status) async {
    final userId = ref.read(supabaseProvider).client.auth.currentUser?.id;
    if (userId == null) return;

    final repo = ref.read(groupEventsRepositoryProvider);

    await repo.markAttendance(
      eventId: widget.event.id,
      userId: userId,
      status: status,
    );

    await _loadAttendance();
  }

  bool canDeleteEvent() {
    if (widget.isAdmin) return true;
    final currentUserId = ref
        .read(supabaseProvider)
        .client
        .auth
        .currentUser!
        .id;
    return currentUserId == widget.event.createdBy;
  }

  @override
  Widget build(BuildContext context) {
    final goingCount = _counts?['going'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),

        onTap: () {
          EventAttendiesListModalSheetRoute(
            eventId: widget.event.id,
          ).push<void>(context);
        },
        child: Column(
          children: [
            ListTile(
              title: Text(
                '${widget.event.prayerType.capitalize()} Prayer',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time: ${widget.event.prayerTime}'),
                  Text('Location: ${widget.event.prayerPlace}'),
                  gapH4,
                  if (widget.event.note != null)
                    Text('Note: ${widget.event.note}'),
                  gapH4,
                  Text(
                    '$goingCount ${goingCount == 1 ? 'person' : 'people'} going',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: canDeleteEvent()
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Event'),
                            content: const Text(
                              'Are you sure you want to delete this event?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm ?? false) {
                          await ref
                              .read(groupEventControllerProvider.notifier)
                              .deleteEvent(widget.event.id, widget.groupId);
                        }
                      },
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAttendance('going'),
                      icon: Icon(
                        Icons.check_circle,
                        color: _userStatus == 'going' ? Colors.green : null,
                      ),
                      label: const FittedBox(child: Text('Going')),
                      style: _userStatus == 'going'
                          ? OutlinedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.4),
                              side: const BorderSide(color: Colors.green),
                            )
                          : null,
                    ),
                  ),
                  gapW8,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAttendance('maybe'),
                      icon: Icon(
                        Icons.help_outline,
                        color: _userStatus == 'maybe' ? Colors.orange : null,
                      ),
                      label: const FittedBox(child: Text('Maybe')),
                      style: _userStatus == 'maybe'
                          ? OutlinedButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              side: const BorderSide(color: Colors.orange),
                            )
                          : null,
                    ),
                  ),
                  gapW8,
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAttendance('not_going'),
                      icon: Icon(
                        Icons.cancel,
                        color: _userStatus == 'not_going' ? Colors.red : null,
                      ),
                      label: const FittedBox(child: Text("Can't")),
                      style: _userStatus == 'not_going'
                          ? OutlinedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              side: const BorderSide(color: Colors.red),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
