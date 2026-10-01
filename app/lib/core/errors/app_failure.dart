import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, PostgrestException;

import '../../l10n/app_localizations.dart';

/// What went wrong, in user terms. Raw exceptions (SQL, HTTP, stack traces)
/// never reach the UI; they go to [AppFailure.diagnostic] for safe logging.
enum FailureKind {
  network,
  timeout,
  serverUnavailable,
  invalidCredentials,
  accountDisabled,
  sessionExpired,
  permissionDenied,
  notFound,
  alreadyExists,
  productUnavailable,
  rateChanged,
  invalidInput,
  maintenance,

  /// The server answered with data that does not match the contract.
  invalidResponse,
  unknown,
}

@immutable
class AppFailure implements Exception {
  const AppFailure(this.kind, {this.code, this.diagnostic});

  final FailureKind kind;

  /// Stable server error code (e.g. `rate_changed`) when one exists.
  final String? code;

  /// Developer-facing detail. Never shown to users; never contains secrets.
  final String? diagnostic;

  /// Whether retrying the same request can reasonably succeed.
  bool get isRetryable => switch (kind) {
    FailureKind.network ||
    FailureKind.timeout ||
    FailureKind.serverUnavailable ||
    FailureKind.invalidResponse ||
    FailureKind.unknown => true,
    _ => false,
  };

  String message(AppLocalizations l10n) => switch (kind) {
    FailureKind.network => l10n.errorNetwork,
    FailureKind.timeout => l10n.errorTimeout,
    FailureKind.serverUnavailable => l10n.errorServerUnavailable,
    FailureKind.invalidCredentials => l10n.errorInvalidCredentials,
    FailureKind.accountDisabled => l10n.errorAccountDisabled,
    FailureKind.sessionExpired => l10n.errorSessionExpired,
    FailureKind.permissionDenied => l10n.errorPermission,
    FailureKind.notFound => l10n.errorNotFound,
    FailureKind.alreadyExists => l10n.errorAlreadyExists,
    FailureKind.productUnavailable => l10n.errorProductUnavailable,
    FailureKind.rateChanged => l10n.errorRateChanged,
    FailureKind.invalidInput => l10n.errorInvalidInput,
    FailureKind.maintenance => l10n.errorMaintenance,
    FailureKind.invalidResponse || FailureKind.unknown => l10n.errorGeneric,
  };

  /// Converts any thrown object into an [AppFailure].
  static AppFailure from(Object error) {
    if (error is AppFailure) return error;
    if (error is TimeoutException) return const AppFailure(FailureKind.timeout);
    if (error is SocketException) return const AppFailure(FailureKind.network);
    if (error is PostgrestException) return _fromPostgrest(error);
    if (error is AuthException) return _fromAuth(error);
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Failed host lookup') || text.contains('XMLHttpRequest')) {
      return const AppFailure(FailureKind.network);
    }
    return AppFailure(FailureKind.unknown, diagnostic: error.runtimeType.toString());
  }

  /// Server error codes raised by `app.fail()` (docs/architecture/api.md).
  static const _serverCodes = <String, FailureKind>{
    'not_authenticated': FailureKind.sessionExpired,
    'permission_denied': FailureKind.permissionDenied,
    'customer_not_found': FailureKind.notFound,
    'product_not_found': FailureKind.notFound,
    'order_not_found': FailureKind.notFound,
    'bill_not_found': FailureKind.notFound,
    'member_not_found': FailureKind.notFound,
    'customer_inactive': FailureKind.invalidInput,
    'product_unavailable': FailureKind.productUnavailable,
    'rate_changed': FailureKind.rateChanged,
    'order_empty': FailureKind.invalidInput,
    'order_too_large': FailureKind.invalidInput,
    'invalid_quantity': FailureKind.invalidInput,
    'invalid_amount': FailureKind.invalidInput,
    'invalid_request': FailureKind.invalidInput,
    'invalid_transition': FailureKind.invalidInput,
    'note_required': FailureKind.invalidInput,
    'opening_exists': FailureKind.alreadyExists,
    'order_cancelled': FailureKind.invalidInput,
    'amount_too_large': FailureKind.invalidInput,
    'maintenance': FailureKind.maintenance,
  };

  static AppFailure _fromPostgrest(PostgrestException e) {
    final byMessage = _serverCodes[e.message];
    if (byMessage != null) return AppFailure(byMessage, code: e.message, diagnostic: 'postgrest:${e.code}');
    final kind = switch (e.code) {
      '42501' => FailureKind.permissionDenied,
      '23505' => FailureKind.alreadyExists,
      '23503' || '23514' || '22P02' || '22003' => FailureKind.invalidInput,
      'PGRST301' || 'PGRST302' => FailureKind.sessionExpired,
      'PGRST116' => FailureKind.notFound,
      _ => (int.tryParse(e.code ?? '') ?? 0) >= 500 ? FailureKind.serverUnavailable : FailureKind.unknown,
    };
    return AppFailure(kind, diagnostic: 'postgrest:${e.code}');
  }

  static AppFailure _fromAuth(AuthException e) {
    final status = int.tryParse(e.statusCode ?? '') ?? 0;
    final code = e.code ?? '';
    if (code == 'invalid_credentials' || status == 400) {
      return AppFailure(FailureKind.invalidCredentials, diagnostic: 'auth:$code');
    }
    if (code == 'user_banned') return AppFailure(FailureKind.accountDisabled, diagnostic: 'auth:$code');
    if (code == 'session_expired' || code == 'refresh_token_not_found' || status == 401) {
      return AppFailure(FailureKind.sessionExpired, diagnostic: 'auth:$code');
    }
    if (status == 429) return const AppFailure(FailureKind.serverUnavailable, diagnostic: 'auth:rate_limited');
    if (status >= 500) return AppFailure(FailureKind.serverUnavailable, diagnostic: 'auth:$status');
    return AppFailure(FailureKind.unknown, diagnostic: 'auth:$code');
  }

  @override
  String toString() => 'AppFailure($kind${code == null ? '' : ', $code'})';
}
