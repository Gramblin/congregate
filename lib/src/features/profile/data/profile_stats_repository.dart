import 'dart:developer';

import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_stats_repository.g.dart';

class UserStats {
  const UserStats({
    required this.eventsAttended,
    required this.communitiesJoined,
  });
  final int eventsAttended;
  final int communitiesJoined;

  CommunityLevel get level => CommunityLevel.forCount(eventsAttended);
}

enum CommunityLevel {
  musafir(1, 'Musafir', 'The Arriving Soul', '🌙', 0, 9),
  muqeem(2, 'Muqeem', 'The Devoted Resident', '⭐', 10, 29),
  mujahid(3, 'Mujahid', 'The Steadfast One', '🌟', 30, 49),
  muneer(4, 'Muneer', 'The Radiant Luminary', '💫', 50, 99),
  rukn(5, 'Rukn', 'The Cornerstone', '🏛️', 100, 999999);

  const CommunityLevel(
    this.number,
    this.title,
    this.subtitle,
    this.emoji,
    this.min,
    this.max,
  );

  final int number;
  final String title;
  final String subtitle;
  final String emoji;
  final int min;
  final int max;

  static CommunityLevel forCount(int count) {
    if (count >= 100) return CommunityLevel.rukn;
    if (count >= 50) return CommunityLevel.muneer;
    if (count >= 30) return CommunityLevel.mujahid;
    if (count >= 10) return CommunityLevel.muqeem;
    return CommunityLevel.musafir;
  }

  int nextLevelAt() => max == 999999 ? -1 : max + 1;
}

class CommunityImpact {
  const CommunityImpact({
    required this.totalEvents,
    required this.totalMembers,
    required this.activeDonations,
  });
  final int totalEvents;
  final int totalMembers;
  final int activeDonations;
}

@riverpod
Future<UserStats> userStats(Ref ref, String userId) async {
  try {
    final client = ref.watch(supabaseProvider).client;
    final result = await client.rpc<dynamic>(
      'get_user_stats',
      params: {'p_user_id': userId},
    );
    final data = result as Map<String, dynamic>;
    return UserStats(
      eventsAttended: (data['events_attended'] as num?)?.toInt() ?? 0,
      communitiesJoined: (data['communities_joined'] as num?)?.toInt() ?? 0,
    );
  } catch (e, st) {
    log('userStats error: $e\n$st');
    return const UserStats(eventsAttended: 0, communitiesJoined: 0);
  }
}

@riverpod
Future<CommunityImpact> communityImpact(Ref ref, String groupId) async {
  try {
    final client = ref.watch(supabaseProvider).client;
    final result = await client.rpc<dynamic>(
      'get_community_impact',
      params: {'p_group_id': groupId},
    );
    final data = result as Map<String, dynamic>;
    return CommunityImpact(
      totalEvents: (data['total_events'] as num?)?.toInt() ?? 0,
      totalMembers: (data['total_members'] as num?)?.toInt() ?? 0,
      activeDonations: (data['active_donations'] as num?)?.toInt() ?? 0,
    );
  } catch (e, st) {
    log('communityImpact error: $e\n$st');
    return const CommunityImpact(
      totalEvents: 0,
      totalMembers: 0,
      activeDonations: 0,
    );
  }
}
