import 'dart:io';
import 'dart:typed_data';

/// Stores optimised images by key (see `optimizedImageCacheKey`), so a design
/// that appears on many bills is downloaded and processed once.
abstract interface class ImageCacheService {
  Future<Uint8List?> read(String key);

  Future<void> write(String key, Uint8List bytes);

  /// Drops everything (sign-out: another business must not inherit it).
  Future<void> clear();
}

final _validKey = RegExp(r'^[0-9a-f]{64}$');

/// Bounded in-memory LRU (by bytes).
class MemoryImageCache implements ImageCacheService {
  MemoryImageCache({this.maxBytes = 8 * 1024 * 1024});

  final int maxBytes;
  final _entries = <String, Uint8List>{};
  int _bytes = 0;

  int get length => _entries.length;

  @override
  Future<Uint8List?> read(String key) async {
    final hit = _entries.remove(key);
    if (hit != null) _entries[key] = hit; // most recently used
    return hit;
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    if (bytes.length > maxBytes) return;
    final old = _entries.remove(key);
    if (old != null) _bytes -= old.length;
    _entries[key] = bytes;
    _bytes += bytes.length;
    while (_bytes > maxBytes && _entries.isNotEmpty) {
      final first = _entries.keys.first;
      _bytes -= _entries.remove(first)!.length;
    }
  }

  @override
  Future<void> clear() async {
    _entries.clear();
    _bytes = 0;
  }
}

/// Files in the app's private support directory, so bills can be rebuilt
/// offline from already-processed photos. Bounded: least recently used
/// files are evicted beyond [maxBytes]. Keys are hex digests (no paths), so
/// a key can never escape the cache folder.
class DiskImageCache implements ImageCacheService {
  DiskImageCache(this._directory, {this.maxBytes = 64 * 1024 * 1024});

  final Future<Directory> Function() _directory;
  final int maxBytes;
  Directory? _dir;

  Future<Directory> _folder() async {
    final dir = _dir ??= await _directory();
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  File _file(Directory dir, String key) => File('${dir.path}/$key.jpg');

  @override
  Future<Uint8List?> read(String key) async {
    if (!_validKey.hasMatch(key)) return null;
    final file = _file(await _folder(), key);
    if (!file.existsSync()) return null;
    try {
      final bytes = await file.readAsBytes();
      await file.setLastModified(DateTime.now());
      return bytes;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    if (!_validKey.hasMatch(key)) return;
    final dir = await _folder();
    final tmp = File('${dir.path}/$key.tmp');
    try {
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(_file(dir, key).path); // atomic: never a half-written cache entry
      await _evict(dir);
    } on FileSystemException {
      // A full or read-only disk only costs a re-download next time.
    }
  }

  Future<void> _evict(Directory dir) async {
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg')).toList();
    var total = files.fold<int>(0, (sum, f) => sum + f.lengthSync());
    if (total <= maxBytes) return;
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    for (final f in files) {
      if (total <= maxBytes) break;
      total -= f.lengthSync();
      await f.delete();
    }
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _folder();
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on Object {
      // Storage unavailable (or never created): nothing to clear.
    }
    _dir = null;
  }
}

/// Memory first, then disk (disk hits are promoted to memory).
class TieredImageCache implements ImageCacheService {
  TieredImageCache(this._memory, this._disk);

  final ImageCacheService _memory;
  final ImageCacheService _disk;

  @override
  Future<Uint8List?> read(String key) async {
    final hot = await _memory.read(key);
    if (hot != null) return hot;
    final cold = await _disk.read(key);
    if (cold != null) await _memory.write(key, cold);
    return cold;
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    await _memory.write(key, bytes);
    await _disk.write(key, bytes);
  }

  @override
  Future<void> clear() async {
    await _memory.clear();
    await _disk.clear();
  }
}
