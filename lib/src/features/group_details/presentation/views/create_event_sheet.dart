import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/group/presentation/controller/group_event_controller.dart';
import 'package:congregate/src/features/group_details/data/event_template_repository.dart';
import 'package:congregate/src/features/group_details/domain/event_template.dart';
import 'package:congregate/src/features/group_details/domain/group_event.dart';
import 'package:congregate/src/features/group_details/presentation/views/map_location_picker.dart';
import 'package:congregate/src/features/home/data/prayer_times_repository.dart';
import 'package:congregate/src/features/home/domain/prayer_times.dart';
import 'package:congregate/src/router/congregate_bottom_sheet.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  final _noteController = TextEditingController();

  LatLng? _pickedLocation;
  bool _locating = false;
  bool _prayerTimesInitialized = false;

  PrayerType _selectedPrayerType = PrayerType.dhuhr;
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _congregateOffset = 0;
  String? _congregateOffsetKey;

  @override
  void initState() {
    super.initState();
    _placeController.addListener(() => setState(() {}));
  }

  bool _isNextDayPrayer() {
    final now = TimeOfDay.now();
    final currentHour = now.hour;

    if (currentHour >= 21 && currentHour <= 23) {
      return _selectedPrayerType == PrayerType.tahajjud ||
          _selectedPrayerType == PrayerType.fajr;
    }
    return false;
  }

  TimeOfDay get _congregateTime {
    final now = DateTime.now();
    final selectedDt = DateTime(
      now.year, now.month, now.day,
      _selectedTime.hour, _selectedTime.minute,
    );
    final base = selectedDt.isAfter(now) ? selectedDt : now;
    final adjusted = base.add(Duration(minutes: _congregateOffset));
    return TimeOfDay(hour: adjusted.hour % 24, minute: adjusted.minute);
  }

  bool get _isPrayerFuture {
    final now = DateTime.now();
    final dt = DateTime(
      now.year, now.month, now.day,
      _selectedTime.hour, _selectedTime.minute,
    );
    return dt.isAfter(now);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _congregateOffset = 0;
        _congregateOffsetKey = null;
      });
    }
  }

  void _setTimePreset(int minutes, String presetKey) {
    setState(() {
      _congregateOffset = minutes;
      _congregateOffsetKey = presetKey;
    });
  }

  /// Apply a prayer time from the API result — auto-selects type and time.
  void _applyPrayerTimes(PrayerTimes pt) {
    if (_prayerTimesInitialized) return;
    _prayerTimesInitialized = true;

    final next = pt.nextPrayer ?? PrayerType.fajr;
    final time = pt.timeFor(next) ?? DateTime.now();
    setState(() {
      _selectedPrayerType = next;
      _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
      _congregateOffset = 0;
      _congregateOffsetKey = null;
    });
  }

  void _selectPrayerType(PrayerType type, PrayerTimes? pt) {
    final time = pt?.timeFor(type);
    setState(() {
      _selectedPrayerType = type;
      if (time != null) {
        _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
        _congregateOffset = 0;
        _congregateOffsetKey = null;
      }
    });
  }


  void _applyTemplate(EventTemplate t) {
    setState(() {
      _placeController.text = t.prayerPlace;
      _noteController.text = t.note ?? '';
      _pickedLocation = t.latitude != null && t.longitude != null
          ? LatLng(t.latitude!, t.longitude!)
          : null;
    });
  }

  Future<void> _saveAsTemplate() async {
    final place = _placeController.text.trim();
    if (place.isEmpty) return;
    final template = EventTemplate.create(
      prayerPlace: place,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      latitude: _pickedLocation?.latitude,
      longitude: _pickedLocation?.longitude,
    );
    await ref.read(eventTemplateProvider.notifier).save(template);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$place" saved as template'.hardcoded)),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission denied. Enable it in Settings.',
              ),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _pickedLocation = LatLng(pos.latitude, pos.longitude));
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute<LatLng>(
        builder: (_) => MapLocationPicker(initial: _pickedLocation),
      ),
    );
    if (result != null && mounted) {
      setState(() => _pickedLocation = result);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // Build the complete prayer datetime in local timezone
    final now = DateTime.now();
    final eventDate = _isNextDayPrayer()
        ? DateTime(now.year, now.month, now.day + 1)
        : DateTime(now.year, now.month, now.day);

    final congregate = _congregateTime;
    final prayerDateTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      congregate.hour,
      congregate.minute,
    );

    // Validate it's not in the past
    if (prayerDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot schedule prayer in the past'.hardcoded),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref
        .read(groupEventControllerProvider.notifier)
        .createEventAndNotify(
          groupId: widget.groupId,
          prayerType: _selectedPrayerType.value,
          prayerDateTime: prayerDateTime,
          prayerPlace: _placeController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          latitude: _pickedLocation?.latitude,
          longitude: _pickedLocation?.longitude,
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
    final prayerTimesAsync = ref.watch(todayPrayerTimesProvider);
    final prayerTimes = prayerTimesAsync.value;
    final templates = ref.watch(eventTemplateProvider);

    ref.listen<AsyncValue<PrayerTimes?>>(todayPrayerTimesProvider, (_, next) {
      next.whenData((pt) {
        if (pt != null) _applyPrayerTimes(pt);
      });
    });

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
                      if (templates.isNotEmpty) ...[
                        Text(
                          'Templates'.hardcoded,
                          style: const TextStyle(
                            fontSize: Sizes.p14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        gapH8,
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: templates
                              .map(
                                (t) => InputChip(
                                  label: Text(t.name),
                                  onPressed: () => _applyTemplate(t),
                                  onDeleted: () => ref
                                      .read(
                                        eventTemplateProvider.notifier,
                                      )
                                      .delete(t.id),
                                ),
                              )
                              .toList(),
                        ),
                        gapH16,
                      ],
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
                            onSelected: (_) =>
                                _selectPrayerType(prayerType, prayerTimes),
                            selectedColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: Theme.of(context).primaryColor,
                          );
                        }).toList(),
                      ),
                      if (_isNextDayPrayer())
                        Padding(
                          padding: const EdgeInsets.only(top: Sizes.p8),
                          child: Text(
                            'This will be scheduled for tomorrow'.hardcoded,
                            style: TextStyle(
                              fontSize: Sizes.p12,
                              color: Theme.of(context).primaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      gapH16,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20),
                              gapW8,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Prayer Time'.hardcoded,
                                          style: const TextStyle(
                                            fontSize: Sizes.p14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (prayerTimesAsync.isLoading) ...[
                                          gapW8,
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(
                                        fontSize: Sizes.p16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_congregateOffset > 0) ...[
                                const SizedBox(
                                  height: 40,
                                  child: VerticalDivider(width: 24),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Congregate at'.hardcoded,
                                        style: const TextStyle(
                                          fontSize: Sizes.p14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${_congregateTime.hour.toString().padLeft(2, '0')}:${_congregateTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: Sizes.p16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          gapH8,
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...() {
                                final future = _isPrayerFuture;
                                String label(int m) =>
                                    future ? '+${m}m' : 'in ${m}m';
                                return [
                                  FilterChip(
                                    label: Text(label(10).hardcoded),
                                    selected: _congregateOffsetKey == '10min',
                                    onSelected: (_) =>
                                        _setTimePreset(10, '10min'),
                                  ),
                                  FilterChip(
                                    label: Text(label(20).hardcoded),
                                    selected: _congregateOffsetKey == '20min',
                                    onSelected: (_) =>
                                        _setTimePreset(20, '20min'),
                                  ),
                                  FilterChip(
                                    label: Text(label(30).hardcoded),
                                    selected: _congregateOffsetKey == '30min',
                                    onSelected: (_) =>
                                        _setTimePreset(30, '30min'),
                                  ),
                                  FilterChip(
                                    label: Text(label(45).hardcoded),
                                    selected: _congregateOffsetKey == '45min',
                                    onSelected: (_) =>
                                        _setTimePreset(45, '45min'),
                                  ),
                                ];
                              }(),
                              FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Custom'.hardcoded),
                                  ],
                                ),
                                selected: _congregateOffsetKey == 'custom',
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
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a place';
                          }
                          return null;
                        },
                      ),
                      gapH16,
                      // --- Location ---
                      Text(
                        'Location on map (optional)'.hardcoded,
                        style: const TextStyle(
                          fontSize: Sizes.p16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      gapH8,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _locating ? null : _useCurrentLocation,
                              icon: _locating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location, size: 18),
                              label: const Text('Current'),
                            ),
                          ),
                          gapW8,
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openMapPicker,
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('Pick on map'),
                            ),
                          ),
                        ],
                      ),
                      if (_pickedLocation != null) ...[
                        gapH8,
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.green,
                            ),
                            gapW4,
                            Expanded(
                              child: Text(
                                '${_pickedLocation!.latitude.toStringAsFixed(5)}, '
                                '${_pickedLocation!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () =>
                                  setState(() => _pickedLocation = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                      gapH16,
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          hintText: 'e.g., Bring prayer mat, Special occasion',
                          prefixIcon: Icon(Icons.note),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        maxLength: 200,
                      ),
                      gapH4,
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _placeController.text.trim().isEmpty
                              ? null
                              : _saveAsTemplate,
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 16,
                          ),
                          label: Text('Save as template'.hardcoded),
                        ),
                      ),
                    ],
                  ),
                ),
                gapH16,
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
    _noteController.dispose();
    super.dispose();
  }
}

