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
    },
    (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      print(error);
    },
  );
}
