import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_provider.g.dart';

class UserLocation {
  const UserLocation({this.country, this.city});
  final String? country;
  final String? city;

  UserLocation copyWith({String? country, String? city}) => UserLocation(
    country: country ?? this.country,
    city: city ?? this.city,
  );

  bool get hasLocation => country != null;

  @override
  String toString() {
    if (country == null) return 'Set location';
    if (city != null && city!.isNotEmpty) return '$city, $country';
    return country!;
  }
}

@Riverpod(keepAlive: true)
class LocationNotifier extends _$LocationNotifier {
  static const _countryKey = 'location_country';
  static const _cityKey = 'location_city';

  @override
  UserLocation build() {
    final prefs = ref.read(preferencesProvider);
    return UserLocation(
      country: prefs.getString(_countryKey),
      city: prefs.getString(_cityKey),
    );
  }

  Future<void> setLocation({required String country, String? city}) async {
    final prefs = ref.read(preferencesProvider);
    await prefs.setString(_countryKey, country);
    if (city != null && city.isNotEmpty) {
      await prefs.setString(_cityKey, city);
    } else {
      await prefs.remove(_cityKey);
    }
    state = UserLocation(country: country, city: city);
  }

  Future<void> clear() async {
    final prefs = ref.read(preferencesProvider);
    await prefs.remove(_countryKey);
    await prefs.remove(_cityKey);
    state = const UserLocation();
  }
}

/// Country list: ISO 3166-1 alpha-2 code + display name.
const kCountries = [
  ('AF', 'Afghanistan'),
  ('AL', 'Albania'),
  ('DZ', 'Algeria'),
  ('AO', 'Angola'),
  ('AR', 'Argentina'),
  ('AU', 'Australia'),
  ('AZ', 'Azerbaijan'),
  ('BH', 'Bahrain'),
  ('BD', 'Bangladesh'),
  ('BE', 'Belgium'),
  ('BJ', 'Benin'),
  ('BN', 'Brunei'),
  ('BF', 'Burkina Faso'),
  ('CA', 'Canada'),
  ('CM', 'Cameroon'),
  ('CF', 'Central African Republic'),
  ('TD', 'Chad'),
  ('KM', 'Comoros'),
  ('CD', 'DR Congo'),
  ('DJ', 'Djibouti'),
  ('EG', 'Egypt'),
  ('ER', 'Eritrea'),
  ('ET', 'Ethiopia'),
  ('FR', 'France'),
  ('GM', 'Gambia'),
  ('DE', 'Germany'),
  ('GH', 'Ghana'),
  ('GN', 'Guinea'),
  ('GW', 'Guinea-Bissau'),
  ('GY', 'Guyana'),
  ('ID', 'Indonesia'),
  ('IR', 'Iran'),
  ('IQ', 'Iraq'),
  ('IE', 'Ireland'),
  ('IN', 'India'),
  ('IL', 'Israel'),
  ('IT', 'Italy'),
  ('CI', 'Ivory Coast'),
  ('JO', 'Jordan'),
  ('KZ', 'Kazakhstan'),
  ('KE', 'Kenya'),
  ('KW', 'Kuwait'),
  ('KG', 'Kyrgyzstan'),
  ('LB', 'Lebanon'),
  ('LY', 'Libya'),
  ('MY', 'Malaysia'),
  ('MV', 'Maldives'),
  ('ML', 'Mali'),
  ('MR', 'Mauritania'),
  ('MA', 'Morocco'),
  ('MZ', 'Mozambique'),
  ('NL', 'Netherlands'),
  ('NE', 'Niger'),
  ('NG', 'Nigeria'),
  ('OM', 'Oman'),
  ('PK', 'Pakistan'),
  ('PS', 'Palestine'),
  ('QA', 'Qatar'),
  ('RU', 'Russia'),
  ('SA', 'Saudi Arabia'),
  ('SN', 'Senegal'),
  ('SL', 'Sierra Leone'),
  ('SO', 'Somalia'),
  ('ZA', 'South Africa'),
  ('SS', 'South Sudan'),
  ('ES', 'Spain'),
  ('LK', 'Sri Lanka'),
  ('SD', 'Sudan'),
  ('SR', 'Suriname'),
  ('SE', 'Sweden'),
  ('SY', 'Syria'),
  ('TJ', 'Tajikistan'),
  ('TZ', 'Tanzania'),
  ('TH', 'Thailand'),
  ('TG', 'Togo'),
  ('TN', 'Tunisia'),
  ('TR', 'Turkey'),
  ('TM', 'Turkmenistan'),
  ('UG', 'Uganda'),
  ('UA', 'Ukraine'),
  ('AE', 'United Arab Emirates'),
  ('GB', 'United Kingdom'),
  ('US', 'United States'),
  ('UZ', 'Uzbekistan'),
  ('YE', 'Yemen'),
];
