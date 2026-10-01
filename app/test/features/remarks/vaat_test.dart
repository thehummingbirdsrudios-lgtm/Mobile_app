import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:vepari/app/router.dart';
import 'package:vepari/features/remarks/remarks.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

Future<void> _openCustomerVaat(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(AppRoutes.customerDetail(customerPatelId));
  await tester.pumpAndSettle();
  await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
  await tester.pumpAndSettle();
}

void main() {
  const target = RemarkTarget.customer(customerPatelId);

  testWidgets('type a note and send it', (tester) async {
    final remarks = FakeRemarksRepository();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      remarks: remarks,
    );
    await _openCustomerVaat(tester);
    expect(find.text('No Vaat yet. Add a note, voice or photo.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Write a note…'), 'Wants 2 dozen before Diwali');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Wants 2 dozen before Diwali'), findsOneWidget);
    expect(find.textContaining('You ·'), findsOneWidget);
  });

  testWidgets('record a voice note: timer, then send; too short is refused', (tester) async {
    final remarks = FakeRemarksRepository();
    final recorder = FakeVoiceRecorder();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      remarks: remarks,
      recorder: recorder,
    );
    await _openCustomerVaat(tester);
    await tester.tap(find.byTooltip('Record voice'));
    await tester.pump();
    expect(recorder.recording, isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Recording 00:03'), findsOneWidget);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(remarks.uploads.single.$1, 'voice');
    expect(remarks.uploads.single.$2, 't-a');
    expect(find.text('00:04'), findsOneWidget); // duration of the note

    recorder.next = const Duration(milliseconds: 200);
    await tester.tap(find.byTooltip('Record voice'));
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Too short. Speak a little longer.'), findsOneWidget);
    expect(remarks.uploads, hasLength(1));
  });

  testWidgets('cancel recording discards it; denied mic is explained', (tester) async {
    final recorder = FakeVoiceRecorder();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      recorder: recorder,
    );
    await _openCustomerVaat(tester);
    await tester.tap(find.byTooltip('Record voice'));
    await tester.pump();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(recorder.cancels, 1);

    recorder.permission = false;
    await tester.tap(find.byTooltip('Record voice'));
    await tester.pumpAndSettle();
    expect(find.text('Allow the microphone to record voice notes.'), findsOneWidget);
  });

  testWidgets('photo note is stored as the share-size JPEG', (tester) async {
    final remarks = FakeRemarksRepository();
    final photo = img.encodeJpg(img.Image(width: 2000, height: 1500));
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      remarks: remarks,
      photos: FakePhotoPicker(photo),
    );
    await _openCustomerVaat(tester);
    await tester.tap(find.byTooltip('Add photo'));
    await tester.pumpAndSettle();
    final (kind, tenant, bytes, _) = remarks.uploads.single;
    expect(kind, 'photo');
    expect(tenant, 't-a');
    expect(bytes, lessThan(photo.length));
  });

  testWidgets('voice note plays from a signed URL', (tester) async {
    final remarks = FakeRemarksRepository();
    await remarks.addVoice(
      target,
      tenantId: 't-a',
      audio: img.encodePng(img.Image(width: 1, height: 1)),
      mimeType: 'audio/mp4',
      duration: const Duration(seconds: 7),
    );
    final player = FakeVoicePlayer();
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      remarks: remarks,
      player: player,
    );
    await _openCustomerVaat(tester);
    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();
    expect(player.played.single, 'https://storage.invalid/remarks/t-a/remarks/v.m4a');
  });

  testWidgets('only the author or the owner can remove a note', (tester) async {
    final remarks = FakeRemarksRepository();
    await remarks.addText(target, 'Owner note');
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: staffSession),
      remarks: remarks,
    );
    await _openCustomerVaat(tester);
    expect(find.text('Owner note'), findsOneWidget);
    expect(find.byTooltip('Remove note'), findsNothing);
  });

  testWidgets('owner removes a note', (tester) async {
    final remarks = FakeRemarksRepository();
    await remarks.addText(target, 'Old note');
    await pumpVepari(
      tester,
      auth: FakeAuthRepository(restored: ownerSession),
      remarks: remarks,
    );
    await _openCustomerVaat(tester);
    await tester.tap(find.byTooltip('Remove note'));
    await tester.pumpAndSettle();
    expect(remarks.archived, hasLength(1));
    expect(find.text('Old note'), findsNothing);
  });
}
