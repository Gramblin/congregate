// import 'package:congregate/firebase_options.dart';
import 'dart:convert';

import 'package:congregate/firebase_options.dart';
import 'package:congregate/src/utils/main_initialization_utils.dart'
    as main_initialization_utils;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseInitialization {
  static Future<bool> requestNotificationPermissions() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // print('✅ User granted permission');
      return true;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // print('⚠️ User granted provisional permission');
      return true;
    } else {
      // print('❌ User declined or has not accepted permission');
      return false;
    }
  }
}

Future<void> initializeFirebaseApp() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    name: 'Congregate',
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('📬 Background message received: ${message.messageId}');

  if (message.data.isEmpty || message.data['type'] != 'prayer_event') {
    debugPrint('⚠️ Ignoring invalid background message');
    return;
  }

  // ✅ NEW: Don't notify the event creator (requires initializing Supabase)
  // Note: This requires Supabase to be initialized in background
  // For now, we'll handle this on the backend instead

  final title =
      message.data['title'] as String? ??
      message.notification?.title ??
      'New Notification';
  final body =
      message.data['body'] as String? ?? message.notification?.body ?? '';

  await main_initialization_utils.flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_events_channel',
        'Prayer Event Notifications',
        channelDescription: 'Notifications for prayer gatherings and events',
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
    payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
  );
}
