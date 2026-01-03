import 'dart:io';

import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/router/app_router_observer.dart';
import 'package:congregate/src/router/misc_routes/error_screen.dart';
import 'package:congregate/src/router/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  print('🔄 RouterProvider rebuilding at ${DateTime.now()}');

  // final loggedIn = ref.watch(userStream).value?.session != null;
  final userProfile = ref.watch(userProfileProvider).value;

  // final supabase = ref.watch(supabaseProvider);

  return GoRouter(
    initialLocation: '/home',
    navigatorKey: rootNavigatorKey,
    // debugLogDiagnostics: true,
    observers: [AppRouterObserver(ref)],
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentUser != null;

      // 1. Skip redirects for alert dialogs
      if (state.fullPath?.startsWith('/alert-dialog') ?? false) {
        return null;
      }

      final uri = state.uri;

      // 2. Handle deep links like congregate://invite/{inviteCode}
      if (uri.scheme == 'congregate' && uri.host == 'invite') {
        final inviteCode = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null;
        if (inviteCode != null && state.uri.path != '/invite/$inviteCode') {
          return '/invite/$inviteCode';
        }
      }

      // 3. Handle deep links like congregate://group/{roomId}
      if (uri.scheme == 'congregate' && uri.host == 'group') {
        final roomId = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null;
        if (roomId != null && state.uri.path != '/game/$roomId') {
          return '/home/game/$roomId';
        }
      }

      // 4. Not signed in → login
      if (loggedIn == false && !state.uri.path.startsWith('/login')) {
        return '/login';
      }

      // 5. Profile incomplete → setup
      final needsProfileSetup =
          userProfile == null ||
          userProfile.displayName.isEmpty ||
          userProfile.realName == null ||
          userProfile.realName!.isEmpty;

      if (loggedIn &&
          needsProfileSetup &&
          !state.uri.path.startsWith('/login/profile-setup')) {
        return '/login/profile-setup';
      }

      return null;
    },
    errorPageBuilder: (context, state) =>
        adaptivePageBuilder(ErrorScreen(uriPath: state.uri.path)),
    routes: $appRoutes,
  );
});

Page<dynamic> adaptivePageBuilder(Widget child) {
  if (kIsWeb) {
    return MaterialPage(child: child);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    return MaterialPage(child: child);
  } else {
    return MaterialPage(child: child);
  }
}

void popShellRoute(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  Navigator.of(context).pop();
}
