import 'dart:async';
import 'dart:developer';

import 'package:congregate/src/congregate_app.dart';
import 'package:congregate/src/utils/main_initialization_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      final container = await MainInitializationUtils.initializeProviders();
      await MainInitializationUtils.setupUI();

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const CongregateApp(),
        ),
      );

      // await SentryFlutter.init(
      //   (options) {
      //     options
      //       ..dsn =
      //           'https://b5e9f65cdbb00fdf75a18f5d6ab1b1d8@o4509785979879424.ingest.de.sentry.io/4509785981911120'
      //       ..sendDefaultPii = true;
      //   },
      //   appRunner: () => runApp(
      //     UncontrolledProviderScope(
      //       container: container,
      //       child: const CongregateApp(),
      //     ),
      //   ),
      // );
    },
    (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      print(error);
    },
  );
}
