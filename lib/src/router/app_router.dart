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
      // return '/home';
      final loggedIn = Supabase.instance.client.auth.currentUser != null;

      // 1. Skip redirects for alert dialogs
      if (state.fullPath?.startsWith('/alert-dialog') ?? false) {
        return null;
      }

      final uri = state.uri;

      // 2. Handle deep links like suffah://game/{roomId}
      if (uri.scheme == 'suffah' && uri.host == 'game') {
        final roomId = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null;
        if (roomId != null && state.uri.path != '/game/$roomId') {
          // ref.read(gameControllerProvider.notifier).joinRoom(roomId);
          return '/home/game/$roomId';
        }
      }

      // 3. Handle deep links like suffah://friend/{userId}/{username}
      if (uri.scheme == 'suffah' && uri.host == 'friend') {
        final segments = uri.pathSegments;
        final userId = segments.isNotEmpty ? segments[0] : null;
        final username = segments.length > 1 ? segments[1] : null;

        if (userId != null && username != null) {
          final path = '/friend/$userId/$username';
          if (state.uri.path != path) {
            return path;
          }
        }
      }

      // ✅ 4. Handle deep links like suffah://profile/{userId}
      if (uri.scheme == 'suffah' && uri.host == 'profile') {
        final userId = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null;

        if (userId != null && state.uri.path != '/profile/$userId') {
          return '/profile/$userId';
        }
      }

      // 5. Not signed in → login

      if (loggedIn == false && !state.uri.path.startsWith('/login')) {
        return '/login';
      }

      // log('prif $userProfile');

      // 6. Profile incomplete → setup
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
