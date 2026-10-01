/// Strict, typed access to decoded JSON. A missing or mistyped field throws
/// [FormatException] naming the field, which the API client converts into a
/// `FailureKind.invalidResponse` — malformed server data never crashes the UI.
extension JsonReader on Map<String, dynamic> {
  String requireString(String key) {
    final value = this[key];
    if (value is String) return value;
    throw FormatException('expected string', key);
  }

  String? optionalString(String key) {
    final value = this[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('expected string or null', key);
  }

  int requireInt(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is num && value == value.truncate()) return value.toInt();
    throw FormatException('expected integer', key);
  }

  /// ISO-8601 timestamp (as PostgREST sends timestamptz).
  DateTime requireDateTime(String key) {
    final value = this[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('expected timestamp', key);
  }

  DateTime? optionalDateTime(String key) => this[key] == null ? null : requireDateTime(key);

  /// Money in paise; null stays null (e.g. Baki hidden by permissions).
  int? optionalInt(String key) => this[key] == null ? null : requireInt(key);

  List<String> stringList(String key) {
    final value = this[key];
    if (value == null) return const [];
    if (value is List && value.every((e) => e is String)) return value.cast<String>();
    throw FormatException('expected list of strings', key);
  }
}

/// Casts a decoded JSON value to an object map or throws [FormatException].
Map<String, dynamic> asJsonObject(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw const FormatException('expected JSON object');
}
