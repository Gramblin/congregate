import 'dart:developer';
import 'dart:io';

import 'package:congregate/src/features/business/domain/business.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'business_remote_repository.g.dart';

class BusinessRemoteRepository {
  BusinessRemoteRepository(this._client, this._messaging);
  final SupabaseClient _client;
  final FirebaseMessaging _messaging;

  Future<List<Business>> fetchBusinesses({
    String? country,
    String? city,
    String? category,
  }) async {
    try {
      var query = _client
          .from('businesses')
          .select()
          .eq('approval_status', 'approved');

      if (country != null) query = query.eq('country', country);
      if (city != null && city.isNotEmpty) query = query.eq('city', city);
      if (category != null) query = query.eq('category', category);

      final rows = await query.order('follower_count', ascending: false);
      return (rows as List).map((r) => Business.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e, st) {
      log('BusinessRemoteRepository.fetchBusinesses error: $e\n$st');
      rethrow;
    }
  }

  Future<Business> fetchBusiness(String id) async {
    final row = await _client.from('businesses').select().eq('id', id).single();
    return Business.fromJson(row);
  }

  Future<List<Business>> fetchMyBusinesses(String userId) async {
    final rows = await _client
        .from('businesses')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => Business.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Business> createBusiness({
    required String name,
    required String category,
    required String userId,
    String? description,
    String? country,
    String? city,
    String? email,
    String? phone,
    String? website,
    String visibility = 'global',
    bool contactPublic = true,
  }) async {
    final id = const Uuid().v4();
    final topicId = 'business_$id';

    final row = await _client
        .from('businesses')
        .insert({
          'id': id,
          'name': name,
          'category': category,
          'owner_id': userId,
          'topic_id': topicId,
          'visibility': visibility,
          'contact_public': contactPublic,
          if (description != null) 'description': description,
          if (country != null) 'country': country,
          if (city != null) 'city': city,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (website != null) 'website': website,
        })
        .select()
        .single();

    try {
      await _messaging.subscribeToTopic(topicId);
    } catch (e) {
      log('FCM subscribe failed: $e');
    }

    return Business.fromJson(row);
  }

  Future<Business> updateBusiness({
    required String businessId,
    String? name,
    String? description,
    String? category,
    String? country,
    String? city,
    String? email,
    String? phone,
    String? website,
    String? visibility,
    bool? contactPublic,
  }) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (visibility != null) 'visibility': visibility,
      if (contactPublic != null) 'contact_public': contactPublic,
    };
    final row = await _client
        .from('businesses')
        .update(updates)
        .eq('id', businessId)
        .select()
        .single();
    return Business.fromJson(row);
  }

  Future<void> deleteBusiness(String businessId) async {
    await _client.from('businesses').delete().eq('id', businessId);
  }

  /// Upload profile image → returns public URL.
  Future<String> uploadProfileImage({
    required String businessId,
    required File image,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$businessId/profile.jpg';
    await _client.storage.from('business-images').upload(
          path,
          image,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('business-images').getPublicUrl(path);
    await _client.from('businesses').update({'profile_image_url': url}).eq('id', businessId);
    return url;
  }

  // ── Follow / Unfollow ──────────────────────────────────────

  Future<bool> isFollowing(String businessId, String userId) async {
    final row = await _client
        .from('business_follows')
        .select()
        .eq('business_id', businessId)
        .eq('follower_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> follow(String businessId, String topicId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('business_follows').insert({
      'business_id': businessId,
      'follower_id': userId,
    });
    try {
      await _messaging.subscribeToTopic(topicId);
    } catch (e) {
      log('FCM follow subscribe failed: $e');
    }
  }

  Future<void> unfollow(String businessId, String topicId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('business_follows')
        .delete()
        .eq('business_id', businessId)
        .eq('follower_id', userId);
    try {
      await _messaging.unsubscribeFromTopic(topicId);
    } catch (e) {
      log('FCM unfollow failed: $e');
    }
  }
}

@Riverpod(keepAlive: true)
BusinessRemoteRepository businessRemoteRepository(Ref ref) {
  return BusinessRemoteRepository(
    ref.watch(supabaseProvider).client,
    FirebaseMessaging.instance,
  );
}
