import 'dart:convert';

import '../../../settings/settings.dart';

/// Last few queries per identity, newest first, in device preferences.
class RecentSearchStore {
  RecentSearchStore(this._prefs, {this.maxEntries = 8});

  final PreferenceStore _prefs;
  final int maxEntries;

  String _key(String scope) => 'search.recent.$scope';

  List<String> read(String scope) {
    final raw = _prefs.getString(_key(scope));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List
          ? [
              for (final q in decoded)
                if (q is String && q.isNotEmpty) q,
            ]
          : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> add(String scope, String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [q, ...read(scope).where((e) => e.toLowerCase() != q.toLowerCase())].take(maxEntries).toList();
    await _prefs.setString(_key(scope), jsonEncode(next));
  }

  Future<void> clear(String scope) => _prefs.setString(_key(scope), '[]');
}
