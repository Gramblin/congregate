import 'package:congregate/src/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: IconButton(
                onPressed: () {
                  const ProfileRoute().go(context);
                },
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.groups_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
