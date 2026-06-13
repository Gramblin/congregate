import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'dark_mode';

  @override
  ThemeMode build() {
    final isDark = ref.read(preferencesProvider).getBool(_key) ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final isDark = state == ThemeMode.dark;
    await ref.read(preferencesProvider).setBool(_key, !isDark);
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
