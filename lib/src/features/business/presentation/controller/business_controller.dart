import 'dart:developer';
import 'dart:io';

import 'package:congregate/src/features/business/data/business_remote_repository.dart';
import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/utils/location_provider.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'business_controller.g.dart';

// ── Business list ──────────────────────────────────────────────

@riverpod
Future<List<Business>> businessList(Ref ref, {String? category}) async {
  final location = ref.watch(locationProvider);
  final repo = ref.watch(businessRemoteRepositoryProvider);
  final userId = ref.watch(supabaseProvider).client.auth.currentUser?.id;

  final businesses = await repo.fetchBusinesses(
    country: location.country,
    city: location.city,
    category: category,
  );

  if (userId == null) return businesses;

  // Annotate isFollowing
  final follows = await ref.watch(supabaseProvider).client
      .from('business_follows')
      .select('business_id')
      .eq('follower_id', userId);

  final followedIds = (follows as List)
      .map((r) => r['business_id'] as String)
      .toSet();

  return businesses
      .map((b) => b.copyWith(isFollowing: followedIds.contains(b.id)))
      .toList();
}

// ── Follow notifier ────────────────────────────────────────────

@Riverpod(keepAlive: true)
class FollowNotifier extends _$FollowNotifier {
  @override
  FutureOr<void> build() => null;

  Future<void> toggle(Business business) async {
    // Capture ref-dependent objects before any async gap
    final repo = ref.read(businessRemoteRepositoryProvider);
    state = const AsyncLoading();
    try {
      if (business.isFollowing == true) {
        await repo.unfollow(business.id, business.topicId);
      } else {
        await repo.follow(business.id, business.topicId);
      }
      state = const AsyncData(null);
      if (ref.mounted) ref.invalidate(businessListProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ── Business CRUD notifier ────────────────────────────────────

@riverpod
class BusinessFormNotifier extends _$BusinessFormNotifier {
  @override
  FutureOr<void> build() => null;

  Future<Business?> create({
    required String name,
    required String category,
    String? description,
    String? country,
    String? city,
    String? email,
    String? phone,
    String? website,
    String visibility = 'global',
    bool contactPublic = true,
    File? profileImage,
  }) async {
    state = const AsyncLoading();
    Business? result;
    state = await AsyncValue.guard(() async {
      final userId =
          ref.read(supabaseProvider).client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final repo = ref.read(businessRemoteRepositoryProvider);
      var business = await repo.createBusiness(
        name: name,
        category: category,
        userId: userId,
        description: description,
        country: country,
        city: city,
        email: email,
        phone: phone,
        website: website,
        visibility: visibility,
        contactPublic: contactPublic,
      );

      if (profileImage != null) {
        try {
          await repo.uploadProfileImage(
            businessId: business.id,
            image: profileImage,
          );
          business = await repo.fetchBusiness(business.id);
        } catch (e) {
          log('Profile image upload failed: $e');
        }
      }

      result = business;
      ref.invalidate(businessListProvider);
    });
    return result;
  }

  Future<void> updateImage({
    required String businessId,
    required File image,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(businessRemoteRepositoryProvider)
          .uploadProfileImage(businessId: businessId, image: image);
      ref.invalidate(businessListProvider);
    });
  }
}
