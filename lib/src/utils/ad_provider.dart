import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final mobileAdsProvider = Provider<MobileAds>((ref) {
  return MobileAds.instance;
});
