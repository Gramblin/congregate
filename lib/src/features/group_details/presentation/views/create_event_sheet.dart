import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/presentation/controller/group_event_controller.dart';
import 'package:congregate/src/features/group_details/domain/group_event.dart';
import 'package:congregate/src/router/congregate_bottom_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateEventBottomSheet extends ConsumerStatefulWidget {
  const CreateEventBottomSheet({
    required this.groupId,
    super.key,
  });

  final String groupId;

  @override
  ConsumerState<CreateEventBottomSheet> createState() =>
      _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState
    extends ConsumerState<CreateEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _placeController = TextEditingController();

  PrayerType _selectedPrayerType = PrayerType.dhuhr;
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedTimePreset;

  bool _isNextDayPrayer() {
    final now = TimeOfDay.now();
    final currentHour = now.hour;

    if (currentHour >= 21 && currentHour <= 23) {
      return _selectedPrayerType == PrayerType.tahajjud ||
          _selectedPrayerType == PrayerType.fajr;
    }
    return false;
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _selectedTimePreset = 'custom';
      });
    }
  }

  void _setTimePreset(int minutes, String presetKey) {
    final now = TimeOfDay.now();
    final newTime = TimeOfDay(
      hour: (now.hour + (now.minute + minutes) ~/ 60) % 24,
      minute: (now.minute + minutes) % 60,
    );
    setState(() {
      _selectedTime = newTime;
      _selectedTimePreset = presetKey;
    });
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isNextDayPrayer()) {
      final now = TimeOfDay.now();
      final selectedMinutes = _selectedTime.hour * 60 + _selectedTime.minute;
      final currentMinutes = now.hour * 60 + now.minute;

      if (selectedMinutes < currentMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot schedule prayer in the past'.hardcoded),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final timeString =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    // Calculate the event date
    final eventDate = _isNextDayPrayer()
        ? DateTime.now().add(const Duration(days: 1))
        : DateTime.now();

    await ref
        .read(groupEventControllerProvider.notifier)
        .createEventAndNotify(
          groupId: widget.groupId,
          prayerType: _selectedPrayerType.value,
          prayerTime: timeString,
          prayerPlace: _placeController.text.trim(),
          eventDate: eventDate,
        );

    if (mounted) {
      Navigator.pop(context);
      final dayText = _isNextDayPrayer() ? 'tomorrow' : 'today';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Event created for $dayText and notification sent!'.hardcoded,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupEventControllerProvider);

    return CongregateBottomSheet(
      children: [
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Prayer Event'.hardcoded,
                  style: const TextStyle(
                    fontSize: Sizes.p20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                gapH16,
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prayer Type'.hardcoded,
                        style: const TextStyle(
                          fontSize: Sizes.p16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      gapH16,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PrayerType.values.map((prayerType) {
                          final isSelected = _selectedPrayerType == prayerType;
                          return FilterChip(
                            label: Text(prayerType.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPrayerType = prayerType;
                              });
                            },
                            selectedColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            checkmarkColor: Theme.of(context).primaryColor,
                          );
                        }).toList(),
                      ),
                      // Add helper text for next-day prayers
                      if (_isNextDayPrayer())
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'This will be scheduled for tomorrow'.hardcoded,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      gapH16,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.access_time),
                            title: Text('Prayer Time'.hardcoded),
                            subtitle: Text(_selectedTime.format(context)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: Text('In 10 min'.hardcoded),
                                selected: _selectedTimePreset == '10min',
                                onSelected: (_) => _setTimePreset(10, '10min'),
                              ),
                              FilterChip(
                                label: Text('In 20 min'.hardcoded),
                                selected: _selectedTimePreset == '20min',
                                onSelected: (_) => _setTimePreset(20, '20min'),
                              ),
                              FilterChip(
                                label: Text('In 30 min'.hardcoded),
                                selected: _selectedTimePreset == '30min',
                                onSelected: (_) => _setTimePreset(30, '30min'),
                              ),
                              FilterChip(
                                label: Text('In 45 min'.hardcoded),
                                selected: _selectedTimePreset == '45min',
                                onSelected: (_) => _setTimePreset(45, '45min'),
                              ),
                              FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Custom'.hardcoded),
                                  ],
                                ),
                                selected: _selectedTimePreset == 'custom',
                                onSelected: (_) => _selectTime(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      gapH16,
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
                gapH24,
                Row(
                  spacing: Sizes.p12,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text('Cancel'.hardcoded),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.isLoading ? null : _createEvent,
                        child: state.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Create & Notify'.hardcoded),
                      ),
                    ),
                  ],
                ),
                gapH16,
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }
}
