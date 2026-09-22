import 'package:congregate/src/features/stories/data/story_provider.dart';
import 'package:congregate/src/features/stories/domain/story_item.dart';
import 'package:congregate/src/features/stories/presentation/story_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StoryStrip extends ConsumerWidget {
  const StoryStrip({required this.kind, super.key});

  final StoryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyStripProvider(kind));

    if (state.items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = state.items[i];
          final watched = state.watched.contains(item.id);
          return _StoryCircle(
            item: item,
            watched: watched,
            onTap: () => _open(context, state.items, i),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, List<StoryItem> items, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => StoryViewerScreen(
          items: items,
          initialPage: index,
          kind: kind,
        ),
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  const _StoryCircle({
    required this.item,
    required this.watched,
    required this.onTap,
  });

  final StoryItem item;
  final bool watched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: watched
                    ? null
                    : LinearGradient(
                        colors: item.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: watched
                    ? Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                        width: 2,
                      )
                    : null,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: item.gradient.last.withValues(alpha: 0.85),
                  child: Text(
                    item.name.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: Text(
                item.name,
                style: const TextStyle(fontSize: 11, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
