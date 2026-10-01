import '../../../../core/errors/app_failure.dart';
import '../../domain/auth_repository.dart';
import '../../domain/user_session.dart';
import '../remote/auth_api.dart';

/// [AuthRepository] implementation: owns the sign-in/restore rules
/// (membership must be active, offline sign-out still succeeds locally) and
/// delegates transport to [AuthApi].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, {required this.loginDomain});

  final AuthApi _remote;
  final String loginDomain;

  @override
  Stream<void> get sessionEnded => _remote.sessionEnded;

  @override
  Future<UserSession?> restore() async {
    if (!_remote.hasPersistedSession) return null;
    final session = await _remote.fetchCurrentSession();
    if (session == null) await signOut();
    return session;
  }

  @override
  Future<UserSession> signIn({required String username, required String password}) async {
    await _remote.signInWithPassword(identifier: Username.loginIdentifier(username, loginDomain), password: password);
    final session = await _remote.fetchCurrentSession();
    if (session == null) {
      // Valid credentials but no active membership (disabled staff / suspended business).
      await signOut();
      throw const AppFailure(FailureKind.accountDisabled);
    }
    return session;
  }

  @override
  Future<void> signOut() async {
    try {
      await _remote.signOutLocally();
    } on AppFailure {
      // Offline sign-out still succeeds for the user: the SDK drops the
      // persisted session before contacting the server; ApiClient logged it.
    }
  }
}

/// Used when the build has no backend configuration: nothing is persisted
/// and every sign-in fails honestly instead of pretending to work.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  @override
  Stream<void> get sessionEnded => const Stream.empty();

  @override
  Future<UserSession?> restore() async => null;

  @override
  Future<UserSession> signIn({required String username, required String password}) async =>
      throw const AppFailure(FailureKind.serverUnavailable, diagnostic: 'not_configured');

  @override
  Future<void> signOut() async {}
}
