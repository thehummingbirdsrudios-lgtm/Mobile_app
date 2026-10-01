import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/user_session.dart';
import 'session_dto.dart';

/// Remote data source: the auth backend (Supabase Auth + `current_session` RPC).
/// Transport concerns only — no business rules. All calls go through
/// [ApiClient] for uniform timeouts, error mapping and logging.
class AuthApi {
  AuthApi(this._auth, this._api);

  final GoTrueClient _auth;
  final ApiClient _api;

  bool get hasPersistedSession => _auth.currentSession != null;

  /// The session ended on the backend: the auth client signed out (refresh
  /// failed, signed out elsewhere) or the API rejected our membership.
  Stream<void> get sessionEnded => Stream<void>.multi((controller) {
    final subscriptions = [
      _auth.onAuthStateChange
          .where((state) => state.event == AuthChangeEvent.signedOut)
          .listen((_) => controller.add(null), onError: controller.addError),
      _api.sessionRejected.listen((_) => controller.add(null)),
    ];
    controller.onCancel = () => Future.wait(subscriptions.map((s) => s.cancel()));
  }, isBroadcast: true);

  Future<void> signInWithPassword({required String identifier, required String password}) =>
      _api.run('auth.sign_in', () => _auth.signInWithPassword(email: identifier, password: password));

  Future<void> signOutLocally() => _api.run('auth.sign_out', () => _auth.signOut(scope: SignOutScope.local));

  /// Null when the caller has no active membership in an active business.
  Future<UserSession?> fetchCurrentSession() =>
      _api.rpc('current_session', decode: (json) => json == null ? null : userSessionFromJson(asJsonObject(json)));
}
