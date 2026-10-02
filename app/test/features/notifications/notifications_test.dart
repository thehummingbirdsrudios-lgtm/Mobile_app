import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/notifications/notifications.dart';
import 'package:vepari/features/notifications/presentation/notification_text.dart';
import 'package:vepari/l10n/app_localizations_en.dart';
import 'package:vepari/l10n/app_localizations_gu.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _go(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await tester.pumpAndSettle();
}

Finder _badge(String label) => find.descendant(of: find.byType(Badge), matching: find.text(label));

void main() {
  group('bell and inbox', () {
    testWidgets('Home shows the unread count; the inbox says what happened', (tester) async {
      final notifications = FakeNotificationsRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        notifications: notifications,
      );
      expect(_badge('3'), findsOneWidget);
      await tester.tap(find.byTooltip('3 unread notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('New Maal: 1024 · Kundan Set'), findsOneWidget);
      expect(find.text('New order #1045 · Rajeshbhai'), findsOneWidget);
      expect(find.text('Order #1045: Ready'), findsOneWidget);
      expect(find.text('Payment ₹2,500 from Sureshbhai'), findsOneWidget);
    });

    testWidgets('opening an entry marks it read and goes to its subject', (tester) async {
      final notifications = FakeNotificationsRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: staffSession),
        notifications: notifications,
      );
      await _go(tester, AppRoutes.notifications);
      await tester.tap(find.text('New Maal: 1024 · Kundan Set'));
      await tester.pumpAndSettle();
      expect(notifications.markedIds, ['n4']);
      expect(find.text('Weight: 42 g'), findsOneWidget); // the design's detail screen
    });

    testWidgets('mark all read clears the badge', (tester) async {
      final notifications = FakeNotificationsRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        notifications: notifications,
      );
      await _go(tester, AppRoutes.notifications);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(notifications.markAllCalls, 1);
      expect(find.text('Mark all read'), findsNothing);
      await _go(tester, AppRoutes.home);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(_badge('3'), findsNothing);
    });

    testWidgets('an empty inbox says so', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.notifications);
      expect(find.text("You're all caught up"), findsOneWidget);
    });

    testWidgets('a failing count hides the badge; the inbox shows the error', (tester) async {
      final notifications = FakeNotificationsRepository()..error = const AppFailure(FailureKind.network);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        notifications: notifications,
      );
      expect(find.byTooltip('Notifications'), findsOneWidget);
      await _go(tester, AppRoutes.notifications);
      expect(find.text('Check your internet connection.'), findsOneWidget);
    });
  });

  group('push registration', () {
    testWidgets('the device is registered for the signed-in member', (tester) async {
      final notifications = FakeNotificationsRepository(items: const []);
      final tokens = FakePushTokens('fcm-token-for-this-phone-0001');
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        notifications: notifications,
        pushTokens: tokens,
        locale: const Locale('gu'),
      );
      expect(notifications.registered, [('fcm-token-for-this-phone-0001', 'android', 'gu')]);

      tokens.refreshes.add('fcm-token-rotated-by-firebase-02');
      await tester.pumpAndSettle();
      expect(notifications.registered.last.$1, 'fcm-token-rotated-by-firebase-02');
    });

    testWidgets('sign-out unregisters the device before signing out', (tester) async {
      final journal = <String>[];
      final notifications = FakeNotificationsRepository(items: const [], journal: journal);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession, journal: journal),
        notifications: notifications,
        pushTokens: FakePushTokens('fcm-token-for-this-phone-0001'),
      );
      await _go(tester, AppRoutes.more);
      await tester.ensureVisible(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(journal, ['unregister', 'signOut']);
      expect(notifications.unregistered, ['fcm-token-for-this-phone-0001']);
    });

    testWidgets('a failed registration leaves the app working', (tester) async {
      final notifications = FakeNotificationsRepository(items: const [])
        ..registerError = const AppFailure(FailureKind.network);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        notifications: notifications,
        pushTokens: FakePushTokens('fcm-token-for-this-phone-0001'),
      );
      expect(notifications.registered, isEmpty);
      expect(find.text('Namaskar Rajeshbhai 👋'), findsOneWidget);
    });

    testWidgets('a build without push never registers anything', (tester) async {
      final quiet = FakeNotificationsRepository(items: const []);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        notifications: quiet,
      );
      expect(quiet.registered, isEmpty);
    });
  });

  test('inbox text in Gujarati, and a safe fallback for unknown kinds', () {
    final gu = AppLocalizationsGu();
    final items = sampleNotifications();
    expect(notificationText(gu, items[0]), 'નવો માલ: 1024 · Kundan Set');
    expect(notificationText(gu, items[2]), 'ઓર્ડર #1045: તૈયાર');
    expect(
      notificationText(
        AppLocalizationsEn(),
        AppNotification(id: 'x', kind: 'future_kind', createdAt: DateTime.utc(2026)),
      ),
      'Update',
    );
  });
}
