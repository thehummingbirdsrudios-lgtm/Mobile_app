import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/csv.dart';
import '../domain/export.dart';

/// Overridden at the composition root and in tests.
final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => throw UnimplementedError('exportRepositoryProvider must be overridden'),
);

typedef CsvEncoder = Future<String> Function(CsvOptions options);

Future<String> _encodeInBackground(CsvOptions options) => compute(Csv.encode, options);

/// Seam for widget tests, which cannot await a real isolate under fake time.
final csvEncoderProvider = Provider<CsvEncoder>((ref) => _encodeInBackground);

/// Upper bound on one file: beyond this the owner picks a shorter period.
const maxExportRows = 200000;

final exportServiceProvider = Provider<ExportService>(ExportService.new);

class ExportService {
  ExportService(this._ref);

  final Ref _ref;

  /// Reads every page, then encodes off the UI isolate. Throws [AppFailure]
  /// (permissionDenied for non-owners, invalidInput when too large).
  Future<({ShareFile file, int rows})> build(
    ExportKind kind, {
    ExportRange? range,
    required List<String> header,
    required String yes,
    required String no,
    required Map<String, String> labels,
    ValueChanged<int>? onProgress,
  }) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null || !session.isOwner) throw const AppFailure(FailureKind.permissionDenied);
    if (kind.isDated && range == null) throw const AppFailure(FailureKind.invalidInput);

    final repo = _ref.read(exportRepositoryProvider);
    final rows = <List<Object?>>[];
    Object? cursor;
    do {
      final page = await repo.page(kind, range: range, after: cursor);
      rows.addAll(page.rows);
      if (rows.length > maxExportRows) throw const AppFailure(FailureKind.invalidInput, code: 'export_too_large');
      onProgress?.call(rows.length);
      cursor = page.next;
    } while (cursor != null);

    final csv = await _ref.read(csvEncoderProvider)((header: header, rows: rows, yes: yes, no: no, labels: labels));
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}';
    return (
      file: ShareFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        name: 'vepari-${kind.name}-$stamp.csv',
        mimeType: 'text/csv',
      ),
      rows: rows.length,
    );
  }
}
