import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_failure.dart';
import '../logging/app_logger.dart';

/// The one transport port to the backend's public API (Postgres RPCs exposed
/// by PostgREST). Swappable for tests or a different backend.
abstract interface class RpcTransport {
  Future<Object?> rpc(String function, Map<String, Object?>? params);
}

class SupabaseRpcTransport implements RpcTransport {
  const SupabaseRpcTransport(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> rpc(String function, Map<String, Object?>? params) async =>
      _client.rpc<Object?>(function, params: params);
}

/// Centralised API layer. Every backend call goes through [run] / [rpc], so
/// timeouts, error classification, response validation and structured
/// logging are defined once — never per screen or per repository.
///
/// Retries are deliberately NOT automatic: reads are retried by the user
/// (ErrorState → "Fari try karo"), and writes are made safe to retry by the
/// server's idempotency keys rather than by blind client loops.
class ApiClient {
  ApiClient({required this._transport, required this._logger, this.timeout = const Duration(seconds: 15)});

  final RpcTransport _transport;
  final AppLogger _logger;
  final Duration timeout;
  int _sequence = 0;

  /// Calls a backend RPC and decodes the result with [decode]. Any malformed
  /// payload surfaces as [FailureKind.invalidResponse].
  Future<T> rpc<T>(
    String function, {
    Map<String, Object?>? params,
    required T Function(Object? json) decode,
    Duration? timeout,
  }) {
    return run(function, () async => decode(await _transport.rpc(function, params)), timeout: timeout);
  }

  /// Runs any backend operation (e.g. an auth SDK call) under the same
  /// policy. [operation] is a stable name used in logs, never user data.
  Future<T> run<T>(String operation, Future<T> Function() action, {Duration? timeout}) async {
    final requestId = '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_sequence++}';
    final watch = Stopwatch()..start();
    try {
      final result = await action().timeout(timeout ?? this.timeout);
      _logger.debug('api.ok', {'op': operation, 'rid': requestId, 'ms': watch.elapsedMilliseconds});
      return result;
    } on FormatException catch (e) {
      throw _fail(operation, requestId, watch, AppFailure(FailureKind.invalidResponse, diagnostic: e.message));
    } on TypeError catch (e) {
      throw _fail(operation, requestId, watch, AppFailure(FailureKind.invalidResponse, diagnostic: '$e'));
    } catch (e) {
      throw _fail(operation, requestId, watch, AppFailure.from(e));
    }
  }

  AppFailure _fail(String operation, String requestId, Stopwatch watch, AppFailure failure) {
    final level = switch (failure.kind) {
      FailureKind.invalidResponse || FailureKind.unknown => LogLevel.error,
      FailureKind.invalidCredentials || FailureKind.permissionDenied => LogLevel.info,
      _ => LogLevel.warning,
    };
    _logger.log(level, 'api.fail', {
      'op': operation,
      'rid': requestId,
      'ms': watch.elapsedMilliseconds,
      'kind': failure.kind.name,
      'code': failure.code,
      'diag': failure.diagnostic,
    });
    return failure;
  }
}
