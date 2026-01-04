import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/presentation/controller/group_event_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class EventAttendeesListSheet extends ConsumerStatefulWidget {
  const EventAttendeesListSheet({required this.eventId, super.key});
  final String eventId;

  @override
  ConsumerState<EventAttendeesListSheet> createState() =>
      _EventAttendeesListSheetState();
}

class _EventAttendeesListSheetState
    extends ConsumerState<EventAttendeesListSheet> {
  @override
  Widget build(BuildContext context) {
    return Sheet(
      decoration: MaterialSheetDecoration(
        size: SheetSize.fit,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: Theme.of(context).colorScheme.secondaryContainer,
        elevation: 4,
      ),
      snapGrid: const SheetSnapGrid(
        snaps: [SheetOffset(0.7), SheetOffset(1)],
      ),
      scrollConfiguration: const SheetScrollConfiguration(),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: context.pop,
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: ref
                .watch(eventAttendeesProvider(widget.eventId))
                .when(
                  data: (data) {
                    // First, separate attendees by status
                    final going =
                        data.where((a) => a.status == 'going').toList()..sort(
                          (a, b) => b.respondedAt.compareTo(a.respondedAt),
                        );
                    final maybe =
                        data.where((a) => a.status == 'maybe').toList()..sort(
                          (a, b) => b.respondedAt.compareTo(a.respondedAt),
                        );
                    final notGoing =
                        data.where((a) => a.status == 'not_going').toList()
                          ..sort(
                            (a, b) => b.respondedAt.compareTo(a.respondedAt),
                          );

                    return ListView(
                      children: [
                        if (going.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Going (${going.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...going.map(
                            (attendee) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(0.2),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              title: Text(attendee.displayName ?? 'Unknown'),
                              subtitle: Text(_formatTime(attendee.respondedAt)),
                            ),
                          ),
                          const Divider(),
                        ],
                        if (maybe.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.help_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Maybe (${maybe.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...maybe.map(
                            (attendee) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.withOpacity(0.2),
                                child: const Icon(
                                  Icons.help_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                              title: Text(attendee.displayName ?? 'Unknown'),
                              subtitle: Text(_formatTime(attendee.respondedAt)),
                            ),
                          ),
                          const Divider(),
                        ],
                        if (notGoing.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(Sizes.p16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                gapW8,
                                Text(
                                  'Not Going (${notGoing.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...notGoing.map(
                            (attendee) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                child: const Icon(
                                  Icons.cancel,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ),
                              title: Text(attendee.displayName ?? 'Unknown'),
                              subtitle: Text(_formatTime(attendee.respondedAt)),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  error: (error, stackTrace) => Text('Error: $error'),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
