// Push handling on the phone: what a tap opens, what a push in the
// foreground does, and that nothing survives sign-out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/notifications/notifications.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

const _token = 'fcm-token-for-this-phone-0001';
const _kundanPush = PushMessage(
  notificationId: 'n4',
  kind: 'new_maal',
  targetKind: 'product',
  targetId: productKundanId,
  title: 'New Maal',
);

Finder _badge(String label) => find.descendant(of: find.byType(Badge), matching: find.text(label));

void main() {
  group('reading a push', () {
    const id = '6f1c2a9e-3b4d-4e5f-8a7b-9c0d1e2f3a4b';
    const product = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d';

    test('a Vepari push carries ids only', () {
      final m = PushMessage.fromData({
        'notification_id': id,
        'kind': 'new_maal',
        'target_kind': 'product',
        'target_id': product,
      }, title: 'નવો માલ')!;
      expect(
        (m.notificationId, m.kind, m.targetKind, m.targetId, m.title),
        (id, 'new_maal', 'product', product, 'નવો માલ'),
      );
    });

    test('anything else is ignored, and a malformed target is dropped', () {
      expect(PushMessage.fromData({'kind': 'new_maal'}), isNull);
      expect(PushMessage.fromData({'notification_id': 'not-a-uuid', 'kind': 'new_maal'}), isNull);
      expect(PushMessage.fromData({'notification_id': id}), isNull);
      final m = PushMessage.fromData({
        'notification_id': id,
        'kind': 'new_maal',
        'target_kind': 'product',
        'target_id': '../../etc',
      })!;
      expect((m.targetKind, m.targetId), (null, null));
    });
  });

  group('tapping a push', () {
    testWidgets('opens its subject and marks it read', (tester) async {
      final notifications = FakeNotificationsRepository();
      final tokens = FakePushTokens(_token);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: staffSession),
        notifications: notifications,
        pushTokens: tokens,
      );
      tokens.opened.add(_kundanPush);
      await tester.pumpAndSettle();
      expect(find.text('Weight: 42 g'), findsOneWidget); // the design's detail screen
      expect(notifications.markedIds, ['n4']);
    });

    testWidgets('a push with nothing to open shows the inbox', (tester) async {
      final tokens = FakePushTokens(_token);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        notifications: FakeNotificationsRepository(),
        pushTokens: tokens,
      );
      tokens.opened.add(const PushMessage(notificationId: 'n9', kind: 'order_update'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Notifications'), findsOneWidget);
    });

    testWidgets('the push that started the app opens after sign-in, and Back returns Home', (tester) async {
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: staffSession),
        notifications: FakeNotificationsRepository(),
        pushTokens: FakePushTokens(_token, initial: _kundanPush),
      );
      await tester.pumpAndSettle();
      expect(find.text('Weight: 42 g'), findsOneWidget);

      final context = tester.element(find.byType(Scaffold).last);
      GoRouter.of(context).pop();
      await tester.pumpAndSettle();
      expect(find.byType(NotificationBell), findsOneWidget, reason: 'Home (the bell), not the splash screen');
    });
  });

  testWidgets('a push in the foreground refreshes the bell and offers Open', (tester) async {
    final notifications = FakeNotificationsRepository();
    final tokens = FakePushTokens(_token);
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      notifications: notifications,
      pushTokens: tokens,
    );
    expect(_badge('3'), findsOneWidget);

    notifications.items = [
      AppNotification(
        id: 'n5',
        kind: 'new_maal',
        targetKind: 'product',
        targetId: productKundanId,
        args: const {'design_no': '1024', 'name': 'Kundan Set'},
        createdAt: DateTime.utc(2026, 10, 2, 10),
      ),
      ...notifications.items,
    ];
    tokens.foreground.add(_kundanPush);
    await tester.pumpAndSettle();
    expect(_badge('4'), findsOneWidget);
    expect(find.text('New Maal'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Weight: 42 g'), findsOneWidget);
  });

  testWidgets('sign-out forgets the token; later pushes open nothing', (tester) async {
    final notifications = FakeNotificationsRepository(items: const []);
    final tokens = FakePushTokens(_token);
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      notifications: notifications,
      pushTokens: tokens,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(AppRoutes.more);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(notifications.unregistered, [_token]);
    expect(tokens.resets, 1);

    tokens.opened.add(_kundanPush);
    await tester.pumpAndSettle();
    expect(find.text('Weight: 42 g'), findsNothing);
    expect(notifications.markedIds, isEmpty);
  });
}
