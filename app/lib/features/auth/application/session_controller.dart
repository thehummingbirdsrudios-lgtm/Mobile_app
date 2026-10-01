import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../domain/auth_repository.dart';
import '../domain/user_session.dart';

/// Overridden at the composition root (main.dart) and in tests.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('authRepositoryProvider must be overridden'),
);

/// Tenant-scoped in-memory cache, bound/cleared by the session controller.
final tenantCacheProvider = Provider<TenantCache>((ref) => TenantCache());

sealed class SessionState {
  const SessionState();
}

/// Startup: identity not resolved yet. The UI shows a neutral splash and
/// MUST NOT render any cached business data in this state.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.reason});

  /// Why the user was signed out, if it was not their own choice.
  final AppFailure? reason;
}

final class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.session);

  final UserSession session;
}

final sessionControllerProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Convenience: the signed-in session or null.
final currentSessionProvider = Provider<UserSession?>((ref) {
  final state = ref.watch(sessionControllerProvider);
  return state is SessionSignedIn ? state.session : null;
});

class SessionController extends Notifier<SessionState> {
  StreamSubscription<void>? _endedSub;

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TenantCache get _cache => ref.read(tenantCacheProvider);

  @override
  SessionState build() {
    _endedSub = _repo.sessionEnded.listen((_) {
      if (state is SessionSignedIn) _becomeSignedOut(const AppFailure(FailureKind.sessionExpired));
    });
    ref.onDispose(() => _endedSub?.cancel());
    // Resolve identity after the first frame; state is SessionUnknown until then.
    unawaited(Future.microtask(_restore));
    return const SessionUnknown();
  }

  Future<void> _restore() async {
    try {
      final session = await _repo.restore();
      session == null ? _becomeSignedOut(null) : _becomeSignedIn(session);
    } on AppFailure catch (failure) {
      // Offline at launch with a stored session: we cannot verify membership,
      // so we do not show business data. The user can retry from login.
      _becomeSignedOut(failure);
    }
  }

  /// Throws [AppFailure] on failure so the login form can show it inline.
  Future<void> signIn({required String username, required String password}) async {
    final session = await _repo.signIn(username: Username.normalize(username), password: password);
    _becomeSignedIn(session);
  }

  Future<void> signOut() async {
    _becomeSignedOut(null);
    await _repo.signOut();
  }

  void _becomeSignedIn(UserSession session) {
    _cache.bind(tenantId: session.tenantId, userId: session.userId);
    state = SessionSignedIn(session);
  }

  void _becomeSignedOut(AppFailure? reason) {
    // Clear BEFORE publishing the new state so no widget can read stale data.
    _cache.clear();
    state = SessionSignedOut(reason: reason);
  }
}
