// Enforces the module architecture (docs/architecture/modules.md).
// Run: dart run tool/check_boundaries.dart   (fails with exit code 1)
//
// Rules
//  R1 core never imports features or app.
//  R2 a feature imports another feature ONLY through its public barrel
//     (lib/features/<other>/<other>.dart).
//  R3 domain layers are pure: no Flutter, Riverpod, Supabase, or other layers.
//  R4 presentation and application never import the data layer or Supabase.
//  R5 adapter barrels (*_supabase.dart) and package:supabase_flutter are used
//     only by the composition root (lib/main.dart), data layers, the
//     API client (core/network) and the error mapper (core/errors).
//  R6 Firebase (package:firebase_*) is used only by its push adapter
//     (core/platform/firebase_push.dart), lib/firebase_options.dart and the
//     composition root, so the rest of the app depends on the push port.
import 'dart:io';

final _importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

void main() {
  final lib = Directory('lib');
  final violations = <String>[];

  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') || file.path.contains('/l10n/app_localizations')) continue;
    final from = _normalize(file.path);
    for (final match in _importPattern.allMatches(file.readAsStringSync())) {
      final uri = match.group(1)!;
      final target = _resolve(from, uri);
      final problem = _check(from, uri, target);
      if (problem != null) violations.add('$from → $uri\n    $problem');
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('Module boundaries OK.');
    return;
  }
  stderr.writeln('Module boundary violations (${violations.length}):');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  exitCode = 1;
}

String _normalize(String path) => path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

/// Returns a lib-relative path for project imports, or null for packages/SDK.
String? _resolve(String from, String uri) {
  if (uri.startsWith('package:vepari/')) return 'lib/${uri.substring('package:vepari/'.length)}';
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  final parts = from.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') {
      parts.removeLast();
    } else if (segment != '.') {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

({String module, String layer})? _feature(String path) {
  final m = RegExp(r'^lib/features/([^/]+)/(?:([^/]+)/)?').firstMatch(path);
  if (m == null) return null;
  return (module: m.group(1)!, layer: m.group(2) ?? 'barrel');
}

String? _check(String from, String uri, String? target) {
  final source = _feature(from);
  final isComposition = from == 'lib/main.dart';
  final usesSupabase = uri.startsWith('package:supabase_flutter') || uri.startsWith('package:supabase/');

  // R1
  if (from.startsWith('lib/core/') &&
      target != null &&
      (target.startsWith('lib/features/') || target.startsWith('lib/app/'))) {
    return 'R1: core must not depend on features/app';
  }

  // R5
  if (usesSupabase &&
      !isComposition &&
      source?.layer != 'data' &&
      from != 'lib/core/errors/app_failure.dart' &&
      !from.startsWith('lib/core/network/')) {
    return 'R5: Supabase is only allowed in data layers, core/errors and main.dart';
  }
  if (target != null &&
      (target.endsWith('_supabase.dart') || target.endsWith('_adapters.dart')) &&
      !isComposition &&
      source?.module != _feature(target)?.module) {
    return 'R5: adapter barrels are imported only by lib/main.dart';
  }

  // R6
  if (uri.startsWith('package:firebase_') &&
      !isComposition &&
      from != 'lib/core/platform/firebase_push.dart' &&
      from != 'lib/firebase_options.dart') {
    return 'R6: Firebase is only allowed in core/platform/firebase_push.dart and main.dart';
  }

  if (source == null) return null;

  // R3
  if (source.layer == 'domain') {
    if (uri.startsWith('package:flutter/') || uri.startsWith('package:flutter_riverpod') || usesSupabase) {
      return 'R3: domain must be pure Dart';
    }
    final t = target == null ? null : _feature(target);
    if (t != null && t.module == source.module && t.layer != 'domain') return 'R3: domain must not import ${t.layer}';
  }

  // R4
  if (source.layer == 'presentation' || source.layer == 'application') {
    final t = target == null ? null : _feature(target);
    if (t != null && t.module == source.module && t.layer == 'data') return 'R4: ${source.layer} must not import data';
  }

  // R2
  if (target != null) {
    final t = _feature(target);
    if (t != null && t.module != source.module) {
      final barrel = 'lib/features/${t.module}/${t.module}.dart';
      if (target != barrel) return 'R2: use the public API $barrel';
    }
  }
  return null;
}
