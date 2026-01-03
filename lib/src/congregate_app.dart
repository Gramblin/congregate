import 'dart:async';
import 'dart:developer';

import 'package:congregate/src/router/app_router.dart';
import 'package:congregate/src/utils/deep_link_handler.dart';
import 'package:congregate/src/utils/notifications_service.dart';
import 'package:congregate/src/utils/supabase_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CongregateApp extends ConsumerStatefulWidget {
  const CongregateApp({super.key});

  @override
  ConsumerState<CongregateApp> createState() => CongregateAppState();
}

class CongregateAppState extends ConsumerState<CongregateApp> {
  late final StreamSubscription<Uri> sub;
  StreamSubscription<String>? _tokenRefreshSub;
  final NotificationService notificationService = NotificationService();
  DeepLinkHandler? _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen(
      notificationService.handleForegroundMessage,
    );

    notificationService
      ..setupAppLinks()
      // Run code to handle interacted messages in an async function
      // as initState() must not be async
      ..setupInteractedMessage();

    _deepLinkHandler = DeepLinkHandler(ref);

    // Initialize after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _deepLinkHandler?.initialize(context);
      }
    });
  }

  Future<void> _registerFcmTokenIfNeeded() async {
    final client = ref.read(supabaseProvider).client;
    final user = client.auth.currentUser;

    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      log('token is $token');
      await client
          .from('user_profiles')
          .update({'fcm_token': token})
          .eq('user_id', user.id);
    }

    _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) async {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return;

      log('new token is $token');

      await client
          .from('user_profiles')
          .update({'fcm_token': newToken})
          .eq('user_id', currentUser.id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ref.read(supabaseProvider).client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        _registerFcmTokenIfNeeded();
        ref.read(routerProvider).refresh();
      }

      if (event == AuthChangeEvent.signedOut) {
        ref.read(routerProvider).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.redAccent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          },
        ),
        brightness: Brightness.light,
        fontFamily: 'Pally',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontWeight: FontWeight.normal),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          // Add other customizations here if needed
        ),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.redAccent,
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          },
        ),
        brightness: Brightness.dark,
        fontFamily: 'Pally',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontWeight: FontWeight.normal),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          // Add other customizations here if needed
        ),
      ),
      routerConfig: ref.watch(routerProvider),
      themeMode: ThemeMode.light,
    );
  }

  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    sub.cancel();
    _deepLinkHandler?.dispose();
    super.dispose();
  }
}
