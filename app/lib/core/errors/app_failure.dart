import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException, PostgrestException;

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
  const AppFailure(this.kind, {this.code, this.diagnostic, this.details});

  final FailureKind kind;

  /// Stable server error code (e.g. `rate_changed`) when one exists.
  final String? code;

  /// Developer-facing detail. Never shown to users; never contains secrets.
  final String? diagnostic;

  /// Structured data the server attached to a business error, e.g. for
  /// `rate_changed` the list of `{product_id, rate_paise}` now in force.
  /// Decoded JSON; read only through typed helpers in the feature that
  /// expects it.
  final Object? details;

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

  static final _httpStatus = RegExp(r'^\d{3}$');

  static Object? _decodeDetails(Object? raw) {
    if (raw is! String) return raw;
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  /// PostgREST puts a SQLSTATE (5 chars) or a `PGRST…` code in [PostgrestException.code],
  /// and the HTTP status (3 digits) only when the response body was not JSON.
  static AppFailure _fromPostgrest(PostgrestException e) {
    final byMessage = _serverCodes[e.message];
    if (byMessage != null) {
      return AppFailure(
        byMessage,
        code: e.message,
        diagnostic: 'postgrest:${e.code}',
        details: _decodeDetails(e.details),
      );
    }
    final code = e.code ?? '';
    final kind = _httpStatus.hasMatch(code) ? _fromHttpStatus(int.parse(code)) : _fromSqlState(code);
    return AppFailure(kind, diagnostic: 'postgrest:$code');
  }

  static FailureKind _fromHttpStatus(int status) => switch (status) {
    401 => FailureKind.sessionExpired,
    403 => FailureKind.permissionDenied,
    404 => FailureKind.notFound,
    408 || 504 => FailureKind.timeout,
    503 => FailureKind.maintenance,
    >= 500 => FailureKind.serverUnavailable,
    _ => FailureKind.unknown,
  };

  static FailureKind _fromSqlState(String code) => switch (code) {
    'PGRST301' || 'PGRST302' => FailureKind.sessionExpired,
    'PGRST116' => FailureKind.notFound,
    '42501' => FailureKind.permissionDenied,
    '23505' => FailureKind.alreadyExists,
    '57014' => FailureKind.timeout, // statement timeout
    '40001' || '40P01' => FailureKind.serverUnavailable, // serialization failure / deadlock: safe to retry
    '53300' || '57P03' => FailureKind.serverUnavailable, // too many connections / starting up
    _ when code.startsWith('22') || code.startsWith('23') => FailureKind.invalidInput, // data / constraint
    _ => FailureKind.unknown,
  };

  static AppFailure _fromAuth(AuthException e) {
    // Network-level failure inside the auth client (no HTTP response at all).
    if (e is AuthRetryableFetchException) return const AppFailure(FailureKind.network, diagnostic: 'auth:fetch');
    final status = int.tryParse(e.statusCode ?? '') ?? 0;
    final code = e.code ?? '';
    // Specific codes first: GoTrue also uses HTTP 400 for bans and bad refresh tokens.
    final kind = switch (code) {
      'invalid_credentials' => FailureKind.invalidCredentials,
      'user_banned' => FailureKind.accountDisabled,
      'session_expired' ||
      'session_not_found' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' => FailureKind.sessionExpired,
      'over_request_rate_limit' => FailureKind.serverUnavailable,
      _ => switch (status) {
        400 => FailureKind.invalidCredentials,
        401 || 403 => FailureKind.sessionExpired,
        429 => FailureKind.serverUnavailable,
        >= 500 => FailureKind.serverUnavailable,
        _ => FailureKind.unknown,
      },
    };
    return AppFailure(kind, diagnostic: 'auth:${code.isEmpty ? status : code}');
  }

  @override
  String toString() => 'AppFailure($kind${code == null ? '' : ', $code'})';
}
