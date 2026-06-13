import 'dart:convert';
import 'dart:developer';

import 'package:congregate/src/features/home/domain/prayer_times.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'prayer_times_repository.g.dart';

class PrayerTimesRepository {
  PrayerTimesRepository(this._prefs);

  final SharedPreferences _prefs;
  final Dio _dio = Dio();

  Future<PrayerTimes?> getPrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final key = _cacheKey(latitude, longitude, d);

    final cached = _prefs.getString(key);
    if (cached != null) {
      try {
        return PrayerTimes.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } on Exception {/* stale, re-fetch */}
    }

    final dateStr =
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.aladhan.com/v1/timings/$dateStr',
        queryParameters: {
          'latitude': latitude.toStringAsFixed(4),
          'longitude': longitude.toStringAsFixed(4),
          'method': 3,
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final pt = PrayerTimes.fromApiTimings(timings, d);
      await _prefs.setString(key, jsonEncode(pt.toJson()));
      return pt;
    } on Exception catch (e) {
      log('PrayerTimesRepository.getPrayerTimes error: $e');
      return null;
    }
  }

  String _cacheKey(double lat, double lon, DateTime d) =>
      'pt_${d.year}_${d.month}_${d.day}_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
}

@riverpod
PrayerTimesRepository prayerTimesRepository(Ref ref) =>
    PrayerTimesRepository(ref.read(preferencesProvider));

/// Today's prayer times via GPS. Null if location denied or API fails.
@riverpod
Future<PrayerTimes?> todayPrayerTimes(Ref ref) async {
  try {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition();
    return ref.read(prayerTimesRepositoryProvider).getPrayerTimes(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
  } on Exception catch (e) {
    log('todayPrayerTimes error: $e');
    return null;
  }
}
