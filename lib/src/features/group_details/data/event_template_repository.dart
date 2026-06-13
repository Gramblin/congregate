import 'dart:convert';

import 'package:congregate/src/features/group_details/domain/event_template.dart';
import 'package:congregate/src/utils/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_template_repository.g.dart';

@Riverpod(keepAlive: true)
class EventTemplateNotifier extends _$EventTemplateNotifier {
  static const _key = 'event_templates_v1';

  @override
  List<EventTemplate> build() {
    final raw = ref.read(preferencesProvider).getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EventTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception {
      return [];
    }
  }

  Future<void> save(EventTemplate template) async {
    final updated = [
      ...state.where((t) => t.name != template.name),
      template,
    ];
    state = updated;
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final updated = state.where((t) => t.id != id).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(List<EventTemplate> templates) =>
      ref.read(preferencesProvider).setString(
        _key,
        jsonEncode(templates.map((t) => t.toJson()).toList()),
      );
}
