import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps any screen with the persistent bottom navigation bar.
/// Each top-level screen uses this — no StatefulShellRoute needed.
class BottomNavScaffold extends StatelessWidget {
  const BottomNavScaffold({required this.child, super.key});

  final Widget child;

  static int _indexForPath(String path) {
    if (path.startsWith('/feed')) return 0;
    if (path.startsWith('/home')) return 1;
    if (path.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForPath(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/feed');
            case 1: context.go('/home');
            case 2: context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
