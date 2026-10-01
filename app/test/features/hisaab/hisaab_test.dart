import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/hisaab/data/remote/hisaab_api.dart';
import 'package:vepari/features/hisaab/hisaab.dart';
import 'package:vepari/features/hisaab/hisaab_adapters.dart';
import 'package:vepari/l10n/app_localizations_en.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

class _Transport implements RpcTransport {
  final calls = <(String, Map<String, Object?>?)>[];

  @override
  Future<Object?> rpc(String function, Map<String, Object?>? params) async {
    calls.add((function, params));
    return {'payment_id': 'p1', 'payment_no': 8, 'amount_paise': 100, 'balance_after_paise': 0, 'replayed': true};
  }
}

Future<void> _go(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

void main() {
  group('data', () {
    test('ledger rows decode kinds, modes and signed amounts', () {
      final e = ledgerEntryFromJson({
        'id': 'l1',
        'kind': 'payment',
        'amount_paise': -500000,
        'balance_after_paise': 4820000,
        'order_id': null,
        'order_no': null,
        'payment_id': 'p1',
        'payment_mode': 'upi',
        'note': null,
        'created_at': '2026-09-30T12:00:00+00:00',
      });
      expect(e.kind, LedgerKind.payment);
      expect(e.amount.isNegative, isTrue);
      expect(e.paymentMode, PaymentMode.upi);
    });

    test('payment and adjustment requests carry idempotency keys and trimmed text', () async {
      final transport = _Transport();
      final repo = HisaabRepositoryImpl(
        HisaabApi(
          ApiClient(
            transport: transport,
            logger: AppLogger(minLevel: LogLevel.error, sinks: const []),
          ),
        ),
      );
      final r = await repo.recordPayment(
        customerId: 'c1',
        amount: const Money.paise(100),
        mode: PaymentMode.cheque,
        requestId: 'req',
        reference: ' 000123 ',
        note: '  ',
      );
      expect(r.replayed, isTrue);
      expect(transport.calls.single.$2, {
        'p_customer_id': 'c1',
        'p_amount_paise': 100,
        'p_mode': 'cheque',
        'p_client_request_id': 'req',
        'p_reference': '000123',
        'p_note': null,
      });
      await repo.recordAdjustment(
        customerId: 'c1',
        amount: const Money.paise(-2500),
        requestId: 'req2',
        opening: false,
        note: 'Discount',
      );
      expect(transport.calls.last.$2!['p_kind'], 'adjustment');
      expect(transport.calls.last.$2!['p_amount_paise'], -2500);
    });

    test('negative balance reads as Advance', () {
      final l10n = AppLocalizationsEn();
      expect(bakiText(l10n, const Money.paise(-150000)), 'Advance ₹1,500');
      expect(bakiText(l10n, const Money.paise(150000)), '₹1,500');
    });
  });

  group('screens', () {
    testWidgets('Hisaab tab lists Baki highest first', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await tester.tap(find.text('Hisaab').last);
      await tester.pumpAndSettle();
      final patel = tester.getTopLeft(find.text('Patel Kundan Stores')).dy;
      final shah = tester.getTopLeft(find.text('Shah Imitation')).dy;
      expect(patel, lessThan(shah));
      await tester.tap(find.text('Patel Kundan Stores'));
      await tester.pumpAndSettle();
      expect(find.text('Order #1045'), findsOneWidget);
    });

    testWidgets('staff without Hisaab access see a clear message, no data', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
      await tester.tap(find.text('Hisaab').last);
      await tester.pumpAndSettle();
      expect(find.text("You don't have access to Hisaab. Ask the owner."), findsOneWidget);
      await _go(tester, AppRoutes.ledger(customerPatelId));
      expect(find.text("You don't have access to Hisaab. Ask the owner."), findsOneWidget);
      expect(find.text('Order #1045'), findsNothing);
    });

    testWidgets('ledger shows entries with running Baki and links', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.ledger(customerPatelId));
      expect(find.text('₹48,200'), findsOneWidget); // current Baki
      expect(find.text('Payment · UPI'), findsOneWidget);
      expect(find.text('− ₹5,000'), findsOneWidget);
      expect(find.text('+ ₹7,440'), findsOneWidget);
      expect(find.text('Baki ₹53,200'), findsOneWidget);
      expect(find.text('Opening Baki'), findsOneWidget);
      await tester.tap(find.text('Payment · UPI'));
      await tester.pumpAndSettle();
      expect(find.text('Receipt #7'), findsWidgets);
      expect(find.text('UPI-881'), findsOneWidget);
    });

    testWidgets('send Hisaab on WhatsApp with business name and Baki', (tester) async {
      final contacts = FakeContactLauncher();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        contacts: contacts,
      );
      await _go(tester, AppRoutes.ledger(customerPatelId));
      await tester.tap(find.byTooltip('Send Hisaab'));
      await tester.pumpAndSettle();
      expect(contacts.launched, ['wa:9825012345']);
    });

    testWidgets('payment: preview, save once, receipt, WhatsApp', (tester) async {
      final hisaab = FakeHisaabRepository();
      final contacts = FakeContactLauncher();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        hisaab: hisaab,
        contacts: contacts,
      );
      await _go(tester, AppRoutes.ledger(customerPatelId));
      await tester.tap(find.text('Payment'));
      await tester.pumpAndSettle();
      expect(find.text('Full Baki ₹48,200'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '10000');
      await tester.pump();
      expect(find.text('Baki after this: ₹38,200'), findsOneWidget);
      await tester.tap(find.text('UPI'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Reference (UPI / cheque no.)'), 'UTR123');
      await tester.ensureVisible(find.text('Save payment'));
      await tester.tap(find.text('Save payment'));
      await tester.pumpAndSettle();

      final call = hisaab.payments.single;
      expect(call.amount, const Money.paise(1000000));
      expect(call.mode, PaymentMode.upi);
      expect(call.reference, 'UTR123');
      expect(find.text('Receipt #8'), findsWidgets);
      expect(find.text('₹38,200'), findsOneWidget); // Baki now
      await tester.tap(find.text('Send on WhatsApp'));
      await tester.pumpAndSettle();
      expect(contacts.launched, ['wa:9825012345']);
    });

    testWidgets('a failed save retries with the same request id', (tester) async {
      final hisaab = FakeHisaabRepository()..paymentErrors.add(const AppFailure(FailureKind.network));
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        hisaab: hisaab,
      );
      await _go(tester, AppRoutes.payment(customerPatelId));
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500');
      await tester.tap(find.text('Save payment'));
      await tester.pumpAndSettle();
      expect(find.text('Check your internet connection.'), findsOneWidget);
      await tester.tap(find.text('Save payment'));
      await tester.pumpAndSettle();
      expect(hisaab.payments, hasLength(2));
      expect(hisaab.payments[0].requestId, hisaab.payments[1].requestId);
    });

    testWidgets('overpayment shows the advance, not a negative Baki', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.payment(customerShahId));
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '2000');
      await tester.pump();
      expect(find.text('Advance after this: ₹750'), findsOneWidget);
    });

    testWidgets('adjustment needs a note; reduce posts a negative amount', (tester) async {
      final hisaab = FakeHisaabRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        hisaab: hisaab,
      );
      await _go(tester, AppRoutes.ledger(customerPatelId));
      await tester.tap(find.text('Adjust'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reduce Baki'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '250');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
      expect(hisaab.adjustments, isEmpty);
      await tester.enterText(find.widgetWithText(TextFormField, 'Write why (shown in Hisaab)'), 'Rate discount');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final (_, amount, opening, note, _) = hisaab.adjustments.single;
      expect(amount, const Money.paise(-25000));
      expect(opening, isFalse);
      expect(note, 'Rate discount');
    });

    testWidgets('opening Baki is offered only on an empty Hisaab', (tester) async {
      final hisaab = FakeHisaabRepository()
        ..adjustmentError = const AppFailure(FailureKind.alreadyExists, code: 'opening_exists');
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        hisaab: hisaab,
      );
      await _go(tester, AppRoutes.ledger(customerPatelId));
      expect(find.text('Set opening Baki'), findsNothing);
      await _go(tester, AppRoutes.ledger(customerShahId));
      await tester.tap(find.text('Set opening Baki'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '1250');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Opening Baki is already set for this customer.'), findsOneWidget);
    });
  });
}
