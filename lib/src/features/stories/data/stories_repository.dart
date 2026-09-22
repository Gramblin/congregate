import 'dart:developer';
import 'dart:io';

import 'package:congregate/src/features/stories/domain/story.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const Duration kStoryMaxTtl = Duration(hours: 24);

class StoriesRepository {
  StoriesRepository(this._client);
  final SupabaseClient _client;

  Future<List<Story>> fetchActiveStories({StoryAuthorType? authorType}) async {
    try {
      final query = _client
          .from('stories')
          .select()
          .gt('expires_at', DateTime.now().toUtc().toIso8601String());
      final rows = authorType == null
          ? await query.order('created_at', ascending: false)
          : await query
              .eq('author_type', authorType.name)
              .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => Story.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      log('StoriesRepository.fetchActiveStories error: $e\n$st');
      rethrow;
    }
  }

  Future<String> uploadMedia({
    required String storyId,
    required File media,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final ext = media.path.split('.').last.toLowerCase();
    final path = '$userId/$storyId/media.$ext';
    await _client.storage.from('story-media').upload(
          path,
          media,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('story-media').getPublicUrl(path);
  }

  Future<Story> createStory({
    required StoryAuthorType authorType,
    required String authorId,
    required String authorName,
    required File media,
    String? caption,
    Duration ttl = kStoryMaxTtl,
  }) async {
    final clamped = ttl > kStoryMaxTtl ? kStoryMaxTtl : ttl;
    final id = const Uuid().v4();
    final mediaUrl = await uploadMedia(storyId: id, media: media);
    final now = DateTime.now().toUtc();
    final row = await _client
        .from('stories')
        .insert({
          'id': id,
          'author_type': authorType.name,
          if (authorType == StoryAuthorType.community) 'group_id': authorId,
          if (authorType == StoryAuthorType.business) 'business_id': authorId,
          'author_name': authorName,
          'media_url': mediaUrl,
          if (caption != null && caption.isNotEmpty) 'caption': caption,
          'created_at': now.toIso8601String(),
          'expires_at': now.add(clamped).toIso8601String(),
        })
        .select()
        .single();
    return Story.fromJson(row);
  }

  Future<void> deleteStory(String storyId) async {
    await _client.from('stories').delete().eq('id', storyId);
  }
}

final Provider<StoriesRepository> storiesRepositoryProvider =
    Provider<StoriesRepository>(
  (ref) => StoriesRepository(ref.watch(supabaseProvider).client),
);

final activeStoriesProvider =
    FutureProvider.autoDispose.family<List<Story>, StoryAuthorType>(
  (ref, type) => ref
      .watch(storiesRepositoryProvider)
      .fetchActiveStories(authorType: type),
);

class StoryFormState {
  const StoryFormState({this.isLoading = false, this.error});
  final bool isLoading;
  final Object? error;
}

class StoryFormNotifier extends Notifier<StoryFormState> {
  @override
  StoryFormState build() => const StoryFormState();

  Future<Story?> create({
    required StoryAuthorType authorType,
    required String authorId,
    required String authorName,
    required File media,
    String? caption,
    Duration? ttl,
  }) async {
    state = const StoryFormState(isLoading: true);
    try {
      final story = await ref.read(storiesRepositoryProvider).createStory(
            authorType: authorType,
            authorId: authorId,
            authorName: authorName,
            media: media,
            caption: caption,
            ttl: ttl ?? kStoryMaxTtl,
          );
      ref.invalidate(activeStoriesProvider(authorType));
      state = const StoryFormState();
      return story;
    } on Object catch (e, st) {
      log('StoryFormNotifier.create error: $e\n$st');
      state = StoryFormState(error: e);
      return null;
    }
  }
}

final NotifierProvider<StoryFormNotifier, StoryFormState> storyFormProvider =
    NotifierProvider<StoryFormNotifier, StoryFormState>(StoryFormNotifier.new);
