import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/business/data/business_remote_repository.dart';
import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/features/group_details/data/community_events_repository.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CreateCommunityEventSheet extends ConsumerStatefulWidget {
  const CreateCommunityEventSheet({required this.groupId, super.key});
  final String groupId;

  @override
  ConsumerState<CreateCommunityEventSheet> createState() =>
      _CreateCommunityEventSheetState();
}

class _CreateCommunityEventSheetState
    extends ConsumerState<CreateCommunityEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _eventDatetime;
  final List<Business> _sponsors = [];
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _placeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _eventDatetime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _pickSponsor() async {
    final businesses =
        await ref.read(businessRemoteRepositoryProvider).fetchBusinesses();
    if (!mounted) return;
    final selected = await showModalBottomSheet<Business>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BizPicker(
        businesses: businesses,
        alreadySelected: _sponsors.map((b) => b.id).toSet(),
      ),
    );
    if (selected != null && !_sponsors.any((b) => b.id == selected.id)) {
      setState(() => _sponsors.add(selected));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(communityEventsRepositoryProvider).create(
            groupId: widget.groupId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            place: _placeCtrl.text.trim().isEmpty
                ? null
                : _placeCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            eventDatetime: _eventDatetime,
            sponsorBusinessIds: _sponsors.map((b) => b.id).toList(),
          );
      ref.invalidate(communityEventsProvider(widget.groupId));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM y · HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(Sizes.p16),
            children: [
              Row(
                children: [
                  const Icon(Icons.event_outlined),
                  gapW8,
                  Text(
                    'Create Event'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              gapH16,
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event title',
                  hintText: 'e.g. Community BBQ, Charity Run',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              gapH12,
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              gapH12,
              TextFormField(
                controller: _placeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Place (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              gapH12,
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  _eventDatetime != null
                      ? fmt.format(_eventDatetime!)
                      : 'Set date & time (optional)',
                ),
              ),
              gapH12,
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              gapH16,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sponsors'.hardcoded,
                    style: const TextStyle(
                      fontSize: Sizes.p14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickSponsor,
                    icon: const Icon(Icons.add_business, size: 16),
                    label: Text('Add sponsor'.hardcoded),
                  ),
                ],
              ),
              if (_sponsors.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _sponsors
                      .map(
                        (b) => Chip(
                          avatar: b.profileImageUrl != null
                              ? CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                    b.profileImageUrl!,
                                  ),
                                )
                              : null,
                          label: Text(b.name),
                          onDeleted: () =>
                              setState(() => _sponsors.remove(b)),
                        ),
                      )
                      .toList(),
                ),
              gapH24,
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text('Create Event'.hardcoded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BizPicker extends StatefulWidget {
  const _BizPicker({required this.businesses, required this.alreadySelected});
  final List<Business> businesses;
  final Set<String> alreadySelected;

  @override
  State<_BizPicker> createState() => _BizPickerState();
}

class _BizPickerState extends State<_BizPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final filtered = q.isEmpty
        ? widget.businesses
        : widget.businesses
            .where((b) => b.name.toLowerCase().contains(q))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search businesses',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No businesses found'))
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final b = filtered[i];
                      final already = widget.alreadySelected.contains(b.id);
                      return ListTile(
                        leading: b.profileImageUrl != null
                            ? CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                  b.profileImageUrl!,
                                ),
                              )
                            : CircleAvatar(child: Text(b.name[0])),
                        title: Text(b.name),
                        subtitle: Text(b.category),
                        trailing: already
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                        onTap:
                            already ? null : () => Navigator.pop(context, b),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
