import 'dart:developer';
import 'dart:io';

import 'package:congregate/src/features/ads/domain/ad.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'ads_repository.g.dart';

class AdsRepository {
  AdsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Ad>> fetchActiveAds() async {
    try {
      final rows = await _client
          .from('ads')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return (rows as List)
          .map((r) => Ad.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      log('AdsRepository.fetchActiveAds error: $e\n$st');
      rethrow;
    }
  }

  Future<List<Ad>> fetchAdsByBusiness(String businessId) async {
    final rows = await _client
        .from('ads')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Ad.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadBanner({
    required String adId,
    required File image,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$adId/banner.jpg';
    await _client.storage.from('ad-banners').upload(
          path,
          image,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('ad-banners').getPublicUrl(path);
  }

  Future<Ad> createAd({
    required String businessId,
    required String title,
    required String htmlContent,
    required File bannerImage,
    String? linkUrl,
  }) async {
    final id = const Uuid().v4();
    final bannerUrl = await uploadBanner(adId: id, image: bannerImage);
    final row = await _client
        .from('ads')
        .insert({
          'id': id,
          'business_id': businessId,
          'title': title,
          'banner_image_url': bannerUrl,
          'html_content': htmlContent,
          if (linkUrl != null && linkUrl.isNotEmpty) 'link_url': linkUrl,
          'is_active': true,
        })
        .select()
        .single();
    return Ad.fromJson(row);
  }

  Future<void> deleteAd(String adId) async {
    await _client.from('ads').delete().eq('id', adId);
  }
}

@riverpod
AdsRepository adsRepository(Ref ref) =>
    AdsRepository(ref.watch(supabaseProvider).client);

@riverpod
Future<List<Ad>> adsList(Ref ref) =>
    ref.watch(adsRepositoryProvider).fetchActiveAds();

@riverpod
Future<List<Ad>> businessAds(Ref ref, String businessId) =>
    ref.watch(adsRepositoryProvider).fetchAdsByBusiness(businessId);

@riverpod
class AdFormNotifier extends _$AdFormNotifier {
  @override
  FutureOr<void> build() => null;

  Future<Ad?> create({
    required String businessId,
    required String title,
    required String htmlContent,
    required File bannerImage,
    String? linkUrl,
  }) async {
    state = const AsyncLoading();
    Ad? result;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(adsRepositoryProvider);
      result = await repo.createAd(
        businessId: businessId,
        title: title,
        htmlContent: htmlContent,
        bannerImage: bannerImage,
        linkUrl: linkUrl,
      );
      ref.invalidate(adsListProvider);
      ref.invalidate(businessAdsProvider(businessId));
    });
    return result;
  }

  Future<void> delete({
    required String adId,
    required String businessId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(adsRepositoryProvider).deleteAd(adId);
      ref.invalidate(adsListProvider);
      ref.invalidate(businessAdsProvider(businessId));
    });
  }
}
