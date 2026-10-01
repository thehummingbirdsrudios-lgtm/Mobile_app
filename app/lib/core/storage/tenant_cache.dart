/// In-memory cache whose keys are ALWAYS namespaced by tenant and user, so
/// data from one business can never be served to another (even briefly
/// during account switching). Bounded LRU; cleared completely on sign-out.
class TenantCache {
  TenantCache({this.maxEntries = 500}) : assert(maxEntries > 0);

  final int maxEntries;
  // Insertion-ordered map: first key = least recently used.
  final _entries = <String, Object>{};
  String? _scope;

  /// Binds the cache to a signed-in identity. Changing identity wipes it.
  void bind({required String tenantId, required String userId}) {
    final next = '$tenantId/$userId';
    if (_scope != next) {
      _entries.clear();
      _scope = next;
    }
  }

  /// Unbinds and drops everything (sign-out, session expiry, revocation).
  void clear() {
    _entries.clear();
    _scope = null;
  }

  bool get isBound => _scope != null;

  String _key(String key) {
    final scope = _scope;
    if (scope == null) throw StateError('TenantCache used before a session was bound');
    return '$scope/$key';
  }

  T? read<T extends Object>(String key) {
    if (_scope == null) return null;
    final k = _key(key);
    final value = _entries.remove(k);
    if (value == null) return null;
    _entries[k] = value; // mark as most recently used
    return value is T ? value : null;
  }

  void write(String key, Object value) {
    final k = _key(key);
    _entries.remove(k);
    _entries[k] = value;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void remove(String key) {
    if (_scope == null) return;
    _entries.remove(_key(key));
  }

  int get length => _entries.length;
}
