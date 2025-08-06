import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRouterObserver extends NavigatorObserver {
  AppRouterObserver(this.ref);
  final Ref ref;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // final location = route.settings.name ?? route.settings.arguments.toString();
    // print('MyTest didPush: $location');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    //
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    //
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      final location =
          newRoute.settings.name ?? newRoute.settings.arguments.toString();

      if (location == 'Home') {
        // ref.read(gameControllerProvider.notifier).resetOldProviders();
      }
    }
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    final location =
        topRoute.settings.name ?? topRoute.settings.arguments.toString();

    if (location == 'Home') {
      // ref.read(gameControllerProvider.notifier).resetOldProviders();
    }

    super.didChangeTop(topRoute, previousTopRoute);
  }
}
