import 'dart:async';
import 'dart:developer';

import 'package:congregate/src/router/app_router.dart';
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

  final NotificationService notificationService = NotificationService();

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
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.read(supabaseProvider).client.auth.onAuthStateChange.listen((data) {
      log(data.session?.expiresAt.toString() ?? '');
      if (data.event == AuthChangeEvent.userUpdated) {
        log('user updated ${data.session?.user}');
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
}
