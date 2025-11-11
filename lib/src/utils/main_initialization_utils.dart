import 'dart:convert';

import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/utils/firebase_initialization.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainInitializationUtils {
  static Future<void> setupUI() async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  static Future<ProviderContainer> initializeProviders() async {
    await initializeFirebaseApp();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final notificationPermissionGiven =
        await FirebaseInitialization.requestNotificationPermissions();

    usePathUrlStrategy();

    const apiKey = String.fromEnvironment('SUPABASE_API_KEY');
    const url = String.fromEnvironment('SUPABASE_URL');

    final sharedPreferences = await SharedPreferences.getInstance();
    await Supabase.initialize(url: url, anonKey: apiKey);

    // ✅ Create container first
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWith((ref) => sharedPreferences),
      ],
    );

    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser != null) {
      try {
        final notifier = container.read(userProfileProvider.notifier);

        // First try cached data
        final cached = sharedPreferences.getString('cached_user_profile');
        if (cached != null) {
          final cachedJson = jsonDecode(cached) as Map<String, dynamic>;
          final userProfile = UserProfile.fromJson(cachedJson);
          container.read(userProfileProvider.notifier).state = AsyncData(
            userProfile,
          );
        }

        await notifier.build();
      } on Exception catch (e, st) {
        debugPrint('❌ Failed to initialize user profile: $e\n$st');
      }
    }

    // ✅ Optional: update FCM token if permission granted
    if (notificationPermissionGiven) {
      // await container.read(friendshipControllerProvider.notifier).updateFcmToken();
    }

    return container;
  }
}
