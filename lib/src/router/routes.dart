// part 'routes.g.dart';

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

// @TypedGoRoute<LoginRoute>(
//   path: '/login',
//   routes: [TypedGoRoute<ProfileSetupRoute>(path: 'profile-setup')],
// )
// @immutable
// class LoginRoute extends GoRouteData {
//   const LoginRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(child: LoginScreen(), name: 'Login')
//         : const CupertinoPage(child: LoginScreen(), name: 'Login');
//   }
// }

// @immutable
// class ProfileSetupRoute extends GoRouteData {
//   const ProfileSetupRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(child: ProfileSetupScreen(), name: 'ProfileSetup')
//         : const CupertinoPage(
//             child: ProfileSetupScreen(),
//             name: 'ProfileSetup',
//           );
//   }
// }

// @TypedGoRoute<GameOverRoute>(path: '/game-over')
// @immutable
// class GameOverRoute extends GoRouteData {
//   const GameOverRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(child: GameOverScreen(), name: 'GameOver')
//         : const CupertinoPage(child: GameOverScreen(), name: 'GameOver');
//   }
// }

// @TypedGoRoute<LoginCallbackRoute>(path: '/login-callback')
// @immutable
// class LoginCallbackRoute extends GoRouteData {
//   const LoginCallbackRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? CupertinoPage(
//             child: Scaffold(
//               appBar: AppBar(
//                 title: const SelectableText('Debug Login Callback Screen'),
//               ),
//             ),
//           )
//         : CupertinoPage(
//             child: Scaffold(
//               appBar: AppBar(
//                 title: const SelectableText('Debug Login Callback Screen'),
//               ),
//             ),
//           );
//   }
// }

// @TypedGoRoute<AnimatedTextWidgetRoute>(path: '/test-animated-widget')
// @immutable
// class AnimatedTextWidgetRoute extends GoRouteData {
//   const AnimatedTextWidgetRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(
//             child: AnimatedTextWidgetScreen(),
//             name: 'AnimatedText',
//           )
//         : const CupertinoPage(
//             child: AnimatedTextWidgetScreen(),
//             name: 'AnimatedText',
//           );
//   }
// }

// @TypedGoRoute<HomeRoute>(
//   path: '/home',
//   routes: [
//     TypedGoRoute<TestRoomRoute>(path: 'test-room-screen'),
//     TypedGoRoute<WaitingOpponentRoute>(path: 'waiting-opponent'),
//     TypedGoRoute<GameRoute>(path: 'game/:roomId'),
//     TypedGoRoute<UserProfileSettingsRoute>(path: 'user-profile-settings'),
//     TypedGoRoute<FriendsRoute>(path: 'friends-list'),
//   ],
// )
// @immutable
// class HomeRoute extends GoRouteData {
//   const HomeRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(child: HomeScreen(), name: 'Home')
//         : const CupertinoPage(child: HomeScreen(), name: 'Home');
//   }
// }

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

// @immutable
// class UserProfileSettingsRoute extends GoRouteData {
//   const UserProfileSettingsRoute();

//   @override
//   Page<void> buildPage(BuildContext context, GoRouterState state) {
//     return kIsWeb
//         ? const CupertinoPage(
//             child: UserProfileSettingsScreen(),
//             name: 'UserProfileSettings',
//           )
//         : const CupertinoPage(
//             child: UserProfileSettingsScreen(),
//             name: 'UserProfileSettings',
//           );
//   }
// }

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
//         child: const GramblinDialogScreen(),
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
