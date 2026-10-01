import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/customers/customers.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _openTab(WidgetTester tester) async {
  await tester.tap(find.text('Customer').last);
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

void main() {
  group('list', () {
    testWidgets('owner sees customers A–Z with Baki', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _openTab(tester);
      expect(find.text('Patel Kundan Stores'), findsOneWidget);
      expect(find.text('Shah Imitation'), findsOneWidget);
      expect(find.text('Shah Fancy · Surat'), findsOneWidget);
      expect(find.text('₹48,200'), findsOneWidget);
      expect(find.text('Baki first'), findsOneWidget);
    });

    testWidgets('staff without Hisaab never see Baki or the Baki sort', (tester) async {
      final customers = FakeCustomerRepository()..hideBaki = true;
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: staffSession),
        customers: customers,
      );
      await _openTab(tester);
      expect(find.text('Patel Kundan Stores'), findsOneWidget);
      expect(find.text('₹48,200'), findsNothing);
      expect(find.text('Baki first'), findsNothing);
      expect(find.text('Add customer'), findsNothing);
    });

    testWidgets('search by name and Baki-first sort', (tester) async {
      final customers = FakeCustomerRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
      );
      await _openTab(tester);
      await tester.enterText(find.byType(TextField), 'shah');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Patel Kundan Stores'), findsNothing);
      expect(find.text('Shah Imitation'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('No customer matches “zzz”'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Baki first'));
      await tester.pumpAndSettle();
      expect(customers.queries.last.sort, CustomerSort.baki);
      final patel = tester.getTopLeft(find.text('Patel Kundan Stores')).dy;
      final shah = tester.getTopLeft(find.text('Shah Imitation')).dy;
      expect(patel, lessThan(shah)); // ₹48,200 before ₹1,250
    });

    testWidgets('load failure offers retry', (tester) async {
      final customers = FakeCustomerRepository()..pageError = const AppFailure(FailureKind.network);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
      );
      await _openTab(tester);
      expect(find.text('Check your internet connection.'), findsOneWidget);
      customers.pageError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Patel Kundan Stores'), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets('shows Baki, counts and contact actions', (tester) async {
      final contacts = FakeContactLauncher();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        contacts: contacts,
      );
      await _openTab(tester);
      await tester.tap(find.text('Patel Kundan Stores'));
      await tester.pumpAndSettle();
      expect(find.text('₹48,200'), findsOneWidget);
      expect(find.text('Open orders'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('1 design'), findsOneWidget);
      await tester.tap(find.text('Call'));
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(contacts.launched, ['tel:9825012345', 'wa:9825012345']);
    });

    testWidgets('WhatsApp missing on the phone is explained', (tester) async {
      final contacts = FakeContactLauncher()..available = false;
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        contacts: contacts,
      );
      await _go(tester, AppRoutes.customerDetail(customerPatelId));
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(find.text('WhatsApp could not be opened on this phone.'), findsOneWidget);
    });

    testWidgets('staff without Hisaab see no Baki and no payment action', (tester) async {
      final customers = FakeCustomerRepository()..hideBaki = true;
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: staffSession),
        customers: customers,
      );
      await _go(tester, AppRoutes.customerDetail(customerPatelId));
      expect(find.text('Baki'), findsNothing);
      expect(find.text('Payment'), findsNothing);
      expect(find.text('Order Karo'), findsOneWidget); // staff has orders.create
      expect(find.byTooltip('Edit'), findsNothing);
    });

    testWidgets('Regular Maal lists what the customer buys; + adds it', (tester) async {
      final added = <String>[];
      final customers = FakeCustomerRepository()
        ..regular[customerPatelId] = const [
          RegularMaalItem(
            productId: productKundanId,
            designNo: '1024',
            name: 'Kundan Set',
            timesOrdered: 5,
            lastQty: 12,
            rate: Money.paise(58000),
            isOrderable: true,
          ),
        ];
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
        crossModule: false,
        extraOverrides: [
          customerActionsProvider.overrideWithValue(
            CustomerActions(onAddRegular: (customerId, item) => added.add('$customerId:${item.designNo}')),
          ),
        ],
      );
      await _go(tester, AppRoutes.customerDetail(customerPatelId));
      expect(find.text('Regular Maal'), findsOneWidget);
      expect(find.text('5× · last 12 pcs'), findsOneWidget);
      expect(find.text('₹580'), findsOneWidget);
      await tester.tap(find.byTooltip('Add'));
      expect(added, ['$customerPatelId:1024']);
    });

    testWidgets('another business\'s id reads as not found', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.customerDetail('00000000-0000-4000-8000-0000000000ff'));
      expect(find.text('This record was not found.'), findsOneWidget);
    });
  });

  group('editor', () {
    testWidgets('creates a customer with opening Baki, then opens it', (tester) async {
      final customers = FakeCustomerRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
      );
      await _openTab(tester);
      await tester.tap(find.text('Add customer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Customer name'), 'Mehta Bangles');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mobile'), '+91 98989 12121');
      await tester.enterText(find.widgetWithText(TextFormField, 'Opening Baki'), '15,000');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(customers.created.single.name, 'Mehta Bangles');
      final (id, amount, requestId) = customers.openings.single;
      expect(amount, const Money.paise(1500000));
      expect(requestId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(find.text('Mehta Bangles'), findsWidgets); // detail screen
      expect(find.text('9898912121'), findsOneWidget);
      expect(id, isNotEmpty);
    });

    testWidgets('failed opening Baki keeps the customer and says so', (tester) async {
      final customers = FakeCustomerRepository()..openingError = const AppFailure(FailureKind.network);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
      );
      await _go(tester, AppRoutes.newCustomer);
      await tester.enterText(find.widgetWithText(TextFormField, 'Customer name'), 'Mehta Bangles');
      await tester.enterText(find.widgetWithText(TextFormField, 'Opening Baki'), '500');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(customers.created, hasLength(1));
      expect(find.text('Customer saved, but the opening Baki was not. Add it from Hisaab.'), findsOneWidget);
    });

    testWidgets('invalid mobile is caught before saving', (tester) async {
      final customers = FakeCustomerRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
      );
      await _go(tester, AppRoutes.newCustomer);
      await tester.enterText(find.widgetWithText(TextFormField, 'Customer name'), 'X');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mobile'), '12345');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a 10-digit mobile number'), findsOneWidget);
      expect(customers.created, isEmpty);
    });

    testWidgets('staff without hisaab.adjust get no opening Baki field', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
      await _go(tester, AppRoutes.newCustomer);
      expect(find.text('Opening Baki'), findsNothing);
    });

    testWidgets('editing saves changes and returns', (tester) async {
      final customers = FakeCustomerRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
      );
      await _go(tester, AppRoutes.customerDetail(customerShahId));
      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Opening Baki'), findsNothing); // only when creating
      await tester.enterText(find.widgetWithText(TextFormField, 'City'), 'Ahmedabad');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(customers.updates.single.$2.city, 'Ahmedabad');
      expect(find.text('Edit customer'), findsNothing); // back on detail
    });
  });

  group('special rates', () {
    testWidgets('owner adds a special rate by design number', (tester) async {
      final customers = FakeCustomerRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        customers: customers,
      );
      await _go(tester, AppRoutes.customerRates(customerPatelId));
      expect(find.text('No special rates. This customer pays the normal rate.'), findsOneWidget);
      await tester.tap(find.text('Add special rate'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Design no.'), '1024');
      await tester.enterText(find.widgetWithText(TextFormField, 'Rate (₹ per piece)'), '580');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('1024 · Kundan Set'), findsOneWidget);
      expect(find.text('₹580'), findsOneWidget);
      expect(find.text('Normal ₹620'), findsOneWidget);
    });

    testWidgets('unknown design number is reported', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.customerRates(customerPatelId));
      await tester.tap(find.text('Add special rate'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Design no.'), '9999');
      await tester.enterText(find.widgetWithText(TextFormField, 'Rate (₹ per piece)'), '100');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('No design with this number.'), findsOneWidget);
    });

    testWidgets('without rates.manage rates are read-only', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
      await _go(tester, AppRoutes.customerRates(customerPatelId));
      expect(find.text('Add special rate'), findsNothing);
    });
  });
}
