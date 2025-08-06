// ignore_for_file: unused_field, cancel_subscriptions

import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:congregate/src/router/app_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  late final StreamSubscription<Uri> _linkSubscription;

  Future<void> setupInteractedMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleBackgroundMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleBackgroundMessage);
  }

  void handleForegroundMessage(RemoteMessage message) {
    print('Handling foreground message ${message.data}');
    _handleMessageByType(message);
  }

  void handleBackgroundMessage(RemoteMessage message) {
    print('Handling background message ${message.data}');
    _handleMessageByType(message);
  }

  void setupAppLinks() {
    if (!kIsWeb && Platform.isMacOS) {
      final appLinks = AppLinks();
      appLinks.getInitialLink().then((uri) {
        if (uri != null) {
          _handleInitialLink(uri);
        }
      });

      _linkSubscription = appLinks.uriLinkStream.listen(_handleInitialLink);
    }
  }

  void _handleInitialLink(Uri uri) {
    GoRouter.of(rootNavigatorKey.currentContext!).go(uri.toString());
  }

  void _handleMessageByType(RemoteMessage message) {
    if (message.data['type'] == 'new-game') {
      final roomId = message.data['roomId'];
      print('Parsed game ID >> $roomId');
      if (roomId != null) {
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          // GameRoute(roomId: roomId as String).go(context);
        }
      } else {
        print('⚠️ No roomId found in message data');
      }
    }
  }
}
