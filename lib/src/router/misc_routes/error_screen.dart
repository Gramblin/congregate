import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({required this.uriPath, super.key});

  final String uriPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.scrim,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: Sizes.p12,
          children: [
            Icon(
              MdiIcons.routes,
              size: Sizes.p64,
              color: context.colorScheme.errorContainer,
            ),
            SelectableText(
              '404',
              style: context.textTheme.displayLarge!.copyWith(
                color: context.colorScheme.error,
                shadows: [
                  Shadow(
                    color: context.colorScheme.errorContainer,
                    offset: const Offset(10, 10),
                  ),
                  Shadow(
                    color: context.colorScheme.onPrimaryFixedVariant.withValues(
                      alpha: 0.2,
                    ),
                    offset: const Offset(-10, -10),
                  ),
                ],
              ),
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: context.textTheme.titleLarge,
                children: [
                  TextSpan(text: 'Path '.hardcoded),
                  TextSpan(
                    text: uriPath,
                    style: TextStyle(color: context.colorScheme.error),
                  ),
                  TextSpan(text: ' was not found.'.hardcoded),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // const HomeRoute().go(context);
        },
        label: Row(
          spacing: Sizes.p12,
          children: [
            const Icon(Icons.home_outlined),
            Text('Go Home'.hardcoded),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
