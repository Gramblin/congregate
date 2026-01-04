import 'dart:convert';

import 'package:congregate/src/features/group/data/group_events_repository.dart';
import 'package:congregate/src/features/login/domain/user_profile.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/utils/firebase_initialization.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

// Global instance for local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global container reference (will be set during initialization)
ProviderContainer? _globalContainer;

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

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request notification permissions
    final notificationPermissionGiven =
        await FirebaseInitialization.requestNotificationPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Setup foreground message listener
    _setupForegroundMessageListener();

    // Setup notification tap handlers
    _setupNotificationTapHandlers();

    // Setup FCM token refresh listener
    _setupFcmTokenRefreshListener();

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

    // Store container globally for notification handlers
    _globalContainer = container;

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
      // Update FCM token in database on app startup
      await _updateFcmTokenInDatabase();

      // Re-subscribe to all group topics (handles app reinstall)
      if (currentUser != null) {
        await _resubscribeToGroupTopics();
      }
    }

    return container;
  }

  /// Update FCM token in database
  static Future<void> _updateFcmTokenInDatabase() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        debugPrint('FCM token is null');
        return;
      }

      debugPrint('📱 Updating FCM token in database...');

      await Supabase.instance.client
          .from('user_profiles')
          .update({'fcm_token': fcmToken})
          .eq('user_id', userId);

      debugPrint('✅ FCM token updated in database');
    } catch (e, st) {
      debugPrint('❌ Failed to update FCM token: $e\n$st');
    }
  }

  /// Re-subscribe user to all their group topics
  /// Call this on app startup to handle reinstalls or FCM token changes
  static Future<void> _resubscribeToGroupTopics() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      debugPrint('🔄 Re-subscribing to group topics...');

      // Get all groups the user is a member of
      final memberships = await Supabase.instance.client
          .from('group_members')
          .select('groups!inner(topic_id)')
          .eq('user_id', userId);

      var successCount = 0;
      var failCount = 0;

      // Subscribe to all group topics
      for (final membership in memberships) {
        final topicId = membership['groups']['topic_id'] as String?;
        if (topicId != null) {
          try {
            await FirebaseMessaging.instance.subscribeToTopic(topicId);
            successCount++;
            debugPrint('✅ Subscribed to topic: $topicId');
          } catch (e) {
            failCount++;
            debugPrint('❌ Failed to subscribe to topic $topicId: $e');
          }
        }
      }

      debugPrint(
        '🎉 Re-subscription complete: $successCount succeeded, $failCount failed',
      );
    } catch (e, st) {
      debugPrint('❌ Failed to re-subscribe to group topics: $e\n$st');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_congregate',
    );
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification action: ${details.actionId}');
        debugPrint('Notification payload: ${details.payload}');

        if (details.payload != null) {
          final data = jsonDecode(details.payload!) as Map<String, dynamic>;

          // Handle button actions
          if (details.actionId == 'accept') {
            _handleAcceptGathering(data);
          } else if (details.actionId == 'decline') {
            _handleDeclineGathering(data);
          } else {
            // Regular notification tap (no button)
            _handleNotificationTap(data);
          }
        }
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'prayer_events_channel',
      'Prayer Event Notifications',
      description: 'Notifications for prayer gatherings and events',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Setup foreground message listener
  static void _setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message received!');
      debugPrint('Data: ${message.data}');

      // FILTER: Ignore messages without proper data
      if (message.data.isEmpty || message.data['type'] == null) {
        debugPrint('⚠️ Ignoring message with empty or invalid data');
        return; // Don't show notification for invalid messages
      }

      // Only process prayer_event type notifications
      if (message.data['type'] != 'prayer_event') {
        debugPrint('⚠️ Ignoring non-prayer-event message');
        return;
      }

      // Get title and body from data (your backend sends data-only messages)
      final title = message.data['title'] as String? ?? 'Prayer Notification';
      final body = message.data['body'] as String? ?? '';

      // Validate required fields
      if (title.isEmpty || body.isEmpty) {
        debugPrint('⚠️ Missing title or body in message data');
        return;
      }

      // Show local notification with action buttons
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_events_channel',
            'Prayer Event Notifications',
            channelDescription:
                'Notifications for prayer gatherings and events',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_congregate',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'accept',
                'Accept',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_congregate'),
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'decline',
                'Decline',
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );

      // Also call your existing handler
      // ref.read(fcmNotificationServiceProvider).handleForegroundMessage(message);
    });
  }

  /// Setup notification tap handlers
  static void _setupNotificationTapHandlers() {
    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification tapped (background)!');
      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('🔔 Notification tapped (terminated)!');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Setup FCM token refresh listener
  static void _setupFcmTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM token refreshed: $newToken');

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          debugPrint('User not logged in, skipping token update');
          return;
        }

        // 1. Update FCM token in user_profiles table
        await Supabase.instance.client
            .from('user_profiles')
            .update({'fcm_token': newToken})
            .eq('user_id', userId);

        debugPrint('✅ Updated FCM token in database');

        // 2. Re-subscribe to all group topics
        await _resubscribeToGroupTopics();

        debugPrint('✅ Re-subscribed to all groups after token refresh');
      } catch (e, st) {
        debugPrint('❌ Failed to handle token refresh: $e\n$st');
      }
    });
  }

  /// Show local notification with action buttons
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'prayer_events_channel',
      'Prayer Event Notifications',
      channelDescription: 'Notifications for prayer gatherings and events',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_congregate',
      // Add action buttons
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept',
          'Accept',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_congregate'),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'decline',
          'Decline',
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  /// Handle notification tap and navigate
  static void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('Handling notification tap with data: $data');

    final type = data['type'] as String?;

    if (type == 'prayer_event') {
      final groupId = data['group_id'] as String?;
      if (groupId != null) {
        // TODO: Navigate to group details
        // Use your router: context.go('/group/$groupId');
        debugPrint('Should navigate to group: $groupId');
      }
    }
  }

  /// Handle accept button
  static Future<void> _handleAcceptGathering(Map<String, dynamic> data) async {
    debugPrint('User accepted gathering');

    final eventId = data['event_id'] as String?;
    final groupId = data['group_id'] as String?;

    if (eventId == null) {
      debugPrint('No event_id in notification data');
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }

      if (_globalContainer == null) {
        debugPrint('Container not initialized');
        return;
      }

      final repo = _globalContainer!.read(groupEventsRepositoryProvider);
      await repo.markAttendance(
        eventId: eventId,
        userId: userId,
        status: 'going',
      );

      debugPrint('✅ Marked as going for event: $eventId in group: $groupId');

      // Show confirmation notification
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Attendance Confirmed',
        "You're marked as attending this prayer gathering",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_events_channel',
            'Prayer Event Notifications',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to mark attendance: $e\n$st');
    }
  }

  /// Handle decline button
  static Future<void> _handleDeclineGathering(
    Map<String, dynamic> data,
  ) async {
    debugPrint('User declined gathering');

    final eventId = data['event_id'] as String?;

    if (eventId == null) {
      debugPrint('No event_id in notification data');
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('User not logged in');
        return;
      }

      if (_globalContainer == null) {
        debugPrint('Container not initialized');
        return;
      }

      final repo = _globalContainer!.read(groupEventsRepositoryProvider);
      await repo.markAttendance(
        eventId: eventId,
        userId: userId,
        status: 'not_going',
      );

      debugPrint('✅ Marked as not going for event: $eventId');

      // Show confirmation notification
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Response Recorded',
        "You've declined this prayer gathering",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_events_channel',
            'Prayer Event Notifications',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to mark attendance: $e\n$st');
    }
  }
}
