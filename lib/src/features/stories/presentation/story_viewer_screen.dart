import 'package:congregate/src/features/stories/data/story_provider.dart';
import 'package:congregate/src/features/stories/domain/story.dart';
import 'package:congregate/src/features/stories/domain/story_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story/story.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    required this.items,
    required this.initialPage,
    required this.kind,
    super.key,
  });

  final List<StoryItem> items;
  final int initialPage;
  final StoryKind kind;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _markCurrentWatched();
  }

  void _markCurrentWatched() {
    final item = widget.items[_currentPage];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyStripProvider(widget.kind).notifier).markWatched(item.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyStripProvider(widget.kind));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Dismissible(
        key: const ValueKey('story_viewer_dismiss'),
        direction: DismissDirection.down,
        onDismissed: (_) => Navigator.of(context).pop(),
        child: StoryPageView(
          pageLength: widget.items.length,
          initialPage: widget.initialPage,
          storyLength: (pageIndex) => widget.items[pageIndex].pageCount,
          onPageChanged: (i) {
            setState(() => _currentPage = i);
            _markCurrentWatched();
          },
          onPageLimitReached: () => Navigator.of(context).pop(),
          itemBuilder: (context, pageIndex, storyIndex) {
            final item = widget.items[pageIndex];
            final stories = state.storiesByAuthor[item.id] ?? const <Story>[];
            final story = storyIndex < stories.length
                ? stories[storyIndex]
                : null;
            return _StoryPage(item: item, story: story, storyIndex: storyIndex);
          },
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.item,
    required this.story,
    required this.storyIndex,
  });

  final StoryItem item;
  final Story? story;
  final int storyIndex;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (story != null)
          Image.network(
            story!.mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradient(),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _gradient(),
          )
        else
          _gradient(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
              stops: const [0, 0.3, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      radius: 18,
                      child: Text(
                        item.name.characters.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const Spacer(),
                if (story?.caption != null && story!.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      story!.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                Text(
                  '${storyIndex + 1} / ${item.pageCount}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradient() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}
