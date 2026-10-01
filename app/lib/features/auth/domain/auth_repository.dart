import 'user_session.dart';

/// Outcome of local username validation (the server re-checks everything).
enum UsernameIssue { empty, invalid }

/// Usernames are simple handles like `rajesh`: 3–32 chars, a–z, 0–9, dot,
/// underscore — identical to the database CHECK on app_users.username.
abstract final class Username {
  static final _pattern = RegExp(r'^[a-z0-9][a-z0-9._]{2,31}$');

  static String normalize(String input) => input.trim().toLowerCase();

  static UsernameIssue? validate(String input) {
    final value = normalize(input);
    if (value.isEmpty) return UsernameIssue.empty;
    if (!_pattern.hasMatch(value)) return UsernameIssue.invalid;
    return null;
  }

  /// Synthetic Supabase Auth identifier for a username (never emailed).
  static String loginIdentifier(String username, String domain) => '${normalize(username)}@$domain';
}

/// Authentication port. Implementations: Supabase (production) and fakes
/// (tests). Errors are thrown as `AppFailure`.
abstract interface class AuthRepository {
  /// Restores a persisted session, or null when signed out / no longer a member.
  Future<UserSession?> restore();

  Future<UserSession> signIn({required String username, required String password});

  Future<void> signOut();

  /// Fires when the backend ends the session (expiry, revocation, sign-out elsewhere).
  Stream<void> get sessionEnded;
}
