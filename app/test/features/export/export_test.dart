import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/export/data/remote/export_api.dart';
import 'package:vepari/features/export/domain/csv.dart';
import 'package:vepari/features/export/domain/export.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _go(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

String _csv(List<String> header, List<List<Object?>> rows, {Map<String, String> labels = const {}}) =>
    Csv.encode((header: header, rows: rows, yes: 'Yes', no: 'No', labels: labels));

class _Transport implements RpcTransport {
  _Transport(this.respond);

  final Object? Function(String fn, Map<String, Object?>? params) respond;
  final calls = <(String, Map<String, Object?>?)>[];

  @override
  Future<Object?> rpc(String function, Map<String, Object?>? params) async {
    calls.add((function, params));
    return respond(function, params);
  }
}

void main() {
  group('CSV', () {
    test('BOM, CRLF, quoting only where needed', () {
      final out = _csv(
        ['Name', 'City'],
        [
          ['Rajeshbhai', 'Rajkot'],
          ['Shah, Surat', 'He said "ok"'],
          ['Line\nbreak', ' padded '],
        ],
      );
      expect(out.startsWith('﻿'), isTrue);
      expect(
        out.substring(1),
        'Name,City\r\n'
        'Rajeshbhai,Rajkot\r\n'
        '"Shah, Surat","He said ""ok"""\r\n'
        '"Line\nbreak"," padded "\r\n',
      );
    });

    test('formula-looking text is defused; numbers are not', () {
      final out = _csv(
        ['A', 'B', 'C', 'D', 'E'],
        [
          ['=HYPERLINK("x")', '+91 98250', '-cmd', '@SUM(A1)', const Money.paise(-50000)],
        ],
      );
      expect(out.split('\r\n')[1], '"\'=HYPERLINK(""x"")",\'+91 98250,\'-cmd,\'@SUM(A1),-500.00');
    });

    test('money, grams, dates, booleans, codes and empty cells', () {
      final when = DateTime(2026, 10, 2, 9, 5); // local time
      final out = _csv(
        ['m', 'g', 'd', 'b', 'c', 'n', 'i'],
        [
          [const Money.paise(1234550), const Grams(42500), when, true, const CodeCell('ready'), null, 1045],
          [const Money.paise(5), const Grams(7), when, false, const CodeCell('unknown_code'), null, 0],
        ],
        labels: {'ready': 'તૈયાર'},
      );
      final lines = out.split('\r\n');
      expect(lines[1], '12345.50,42.500,2026-10-02 09:05,Yes,તૈયાર,,1045');
      expect(lines[2], '0.05,0.007,2026-10-02 09:05,No,unknown_code,,0');
    });

    test('Gujarati and Hindi survive the UTF-8 round trip', () {
      final out = _csv(
        ['નામ', 'नाम'],
        [
          ['કુંદન સેટ', 'झुमका'],
        ],
      );
      final bytes = utf8.encode(out);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes.sublist(3)), out.substring(1));
    });
  });

  group('periods', () {
    test('month and year boundaries in local time', () {
      final now = DateTime(2026, 1, 15, 12);
      expect(ExportPeriod.thisMonth.rangeAt(now), (from: DateTime(2026), to: DateTime(2026, 2)));
      expect(ExportPeriod.lastMonth.rangeAt(now), (from: DateTime(2025, 12), to: DateTime(2026)));
      expect(ExportPeriod.last3Months.rangeAt(now), (from: DateTime(2025, 11), to: DateTime(2026, 2)));
      expect(ExportPeriod.thisYear.rangeAt(now), (from: DateTime(2026), to: DateTime(2027)));
    });
  });

  group('ExportApi', () {
    ApiClient client(_Transport t) => ApiClient(
      transport: t,
      logger: AppLogger(minLevel: LogLevel.error, sinks: const []),
    );

    test('id-keyset kinds continue from the last id until a short page', () async {
      final t = _Transport(
        (fn, p) => [
          for (var i = 0; i < (p!['p_after'] == null ? 500 : 3); i++)
            {'id': 'c$i', 'name': 'C$i', 'balance_paise': 100, 'archived': false, 'created_at': '2026-10-01T00:00:00Z'},
        ],
      );
      final api = ExportApi(client(t));
      final first = await api.page(ExportKind.customers);
      expect(first.rows, hasLength(500));
      expect(first.next, 'c499');
      final second = await api.page(ExportKind.customers, after: first.next);
      expect(second.next, isNull);
      expect(t.calls.last.$1, 'export_customers');
      expect(t.calls.last.$2, {'p_after': 'c499', 'p_limit': 500});
      expect(first.rows.first, ['C0', null, null, null, null, const Money.paise(100), false, DateTime.utc(2026, 10)]);
    });

    test('dated kinds send the range in UTC and page by (time, id)', () async {
      final t = _Transport((fn, p) => const []);
      final range = (from: DateTime.utc(2026, 9), to: DateTime.utc(2026, 10));
      final page = await ExportApi(client(t)).page(ExportKind.ledger, range: range);
      expect(page.next, isNull);
      expect(t.calls.single.$1, 'export_ledger');
      expect(t.calls.single.$2, {
        'p_from': '2026-09-01T00:00:00.000Z',
        'p_to': '2026-10-01T00:00:00.000Z',
        'p_after_at': null,
        'p_after_id': null,
        'p_limit': 500,
      });
    });

    test('order lines page by order, never splitting one', () async {
      final t = _Transport(
        (fn, p) => [
          for (var o = 0; o < 200; o++)
            for (var l = 1; l <= 2; l++)
              {
                'order_id': 'o$o',
                'order_created_at': '2026-09-0${1 + o % 9}T10:00:00Z',
                'order_no': 1000 + o,
                'customer_name': 'C',
                'line_no': l,
                'design_no': 'D$l',
                'product_name': 'P',
                'qty': 1,
                'rate_paise': 100,
                'amount_paise': 100,
                'weight_mg': null,
              },
        ],
      );
      final page = await ExportApi(client(t))
          .page(ExportKind.orderLines, range: (from: DateTime.utc(2026, 9), to: DateTime.utc(2026, 10)));
      expect(page.rows, hasLength(400));
      expect(page.next, isNotNull, reason: '200 orders = a full page of orders');
      expect(t.calls.single.$2!['p_limit'], 200);
    });
  });

  group('screen', () {
    testWidgets('owner exports customers as a CSV through the share sheet', (tester) async {
      final sharer = FakeFileSharer();
      final exports = FakeExportRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        sharer: sharer,
        exports: exports,
      );
      await _go(tester, AppRoutes.export);
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();

      expect(exports.calls.map((c) => c.$3), [null, 2], reason: 'two pages of 2');
      final file = sharer.shared.single.$1.single;
      expect(file.mimeType, 'text/csv');
      expect(file.name, matches(RegExp(r'^vepari-customers-\d{8}\.csv$')));
      expect(file.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final lines = utf8.decode(file.bytes.sublist(3)).split('\r\n');
      expect(lines[0], 'Customer,Shop,City,Mobile,WhatsApp,Baki (₹),Archived,Added on');
      expect(lines[1], startsWith('Rajeshbhai,Shree Kundan,Rajkot,9825012345,,4820.00,No,'));
      expect(lines[2], startsWith('"\'=HYPERLINK(""evil"")",,,,,-500.00,Yes,'));
      expect(lines[3], startsWith('"Sureshbhai, Surat",,Surat,,,0.00,No,'));
      expect(find.text('3 rows exported'), findsOneWidget);
    });

    testWidgets('designs warn about cost; dated kinds ask for a period', (tester) async {
      final exports = FakeExportRepository(rows: const {});
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        exports: exports,
      );
      await _go(tester, AppRoutes.export);
      expect(find.text('This month'), findsNothing);

      await tester.tap(find.text('Designs with cost'));
      await tester.pumpAndSettle();
      expect(find.textContaining('cost prices and suppliers'), findsOneWidget);

      await tester.tap(find.text('Hisaab entries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      final (kind, range, _) = exports.calls.single;
      expect(kind, ExportKind.ledger);
      expect(range, ExportPeriod.lastMonth.rangeAt(DateTime.now()));
      expect(find.text('Nothing to export for this period'), findsOneWidget);
    });

    testWidgets('failures are explained; nothing is shared', (tester) async {
      final sharer = FakeFileSharer();
      final exports = FakeExportRepository()..error = const AppFailure(FailureKind.network);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        sharer: sharer,
        exports: exports,
      );
      await _go(tester, AppRoutes.export);
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(sharer.shared, isEmpty);

      exports.error = null;
      sharer.available = false;
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();
      expect(find.text("Sharing isn't available on this device."), findsOneWidget);
    });

    testWidgets('staff cannot open export', (tester) async {
      final exports = FakeExportRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: staffSession),
        exports: exports,
      );
      await _go(tester, AppRoutes.export);
      expect(find.text('Only the owner can open this.'), findsOneWidget);
      expect(exports.calls, isEmpty);
    });
  });
}
