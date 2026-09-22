import 'package:congregate/src/features/stories/data/stories_repository.dart';
import 'package:congregate/src/features/stories/domain/story.dart';
import 'package:congregate/src/features/stories/domain/story_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StoryKind { community, business }

StoryAuthorType _authorTypeFor(StoryKind kind) =>
    kind == StoryKind.community
        ? StoryAuthorType.community
        : StoryAuthorType.business;

class StoryStripState {
  const StoryStripState({
    required this.items,
    required this.storiesByAuthor,
    required this.watched,
    this.isLoading = false,
    this.error,
  });

  final List<StoryItem> items;
  final Map<String, List<Story>> storiesByAuthor;
  final Set<String> watched;
  final bool isLoading;
  final Object? error;

  StoryStripState copyWith({
    List<StoryItem>? items,
    Map<String, List<Story>>? storiesByAuthor,
    Set<String>? watched,
    bool? isLoading,
    Object? error,
  }) =>
      StoryStripState(
        items: items ?? this.items,
        storiesByAuthor: storiesByAuthor ?? this.storiesByAuthor,
        watched: watched ?? this.watched,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class StoryStripController extends Notifier<StoryStripState> {
  StoryStripController(this.kind);

  final StoryKind kind;

  @override
  StoryStripState build() {
    Future.microtask(_load);
    return const StoryStripState(
      items: [],
      storiesByAuthor: {},
      watched: {},
      isLoading: true,
    );
  }

  Future<void> _load() async {
    try {
      final stories = await ref
          .read(storiesRepositoryProvider)
          .fetchActiveStories(authorType: _authorTypeFor(kind));
      final grouped = <String, List<Story>>{};
      for (final s in stories) {
        grouped.putIfAbsent(s.authorId, () => <Story>[]).add(s);
      }
      final items = <StoryItem>[];
      var i = 0;
      for (final entry in grouped.entries) {
        items.add(StoryItem(
          id: entry.key,
          name: entry.value.first.authorName,
          gradient: _palette(i++),
          pageCount: entry.value.length,
        ));
      }
      state = StoryStripState(
        items: items,
        storiesByAuthor: grouped,
        watched: state.watched,
      );
    } on Object catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _load();
  }

  void markWatched(String id) {
    final items = <StoryItem>[...state.items];
    final idx = items.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    final item = items.removeAt(idx);
    items.add(item);
    state = state.copyWith(
      items: items,
      watched: <String>{...state.watched, id},
    );
  }
}

final storyStripProvider =
    NotifierProvider.family<StoryStripController, StoryStripState, StoryKind>(
  StoryStripController.new,
);

List<Color> _palette(int i) {
  const palettes = <List<Color>>[
    [Color(0xFF6750A4), Color(0xFF9A82DB)],
    [Color(0xFF006C51), Color(0xFF3FA57F)],
    [Color(0xFFB3261E), Color(0xFFEE6B60)],
    [Color(0xFF1E5FBF), Color(0xFF6B9EFF)],
    [Color(0xFFEA580C), Color(0xFFFDBA74)],
    [Color(0xFF0F766E), Color(0xFF5EEAD4)],
    [Color(0xFF9333EA), Color(0xFFD8B4FE)],
    [Color(0xFFDB2777), Color(0xFFF9A8D4)],
  ];
  return palettes[i % palettes.length];
}
