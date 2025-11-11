import 'dart:io';

import 'package:congregate/src/features/create_group/presentation/view/create_group_screen.dart';
import 'package:congregate/src/features/home/presentation/home_screen.dart';
import 'package:congregate/src/features/login/presentation/login_screen.dart';
import 'package:congregate/src/features/profile/presentation/controllers/views/profile_screen.dart';
import 'package:congregate/src/features/profile/presentation/controllers/views/profile_setup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';

// @TypedGoRoute<FriendRequestRoute>(path: '/friend/:userId/:username')
// @immutable
// class FriendRequestRoute extends GoRouteData {
//   const FriendRequestRoute({required this.userId, required this.username});

//   final String userId;
//   final String username;

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? CupertinoPage(
//             child: FriendRequestScreen(userId: userId, username: username),
//             name: 'FriendRequest',
//           )
//         : CupertinoPage(
//             child: FriendRequestScreen(userId: userId, username: username),
//             name: 'FriendRequest',
//           );
//   }
// }

// @TypedGoRoute<PublicProfileRoute>(path: '/profile/:userId')
// @immutable
// class PublicProfileRoute extends GoRouteData {
//   const PublicProfileRoute({required this.userId});

//   final String userId;

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? CupertinoPage(
//             child: PublicProfileScreen(userId: userId),
//             name: 'PublicProfile',
//           )
//         : CupertinoPage(
//             child: PublicProfileScreen(userId: userId),
//             name: 'PublicProfile',
//           );
//   }
// }

@TypedGoRoute<LoginRoute>(
  path: '/login',
  routes: [TypedGoRoute<ProfileSetupRoute>(path: 'profile-setup')],
)
@immutable
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return kIsWeb
        ? const CupertinoPage(child: LoginScreen(), name: 'Login')
        : const CupertinoPage(child: LoginScreen(), name: 'Login');
  }
}

@immutable
class ProfileSetupRoute extends GoRouteData with $ProfileSetupRoute {
  const ProfileSetupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return kIsWeb
        ? const CupertinoPage(child: ProfileSetupScreen(), name: 'ProfileSetup')
        : const CupertinoPage(
            child: ProfileSetupScreen(),
            name: 'ProfileSetup',
          );
  }
}

@TypedGoRoute<HomeRoute>(
  path: '/home',
  routes: [TypedGoRoute<ProfileRoute>(path: 'profile')],
)
@immutable
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return Platform.isAndroid
        ? const MaterialPage(child: HomeScreen(), name: 'Home')
        : const CupertinoPage(child: HomeScreen(), name: 'Home');
  }
}

// @immutable
// class TestRoomRoute extends GoRouteData {
//   const TestRoomRoute({required this.isScrolling});

//   final bool isScrolling;

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? CupertinoPage(
//             child: TestRoomScreen(isScrolling: isScrolling),
//             name: 'TestRoom',
//           )
//         : CupertinoPage(
//             child: TestRoomScreen(isScrolling: isScrolling),
//             name: 'TestRoom',
//           );
//   }
// }

// @immutable
// class WaitingOpponentRoute extends GoRouteData {
//   const WaitingOpponentRoute({this.friendId});

//   final String? friendId;

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? CupertinoPage(
//             child: WaitingOpponentScreen(friendId: friendId),
//             name: 'WaitingOpponent',
//           )
//         : CupertinoPage(
//             child: WaitingOpponentScreen(friendId: friendId),
//             name: 'WaitingOpponent',
//           );
//   }
// }

// @immutable
// class GameRoute extends GoRouteData {
//   const GameRoute({required this.roomId});

//   final String roomId;

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? CupertinoPage(
//             child: GameScreen(roomId: roomId),
//             name: 'Game',
//           )
//         : CupertinoPage(
//             child: GameScreen(roomId: roomId),
//             name: 'Game',
//           );
//   }
// }

@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return Platform.isAndroid
        ? const MaterialPage(
            child: ProfileScreen(),
            name: 'Profile',
          )
        : const CupertinoPage(
            child: ProfileScreen(),
            name: 'Profile',
          );
  }
}

@TypedGoRoute<CreateGroupRoute>(
  path: '/create-group',
)
@immutable
class CreateGroupRoute extends GoRouteData with $CreateGroupRoute {
  const CreateGroupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return kIsWeb
        ? const CupertinoPage(child: CreateGroupScreen(), name: 'CreateGroup')
        : const CupertinoPage(child: CreateGroupScreen(), name: 'CreateGroup');
  }
}

// @immutable
// class FriendsRoute extends GoRouteData {
//   const FriendsRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(child: FriendsScreen(), name: 'Friends')
//         : const CupertinoPage(child: FriendsScreen(), name: 'Friends');
//   }
// }

// @TypedGoRoute<InfoDialogRoute>(path: '/dialog')
// @immutable
// class InfoDialogRoute extends GoRouteData {
//   const InfoDialogRoute({this.dismissible = true});

//   final bool dismissible;

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return CustomTransitionPage(
//       name: 'InfoDialog',
//       child: Dialog(
//         shadowColor: Colors.transparent,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.white,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadiusGeometry.circular(Sizes.p8),
//         ),
//         child: const SuffahDialogScreen(),
//       ),
//       barrierColor: Colors.black45,
//       opaque: false,
//       barrierDismissible: dismissible,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         final scaleTween = Tween(
//           begin: 0.8,
//           end: 1.toDouble(),
//         ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
//         final opacityTween = Tween(
//           begin: 0.toDouble(),
//           end: 1.toDouble(),
//         ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

//         return FadeTransition(
//           opacity: opacityTween,
//           child: ScaleTransition(scale: scaleTween, child: child),
//         );
//       },
//     );
//   }
// }

// @TypedGoRoute<LeaderboardRoute>(path: '/leaderboard')
// @immutable
// class LeaderboardRoute extends GoRouteData {
//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(child: LeaderboardScreen(), name: 'Leaderboard')
//         : const CupertinoPage(child: LeaderboardScreen(), name: 'Leaderboard');
//   }
// }

// @TypedGoRoute<TestFunctionalitiesRoute>(path: '/test-screens')
// @immutable
// class TestFunctionalitiesRoute extends GoRouteData {
//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(
//             child: TestFunctionalitiesScreen(),
//             name: 'TestFunctionalities',
//           )
//         : const CupertinoPage(
//             child: TestFunctionalitiesScreen(),
//             name: 'TestFunctionalities',
//           );
//   }
// }
