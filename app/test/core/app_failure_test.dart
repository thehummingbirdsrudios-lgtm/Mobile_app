import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vepari/core/core.dart';
import 'package:vepari/l10n/app_localizations_en.dart';

void main() {
  test('network and timeout', () {
    expect(AppFailure.from(const SocketException('x')).kind, FailureKind.network);
    expect(AppFailure.from(TimeoutException('x')).kind, FailureKind.timeout);
    expect(
      AppFailure.from(Exception('ClientException with SocketException: Failed host lookup')).kind,
      FailureKind.network,
    );
  });

  // R-029: on web the http package reports a failed fetch (offline, DNS,
  // blocked) as ClientException('Failed to fetch'); it was shown as a generic
  // error instead of the network message.
  test('a request that got no response is a network failure (web fetch)', () {
    final failure = AppFailure.from(http.ClientException('Failed to fetch', Uri.parse('https://x.test/rest')));
    expect(failure.kind, FailureKind.network);
    expect(failure.isRetryable, isTrue);
  });

  test('stable server codes map to user-meaningful kinds', () {
    PostgrestException pg(String message, [String code = 'P0001']) => PostgrestException(message: message, code: code);
    expect(AppFailure.from(pg('rate_changed')).kind, FailureKind.rateChanged);
    expect(AppFailure.from(pg('rate_changed')).code, 'rate_changed');
    expect(AppFailure.from(pg('product_unavailable')).kind, FailureKind.productUnavailable);
    expect(AppFailure.from(pg('permission_denied')).kind, FailureKind.permissionDenied);
    expect(AppFailure.from(pg('not_authenticated')).kind, FailureKind.sessionExpired);
    expect(AppFailure.from(pg('customer_not_found')).kind, FailureKind.notFound);
  });

  test('raw SQLSTATEs never leak; they are classified', () {
    expect(
      AppFailure.from(const PostgrestException(message: 'new row violates RLS', code: '42501')).kind,
      FailureKind.permissionDenied,
    );
    expect(AppFailure.from(const PostgrestException(message: 'dup', code: '23505')).kind, FailureKind.alreadyExists);
    expect(
      AppFailure.from(const PostgrestException(message: 'JWT expired', code: 'PGRST301')).kind,
      FailureKind.sessionExpired,
    );
  });

  test('5-digit SQLSTATEs are never mistaken for HTTP 5xx', () {
    PostgrestException pg(String code) => PostgrestException(message: 'x', code: code);
    expect(AppFailure.from(pg('23502')).kind, FailureKind.invalidInput);
    expect(AppFailure.from(pg('22001')).kind, FailureKind.invalidInput);
    expect(AppFailure.from(pg('22023')).kind, FailureKind.invalidInput);
    expect(AppFailure.from(pg('42883')).kind, FailureKind.unknown);
    expect(
      AppFailure.from(pg('42883')).isRetryable,
      isTrue,
      reason: 'unknown stays retryable but is not "server down"',
    );
    expect(AppFailure.from(pg('57014')).kind, FailureKind.timeout);
    expect(AppFailure.from(pg('40001')).kind, FailureKind.serverUnavailable);
  });

  test('3-digit codes are HTTP statuses', () {
    PostgrestException pg(String code) => PostgrestException(message: 'x', code: code);
    expect(AppFailure.from(pg('502')).kind, FailureKind.serverUnavailable);
    expect(AppFailure.from(pg('503')).kind, FailureKind.maintenance);
    expect(AppFailure.from(pg('504')).kind, FailureKind.timeout);
    expect(AppFailure.from(pg('401')).kind, FailureKind.sessionExpired);
  });

  test('auth: specific codes win over the 400 status', () {
    expect(
      AppFailure.from(const AuthException('banned', statusCode: '400', code: 'user_banned')).kind,
      FailureKind.accountDisabled,
    );
    expect(
      AppFailure.from(const AuthException('gone', statusCode: '400', code: 'refresh_token_not_found')).kind,
      FailureKind.sessionExpired,
    );
    expect(AppFailure.from(AuthRetryableFetchException(message: 'offline')).kind, FailureKind.network);
  });

  test('auth errors', () {
    expect(
      AppFailure.from(const AuthException('Invalid login credentials', statusCode: '400', code: 'invalid_credentials'))
          .kind,
      FailureKind.invalidCredentials,
    );
    expect(AppFailure.from(const AuthException('rate limited', statusCode: '429')).kind, FailureKind.serverUnavailable);
  });

  test('user messages are plain language and never contain technical detail', () {
    final l10n = AppLocalizationsEn();
    for (final kind in FailureKind.values) {
      final message = AppFailure(kind, diagnostic: 'postgrest:42501 SELECT secret').message(l10n);
      expect(message, isNotEmpty);
      expect(message, isNot(contains('postgrest')));
      expect(message, isNot(contains('42501')));
      expect(message, isNot(contains('Exception')));
    }
  });

  test('only transient failures are retryable', () {
    expect(const AppFailure(FailureKind.network).isRetryable, isTrue);
    expect(const AppFailure(FailureKind.permissionDenied).isRetryable, isFalse);
    expect(const AppFailure(FailureKind.rateChanged).isRetryable, isFalse);
  });

  test('Edge Function errors map by code, then by status', () {
    AppFailure fn(int status, Object? body) => AppFailure.from(FunctionException(status: status, details: body));
    final taken = fn(409, {'error': 'username_taken'});
    expect(taken.kind, FailureKind.alreadyExists);
    expect(taken.code, 'username_taken');
    final invalid = fn(400, {'error': 'invalid_request', 'field': 'password'});
    expect(invalid.kind, FailureKind.invalidInput);
    expect(invalid.details, {'field': 'password'});
    expect(fn(403, {'error': 'permission_denied'}).kind, FailureKind.permissionDenied);
    expect(fn(404, {'error': 'member_not_found'}).kind, FailureKind.notFound);
    expect(fn(401, {'error': 'not_authenticated'}).kind, FailureKind.sessionExpired);
    expect(fn(500, {'error': 'server_error'}).kind, FailureKind.serverUnavailable);
    expect(fn(502, 'Bad gateway').kind, FailureKind.serverUnavailable);
    expect(fn(401, null).kind, FailureKind.sessionExpired);
    expect(AppFailure.from(const FunctionsFetchException(details: 'offline')).kind, FailureKind.network);
  });
}
