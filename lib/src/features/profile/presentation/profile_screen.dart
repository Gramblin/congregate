import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name'.hardcoded),
            SizedBox(
              child: IconButton(
                padding: const EdgeInsets.symmetric(vertical: Sizes.p16),
                onPressed: () {},
                icon: Row(
                  spacing: Sizes.p16,
                  children: [
                    Text('Share Profile'.hardcoded),
                    const Icon(Icons.groups_outlined),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
