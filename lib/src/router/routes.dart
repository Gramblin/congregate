import 'dart:io';

import 'package:congregate/src/features/group/presentation/view/create_group_sheet.dart';
import 'package:congregate/src/features/group/presentation/view/group_invite_screen.dart';
import 'package:congregate/src/features/group_details/presentation/views/create_event_sheet.dart';
import 'package:congregate/src/features/group_details/presentation/views/edit_group_details_sheet.dart';
import 'package:congregate/src/features/group_details/presentation/views/event_attendees_list_sheet.dart';
import 'package:congregate/src/features/group_details/presentation/views/group_details_screen.dart';
import 'package:congregate/src/features/home/presentation/view/home_screen.dart';
import 'package:congregate/src/features/home/presentation/view/join_group_sheet.dart';
import 'package:congregate/src/features/login/presentation/login_screen.dart';
import 'package:congregate/src/features/profile/presentation/controllers/views/profile_screen.dart';
import 'package:congregate/src/features/profile/presentation/controllers/views/profile_setup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

part 'routes.g.dart';

@TypedGoRoute<LoginRoute>(
  path: '/login',
  routes: [TypedGoRoute<ProfileSetupRoute>(path: 'profile-setup')],
)
@immutable
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return Platform.isAndroid
        ? const MaterialPage(child: LoginScreen(), name: 'Login')
        : const CupertinoPage(child: LoginScreen(), name: 'Login');
  }
}

@immutable
class ProfileSetupRoute extends GoRouteData with $ProfileSetupRoute {
  const ProfileSetupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return Platform.isAndroid
        ? const MaterialPage(child: ProfileSetupScreen(), name: 'ProfileSetup')
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

@TypedGoRoute<GroupInviteRoute>(path: '/invite/:inviteCode')
@immutable
class GroupInviteRoute extends GoRouteData with $GroupInviteRoute {
  const GroupInviteRoute({required this.inviteCode});

  final String inviteCode;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return Platform.isAndroid
        ? MaterialPage(
            child: GroupInviteScreen(inviteCode: inviteCode),
            name: 'GroupInvite',
          )
        : CupertinoPage(
            child: GroupInviteScreen(inviteCode: inviteCode),
            name: 'GroupInvite',
          );
  }
}

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

@TypedGoRoute<GroupDetailsRoute>(path: '/group-details')
@immutable
class GroupDetailsRoute extends GoRouteData with $GroupDetailsRoute {
  const GroupDetailsRoute({
    required this.isPublic,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;
  final bool isPublic;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return Platform.isAndroid
        ? MaterialPage(
            child: GroupDetailsScreen(
              groupId: groupId,
              groupName: groupName,
              isPublic: isPublic,
            ),
            name: 'CreateGroup',
          )
        : CupertinoPage(
            child: GroupDetailsScreen(
              groupId: groupId,
              groupName: groupName,
              isPublic: isPublic,
            ),
            name: 'CreateGroup',
          );
  }
}

@TypedGoRoute<CreateEventModalSheetRoute>(path: '/create-event-modal')
@immutable
class CreateEventModalSheetRoute extends GoRouteData
    with $CreateEventModalSheetRoute {
  const CreateEventModalSheetRoute({required this.groupId});

  final String groupId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return ModalSheetPage(
      swipeDismissible: true,
      child: CreateEventBottomSheet(groupId: groupId),
      viewportPadding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top,
      ),
    );
  }
}

@TypedGoRoute<EditGroupDetailsModalSheetRoute>(
  path: '/edit-group-details-modal',
)
@immutable
class EditGroupDetailsModalSheetRoute extends GoRouteData
    with $EditGroupDetailsModalSheetRoute {
  const EditGroupDetailsModalSheetRoute({
    required this.groupId,
    required this.groupName,
    required this.isPublic,
  });

  final String groupId;
  final String groupName;
  final bool isPublic;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return ModalSheetPage(
      swipeDismissible: true,
      child: EditGroupDetailsSheet(
        groupId: groupId,
        groupName: groupName,
        isPublic: isPublic,
      ),
      viewportPadding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top,
      ),
    );
  }
}

@TypedGoRoute<EventAttendiesListModalSheetRoute>(path: '/attendees-list')
@immutable
class EventAttendiesListModalSheetRoute extends GoRouteData
    with $EventAttendiesListModalSheetRoute {
  const EventAttendiesListModalSheetRoute({required this.eventId});

  final String eventId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return ModalSheetPage(
      swipeDismissible: true,
      child: EventAttendeesListSheet(eventId: eventId),
      viewportPadding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top,
      ),
    );
  }
}

@TypedGoRoute<CreateGroupModalSheetRoute>(path: '/new-group-sheet')
@immutable
class CreateGroupModalSheetRoute extends GoRouteData
    with $CreateGroupModalSheetRoute {
  const CreateGroupModalSheetRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return ModalSheetPage(
      swipeDismissible: true,
      child: const CreateGroupSheet(),
      viewportPadding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top,
      ),
    );
  }
}

@TypedGoRoute<JoinGroupModalSheetRoute>(path: '/join-group-modal')
@immutable
class JoinGroupModalSheetRoute extends GoRouteData
    with $JoinGroupModalSheetRoute {
  const JoinGroupModalSheetRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return ModalSheetPage(
      swipeDismissible: true,
      child: const JoinGroupSheet(),
      name: 'JoinGroup',
      viewportPadding: EdgeInsets.only(
        top: MediaQuery.viewPaddingOf(context).top,
      ),
    );
  }
}
