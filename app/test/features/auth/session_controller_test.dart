import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  ProviderContainer make() {
    final c = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(auth)]);
    addTearDown(c.dispose);
    return c;
  }

  Future<SessionState> settle() async {
    container.read(sessionControllerProvider);
    await Future<void>.delayed(Duration.zero);
    return container.read(sessionControllerProvider);
  }

  setUp(() => auth = FakeAuthRepository());
  tearDown(() => auth.dispose());

  test('starts Unknown, never signed in before identity is verified', () {
    container = make();
    expect(container.read(sessionControllerProvider), isA<SessionUnknown>());
    expect(container.read(currentSessionProvider), isNull);
  });

  test('restores a persisted session and binds the tenant cache', () async {
    auth.restored = ownerSession;
    container = make();
    expect(await settle(), isA<SessionSignedIn>());
    expect(container.read(tenantCacheProvider).isBound, isTrue);
  });

  test('restore failure (offline) signs out with a reason instead of showing stale data', () async {
    auth.restoreError = const AppFailure(FailureKind.network);
    container = make();
    final state = await settle();
    expect(state, isA<SessionSignedOut>());
    expect((state as SessionSignedOut).reason?.kind, FailureKind.network);
  });

  test('sign-in normalises the username', () async {
    auth.signInResult = ownerSession;
    container = make();
    await settle();
    await container.read(sessionControllerProvider.notifier).signIn(username: '  Rajesh ', password: 'x');
    expect(auth.lastUsername, 'rajesh');
    expect(container.read(currentSessionProvider)?.tenantId, 't-a');
  });

  test('sign-out clears the tenant cache before publishing signed-out state', () async {
    auth.restored = ownerSession;
    container = make();
    await settle();
    container.read(tenantCacheProvider).write('product_1024', 'cached');
    var cacheBoundWhenSignedOut = true;
    container.listen(sessionControllerProvider, (_, next) {
      if (next is SessionSignedOut) cacheBoundWhenSignedOut = container.read(tenantCacheProvider).isBound;
    });
    await container.read(sessionControllerProvider.notifier).signOut();
    expect(cacheBoundWhenSignedOut, isFalse);
    expect(auth.signOutCalls, 1);
  });

  test('backend-ended session (expiry/revocation) signs out with sessionExpired', () async {
    auth.restored = ownerSession;
    container = make();
    await settle();
    auth.endSession();
    await Future<void>.delayed(Duration.zero);
    final state = container.read(sessionControllerProvider);
    expect(state, isA<SessionSignedOut>());
    expect((state as SessionSignedOut).reason?.kind, FailureKind.sessionExpired);
  });

  test('owner implicitly has every permission; staff only granted ones', () {
    expect(Permission.values.every(ownerSession.can), isTrue);
    expect(staffSession.can(Permission.ordersCreate), isTrue);
    expect(staffSession.can(Permission.hisaabView), isFalse);
  });
}
