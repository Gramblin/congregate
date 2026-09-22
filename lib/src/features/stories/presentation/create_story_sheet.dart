import 'dart:io';

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/stories/data/stories_repository.dart';
import 'package:congregate/src/features/stories/data/story_provider.dart';
import 'package:congregate/src/features/stories/domain/story.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CreateStorySheet extends ConsumerStatefulWidget {
  const CreateStorySheet({
    required this.authorType,
    required this.authorId,
    required this.authorName,
    super.key,
  });

  final StoryAuthorType authorType;
  final String authorId;
  final String authorName;

  @override
  ConsumerState<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends ConsumerState<CreateStorySheet> {
  final _captionCtrl = TextEditingController();
  File? _media;
  double _hours = 24;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (xfile != null) setState(() => _media = File(xfile.path));
  }

  Future<void> _submit() async {
    if (_media == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a photo first')),
      );
      return;
    }
    final story = await ref.read(storyFormProvider.notifier).create(
          authorType: widget.authorType,
          authorId: widget.authorId,
          authorName: widget.authorName,
          media: _media!,
          caption: _captionCtrl.text.trim().isEmpty
              ? null
              : _captionCtrl.text.trim(),
          ttl: Duration(minutes: (_hours * 60).round()),
        );
    if (!mounted) return;
    if (story != null) {
      await ref
          .read(storyStripProvider(
              widget.authorType == StoryAuthorType.business
                  ? StoryKind.business
                  : StoryKind.community).notifier)
          .refresh();
      if (mounted) Navigator.pop(context);
    } else {
      final err = ref.read(storyFormProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyFormProvider);
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(Sizes.p16),
          children: [
            const Text(
              'New Story',
              style: TextStyle(
                fontSize: Sizes.p20,
                fontWeight: FontWeight.bold,
              ),
            ),
            gapH16,
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  image: _media != null
                      ? DecorationImage(
                          image: FileImage(_media!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _media == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40),
                            SizedBox(height: 6),
                            Text('Pick a photo'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            gapH12,
            TextField(
              controller: _captionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            gapH16,
            Row(
              children: [
                const Text('Expires in:'),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 24,
                    divisions: 23,
                    value: _hours,
                    label: '${_hours.round()}h',
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                ),
                Text('${_hours.round()}h'),
              ],
            ),
            Text(
              'Stories auto-delete after ${_hours.round()} hour(s). '
              'Max 24h.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            gapH24,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isLoading ? null : _submit,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post Story'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
