import 'dart:io';

import 'package:congregate/src/features/group/presentation/view/create_group_sheet.dart';
import 'package:congregate/src/features/group/presentation/view/group_invite_screen.dart';
import 'package:congregate/src/features/group_details/presentation/views/create_event_sheet.dart';
import 'package:congregate/src/features/group_details/presentation/views/edit_group_details_sheet.dart';
import 'package:congregate/src/features/group_details/presentation/views/event_attendees_list_sheet.dart';
import 'package:congregate/src/features/group_details/presentation/views/group_details_screen.dart';
import 'package:congregate/src/features/group_details/presentation/views/share_private_group_sheet.dart';
import 'package:congregate/src/features/home/presentation/view/events_feed_screen.dart';
import 'package:congregate/src/features/home/presentation/view/home_screen.dart';
import 'package:congregate/src/features/home/presentation/view/join_group_sheet.dart';
import 'package:congregate/src/features/login/presentation/account_recovery_screen.dart';
import 'package:congregate/src/features/login/presentation/login_screen.dart';
import 'package:congregate/src/features/login/presentation/recovery_token_screen.dart';
import 'package:congregate/src/features/profile/presentation/controllers/user_profile_notifier.dart';
import 'package:congregate/src/features/profile/presentation/controllers/views/profile_screen.dart';
import 'package:congregate/src/features/profile/presentation/controllers/views/profile_setup_screen.dart';
import 'package:congregate/src/router/app_router_observer.dart';
import 'package:congregate/src/router/misc_routes/error_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  final userProfile = profileAsync.value;

  return GoRouter(
    initialLocation: '/feed',
    navigatorKey: rootNavigatorKey,
    observers: [AppRouterObserver(ref)],
    redirect: (context, state) {
      // Profile is still loading — don't touch navigation
      if (profileAsync.isLoading) return null;

      final loggedIn = Supabase.instance.client.auth.currentUser != null;

      if (state.fullPath?.startsWith('/alert-dialog') ?? false) return null;

      final uri = state.uri;

      // Deep link: congregate://invite/{code}
      if (uri.scheme == 'congregate' && uri.host == 'invite') {
        final code = uri.pathSegments.firstOrNull;
        if (code != null) return '/invite/$code';
      }

      if (!loggedIn && !state.uri.path.startsWith('/login')) return '/login';

      final needsSetup =
          userProfile == null || userProfile.displayName.isEmpty;

      if (loggedIn &&
          needsSetup &&
          !state.uri.path.startsWith('/login/profile-setup')) {
        return '/login/profile-setup';
      }

      return null;
    },
    errorPageBuilder: (context, state) =>
        adaptivePageBuilder(ErrorScreen(uriPath: state.uri.path)),
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => adaptivePageBuilder(const LoginScreen()),
        routes: [
          GoRoute(
            path: 'profile-setup',
            pageBuilder: (ctx, state) =>
                adaptivePageBuilder(const ProfileSetupScreen()),
            routes: [
              GoRoute(
                path: 'recovery-token',
                pageBuilder: (ctx, state) =>
                    adaptivePageBuilder(const RecoveryTokenScreen()),
              ),
            ],
          ),
          GoRoute(
            path: 'recover',
            pageBuilder: (ctx, state) =>
                adaptivePageBuilder(const AccountRecoveryScreen()),
          ),
        ],
      ),

      // ── Bottom nav tabs (each wraps itself with BottomNavScaffold) ────────
      GoRoute(
        path: '/feed',
        pageBuilder: (ctx, state) =>
            adaptivePageBuilder(const EventsFeedScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (ctx, state) => adaptivePageBuilder(const HomeScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (ctx, state) => adaptivePageBuilder(const ProfileScreen()),
      ),

      // ── Group details (full-screen, no bottom nav) ────────────────────────
      GoRoute(
        path: '/group/:groupId',
        pageBuilder: (ctx, state) {
          final groupId = state.pathParameters['groupId']!;
          final q = state.uri.queryParameters;
          return adaptivePageBuilder(
            GroupDetailsScreen(
              groupId: groupId,
              groupName: q['name'] ?? '',
              isPublic: q['public'] == 'true',
            ),
          );
        },
      ),

      // ── Invite deep link ──────────────────────────────────────────────────
      GoRoute(
        path: '/invite/:inviteCode',
        pageBuilder: (ctx, state) => adaptivePageBuilder(
          GroupInviteScreen(
            inviteCode: state.pathParameters['inviteCode']!,
          ),
        ),
      ),

      // ── Modal sheets ──────────────────────────────────────────────────────
      // Path params — no query param name ambiguity
      GoRoute(
        path: '/create-event/:groupId',
        pageBuilder: (ctx, state) => ModalSheetPage(
          swipeDismissible: true,
          child: CreateEventBottomSheet(
            groupId: state.pathParameters['groupId']!,
          ),
          viewportPadding:
              EdgeInsets.only(top: MediaQuery.viewPaddingOf(ctx).top),
        ),
      ),
      GoRoute(
        path: '/edit-group/:groupId',
        pageBuilder: (ctx, state) {
          final q = state.uri.queryParameters;
          return ModalSheetPage(
            swipeDismissible: true,
            child: EditGroupDetailsSheet(
              groupId: state.pathParameters['groupId']!,
              groupName: q['name'] ?? '',
              isPublic: q['public'] == 'true',
            ),
            viewportPadding:
                EdgeInsets.only(top: MediaQuery.viewPaddingOf(ctx).top),
          );
        },
      ),
      GoRoute(
        path: '/attendees/:eventId',
        pageBuilder: (ctx, state) => ModalSheetPage(
          swipeDismissible: true,
          child: EventAttendeesListSheet(
            eventId: state.pathParameters['eventId']!,
          ),
          viewportPadding:
              EdgeInsets.only(top: MediaQuery.viewPaddingOf(ctx).top),
        ),
      ),
      GoRoute(
        path: '/new-group',
        pageBuilder: (ctx, state) => ModalSheetPage(
          swipeDismissible: true,
          child: const CreateGroupSheet(),
          viewportPadding:
              EdgeInsets.only(top: MediaQuery.viewPaddingOf(ctx).top),
        ),
      ),
      GoRoute(
        path: '/join-group',
        pageBuilder: (ctx, state) => ModalSheetPage(
          swipeDismissible: true,
          child: const JoinGroupSheet(),
          viewportPadding:
              EdgeInsets.only(top: MediaQuery.viewPaddingOf(ctx).top),
        ),
      ),
      GoRoute(
        path: '/share-group/:groupId',
        pageBuilder: (ctx, state) => ModalSheetPage(
          swipeDismissible: true,
          child: SharePrivateGroupSheet(
            groupId: state.pathParameters['groupId']!,
          ),
          viewportPadding:
              EdgeInsets.only(top: MediaQuery.viewPaddingOf(ctx).top),
        ),
      ),
    ],
  );
});

Page<dynamic> adaptivePageBuilder(Widget child) {
  if (kIsWeb) return MaterialPage(child: child);
  if (Platform.isIOS || Platform.isMacOS) return MaterialPage(child: child);
  return MaterialPage(child: child);
}

void popShellRoute(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  Navigator.of(context).pop();
}
