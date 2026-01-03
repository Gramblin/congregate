import 'package:congregate/src/features/group/presentation/controller/group_event_controller.dart';
import 'package:congregate/src/features/group_details/domain/group_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateEventDialog extends ConsumerStatefulWidget {
  const CreateEventDialog({
    required this.groupId,
    super.key,
  });

  final String groupId;

  @override
  ConsumerState<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends ConsumerState<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();

  PrayerType _selectedPrayerType = PrayerType.dhuhr;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    await ref
        .read(groupEventControllerProvider.notifier)
        .createEventAndNotify(
          groupId: widget.groupId,
          prayerType: _selectedPrayerType.value,
          prayerTime: timeString,
          prayerPlace: _placeController.text.trim(),
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created and notification sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupEventControllerProvider);

    return AlertDialog(
      title: const Text('Create Prayer Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prayer Type Dropdown
              DropdownButtonFormField<PrayerType>(
                initialValue: _selectedPrayerType,
                decoration: const InputDecoration(
                  labelText: 'Prayer Type',
                  prefixIcon: Icon(Icons.mosque),
                ),
                items: PrayerType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPrayerType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Prayer Time'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _selectTime,
              ),
              const SizedBox(height: 16),

              // Place TextField
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: 'Prayer Place',
                  hintText: 'e.g., Main Mosque, Prayer Room',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a place';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: state.isLoading ? null : _createEvent,
          child: state.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create & Notify'),
        ),
      ],
    );
  }
}
