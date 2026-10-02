import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/app/router.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/admin/admin.dart';
import 'package:vepari/features/auth/auth.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _go(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push<void>(location));
  await tester.pumpAndSettle();
}

/// Scrolls the screen's list until [finder] is built and on screen
/// ([up] for things above the current position, e.g. field errors).
Future<void> _reveal(WidgetTester tester, Finder finder, {bool up = false}) async {
  // hitTestable: the list of the TOP route, not one covered by it.
  await tester.scrollUntilVisible(finder, up ? -200 : 200, scrollable: find.byType(Scrollable).hitTestable().first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // A focused field keeps scrolling its caret back into view; a user would
  // have closed the keyboard before reaching a button further down.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Uint8List _jpeg() {
  final image = img.Image(width: 300, height: 200);
  img.fill(image, color: img.ColorRgb8(120, 30, 40));
  return img.encodeJpg(image);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  group('More', () {
    testWidgets('owner sees business settings; staff do not', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.more);
      expect(find.text('Business settings'), findsOneWidget);
      expect(find.text('Business details'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Activity log'), findsOneWidget);
    });

    testWidgets('staff More has no owner section', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: staffSession));
      await _go(tester, AppRoutes.more);
      expect(find.text('Business settings'), findsNothing);
      expect(find.text('Activity log'), findsNothing);
    });

    testWidgets('a staff deep link to owner screens is refused without a request', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: staffSession),
        admin: admin,
      );
      for (final route in [AppRoutes.staff, AppRoutes.businessProfile, AppRoutes.audit, AppRoutes.newStaff]) {
        await _go(tester, route);
        expect(find.text('Only the owner can open this.'), findsOneWidget, reason: route);
      }
      expect(admin.memberCalls + admin.profileCalls + admin.auditCalls.length, 0);
    });
  });

  group('business details', () {
    testWidgets('loads, validates on the field and saves normalised values', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.businessProfile);
      expect(find.text('Shree Jewels'), findsOneWidget);

      await tester.enterText(_field('Business name'), 'Shree Jewels Rajkot');
      await _reveal(tester, _field('GSTIN (optional)'));
      await tester.enterText(_field('GSTIN (optional)'), '24ABC');
      await _tap(tester, find.text('Save'));
      await _reveal(tester, find.text('GSTIN has 15 letters and numbers'), up: true);
      expect(admin.saved, isEmpty);

      await tester.enterText(_field('GSTIN (optional)'), '24abcde1234f1z5');
      await _tap(tester, find.text('Save'));
      expect(admin.saved, hasLength(1));
      final (draft, tenantId) = admin.saved.single;
      expect(tenantId, 't-a');
      expect(draft.businessName, 'Shree Jewels Rajkot');
      expect(BusinessProfileDraft.normaliseGstin(draft.gstin), '24ABCDE1234F1Z5');
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('a new logo is processed, uploaded and shown', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
        photos: FakePhotoPicker(_jpeg()),
      );
      await _go(tester, AppRoutes.businessProfile);
      await _tap(tester, find.text('Add logo'));
      expect(admin.logos, hasLength(1));
      final (jpeg, tenantId, sha) = admin.logos.single;
      expect(tenantId, 't-a');
      expect(sha, hasLength(64));
      expect(img.decodeJpg(jpeg), isNotNull);
      expect(find.text('Logo updated'), findsOneWidget);
      expect(find.text('Change logo'), findsOneWidget);
      expect(find.byKey(ValueKey('img:branding/${admin.profileValue.logoPath}')), findsOneWidget);
    });

    testWidgets('a file that is not a photo is refused with a clear message', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
        photos: FakePhotoPicker(Uint8List.fromList(List.filled(64, 3))),
      );
      await _go(tester, AppRoutes.businessProfile);
      await _tap(tester, find.text('Add logo'));
      expect(admin.logos, isEmpty);
      expect(find.text('This file is not a usable photo.'), findsOneWidget);
    });

    testWidgets('a save failure is shown and nothing claims success', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.businessProfile);
      admin.error = const AppFailure(FailureKind.network);
      await tester.enterText(_field('Business name'), 'New name');
      await _tap(tester, find.text('Save'));
      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
    });
  });

  group('staff', () {
    testWidgets('lists the owner and staff with their status', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.staff);
      expect(find.text('Rajeshbhai'), findsOneWidget);
      expect(find.text('Kiranbhai'), findsOneWidget);
      expect(find.text('@kiran · 2 permissions'), findsOneWidget);
      expect(find.text('@meena · No extra permissions'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('permissions are changed only when saved', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.staff);
      await tester.tap(find.text('Kiranbhai'));
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Record payments'));
      await _tap(tester, find.text('See Hisaab and Baki'));
      expect(admin.permissionCalls, isEmpty);
      await _tap(tester, find.text('Save permissions'));
      final (userId, permissions) = admin.permissionCalls.single;
      expect(userId, staffKiranId);
      expect(permissions, {Permission.ordersCreate, Permission.paymentsRecord});
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('stopping access asks first and is reversible', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.staffMember(staffKiranId));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text("Stop Kiranbhai's access?"), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(admin.activeCalls, isEmpty);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Stop access'));
      await tester.pumpAndSettle();
      expect(admin.activeCalls, [(staffKiranId, false)]);
      expect(find.text('Access stopped'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(admin.activeCalls.last, (staffKiranId, true));
    });

    testWidgets('a new password is checked, then set on the server', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.staffMember(staffKiranId));
      await _tap(tester, find.text('Set new password'));
      await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'short');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(admin.resets, isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'Haar-2026-new');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(admin.resets, [(staffKiranId, 'Haar-2026-new')]);
      expect(find.text('Password changed'), findsOneWidget);
    });

    testWidgets('the owner row cannot be edited, even by deep link', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, '${AppRoutes.staff}/u-owner'); // not a uuid → back to the list
      expect(find.text('Kiranbhai'), findsOneWidget);
    });

    testWidgets('an unknown member shows "not found"', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.staffMember('00000000-0000-4000-8000-0000000000ff'));
      expect(find.text('This record was not found.'), findsOneWidget);
    });
  });

  group('add staff', () {
    testWidgets('validates every field before any request', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.staff);
      await tester.tap(find.text('Add staff'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('Username'), 'Bad.Name!');
      await tester.enterText(_field('Password'), 'kiranbhai');
      await _tap(tester, find.text('Create login'));
      await _reveal(tester, find.text('Required'), up: true);
      expect(find.text('Use only a–z, 0–9, dot and underscore'), findsOneWidget);
      expect(admin.created, isEmpty);

      await tester.enterText(_field('Username'), 'kiranbhai');
      await _tap(tester, find.text('Create login'));
      await _reveal(tester, find.text('Must not be the same as the username'), up: true);
      expect(admin.created, isEmpty);
    });

    testWidgets('creates the login with the chosen permissions, then returns', (tester) async {
      final admin = FakeAdminRepository();
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.staff);
      await _push(tester, AppRoutes.newStaff);

      await tester.enterText(_field('Full name'), '  Sureshbhai ');
      await tester.enterText(_field('Username'), 'suresh');
      await tester.enterText(_field('Password'), 'Moti-Haar-2026');
      await _tap(tester, find.text('Take orders'));
      await _tap(tester, find.text('Make bills'));
      await _tap(tester, find.text('Create login'));

      final staff = admin.created.single;
      expect(staff.username, 'suresh');
      expect(staff.displayName.trim(), 'Sureshbhai');
      expect(staff.password, 'Moti-Haar-2026');
      expect(staff.permissions, {Permission.ordersCreate, Permission.billsIssue});
      expect(find.text('Sureshbhai can log in now'), findsOneWidget);
      // Back on the list, which now includes the new login.
      expect(find.text('Add staff'), findsOneWidget);
      expect(find.text('Sureshbhai'), findsOneWidget);
    });

    testWidgets('a taken username is shown on the field', (tester) async {
      final admin = FakeAdminRepository()
        ..createError = const AppFailure(FailureKind.alreadyExists, code: 'username_taken');
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.newStaff);
      await tester.enterText(_field('Full name'), 'Kiran Two');
      await tester.enterText(_field('Username'), 'kiran');
      await tester.enterText(_field('Password'), 'Moti-Haar-2026');
      await _tap(tester, find.text('Create login'));
      await _reveal(tester, find.text('This username is taken. Try another.'), up: true);
      expect(find.text('New staff login'), findsOneWidget);
    });
  });

  group('activity log', () {
    final rows = [
      AuditEntry(
        id: 120,
        action: 'update',
        entity: 'products',
        data: const {
          'rate_paise': {'from': 60000, 'to': 62000},
        },
        actorName: 'Rajeshbhai',
        subject: '1024 · Kundan Set',
        createdAt: DateTime.utc(2026, 10, 1, 10),
      ),
      AuditEntry(
        id: 119,
        action: 'delete',
        entity: 'member_permissions',
        data: const {
          'permission': {'from': 'orders.create', 'to': null},
        },
        actorName: 'Rajeshbhai',
        subject: 'Kiranbhai',
        createdAt: DateTime.utc(2026, 10, 1, 9),
      ),
      AuditEntry(
        id: 118,
        action: 'order.created',
        entity: 'orders',
        subject: '#1045',
        createdAt: DateTime.utc(2026, 10, 1, 8),
      ),
    ];

    testWidgets('says what changed, about what, by whom', (tester) async {
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: FakeAdminRepository(audit: rows),
      );
      await _go(tester, AppRoutes.audit);
      expect(find.text('Rate changed ₹600 → ₹620'), findsOneWidget);
      expect(find.textContaining('1024 · Kundan Set'), findsOneWidget);
      expect(find.text('Permission taken back: Take orders'), findsOneWidget);
      expect(find.text('Order taken'), findsOneWidget);
      expect(find.textContaining('System ·'), findsOneWidget);
    });

    testWidgets('pages older entries by id', (tester) async {
      final many = [
        for (var i = 200; i > 120; i--)
          AuditEntry(id: i, action: 'bill.issued', entity: 'bills', createdAt: DateTime.utc(2026, 10, 1)),
      ];
      final admin = FakeAdminRepository(audit: many);
      await pumpVepari(
        tester,
        auth: FakeAuthRepository(restored: ownerSession),
        admin: admin,
      );
      await _go(tester, AppRoutes.audit);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pumpAndSettle();
      expect(admin.auditCalls, [null, 151]);
    });

    testWidgets('empty log says so', (tester) async {
      await pumpVepari(tester, auth: FakeAuthRepository(restored: ownerSession));
      await _go(tester, AppRoutes.audit);
      expect(find.text('No activity yet'), findsOneWidget);
    });
  });
}
