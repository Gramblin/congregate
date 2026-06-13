import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cities_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Map<String, List<String>>> citiesData(Ref ref) async {
  final raw = await rootBundle.loadString('assets/cities.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded.map(
    (k, v) => MapEntry(k, (v as List).cast<String>()),
  );
}

List<String> citiesForCountry(
  Map<String, List<String>>? data,
  String? countryCode,
) {
  if (data == null || countryCode == null) return [];
  return data[countryCode] ?? [];
}
