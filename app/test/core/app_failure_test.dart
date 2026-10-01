import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
