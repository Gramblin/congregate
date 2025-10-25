import 'package:congregate/src/utils/firebase_initialization.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore:depend_on_referenced_package, depend_on_referenced_packages
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

    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWith((ref) => sharedPreferences),

        // userProfileProvider.overrideWith((ref) {
        //   final jsonString = sharedPreferences.getString('user_profile');
        //   final context = rootNavigatorKey.currentContext;
        //   if (jsonString == null) {
        //     if (context != null) const ProfileSetupRoute().go(context);
        //     return null;
        //   }

        //   final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
        //   final userProfile = UserProfile.fromJson(jsonMap);

        //   if (userProfile.countryCode == null) {
        //     if (context != null) const ProfileSetupRoute().go(context);
        //   }
        //   return userProfile;
        // }),
      ],
    );

    if (notificationPermissionGiven) {
      // await container
      //     .read(friendshipControllerProvider.notifier)
      //     .updateFcmToken();
    }

    return container;
  }
}
