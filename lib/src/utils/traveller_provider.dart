import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'traveller_provider.g.dart';

@Riverpod(keepAlive: true)
class TravellerNotifier extends _$TravellerNotifier {
  static const _key = 'is_traveller';

  @override
  bool build() =>
      ref.read(preferencesProvider).getBool(_key) ?? false;

  Future<void> setTraveller(bool value) async {
    await ref.read(preferencesProvider).setBool(_key, value);
    state = value;
  }
}
