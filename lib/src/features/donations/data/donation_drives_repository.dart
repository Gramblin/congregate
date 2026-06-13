import 'dart:developer';

import 'package:congregate/src/features/donations/domain/donation_drive.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'donation_drives_repository.g.dart';

class DonationDrivesRepository {
  DonationDrivesRepository(this._client);
  final SupabaseClient _client;

  Future<List<DonationDrive>> fetchDrives(String groupId) async {
    try {
      final rows = await _client
          .from('donation_drives')
          .select()
          .eq('group_id', groupId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => DonationDrive.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      log('DonationDrivesRepository.fetchDrives error: $e\n$st');
      rethrow;
    }
  }

  Future<DonationDrive> create({
    required String groupId,
    required String title,
    String? description,
    String? externalLink,
    double? goalAmount,
    String currency = 'USD',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('donation_drives')
        .insert({
          'group_id': groupId,
          'title': title,
          'created_by': userId,
          'currency': currency,
          if (description != null) 'description': description,
          if (externalLink != null) 'external_link': externalLink,
          if (goalAmount != null) 'goal_amount': goalAmount,
        })
        .select()
        .single();
    return DonationDrive.fromJson(row);
  }

  Future<void> deactivate(String driveId) async {
    await _client
        .from('donation_drives')
        .update({'is_active': false})
        .eq('id', driveId);
  }
}

@Riverpod(keepAlive: true)
DonationDrivesRepository donationDrivesRepository(Ref ref) =>
    DonationDrivesRepository(ref.watch(supabaseProvider).client);

@riverpod
Future<List<DonationDrive>> donationDrives(Ref ref, String groupId) =>
    ref.watch(donationDrivesRepositoryProvider).fetchDrives(groupId);
