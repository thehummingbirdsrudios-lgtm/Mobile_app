import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vepari/core/core.dart';

class _Transport implements RpcTransport {
  _Transport(this.handler);

  final Future<Object?> Function(String, Map<String, Object?>?) handler;
  final calls = <String>[];

  @override
  Future<Object?> rpc(String function, Map<String, Object?>? params) {
    calls.add(function);
    return handler(function, params);
  }
}

class _MemorySink implements LogSink {
  final events = <LogEvent>[];

  @override
  void write(LogEvent event) => events.add(event);
}

void main() {
  late _MemorySink sink;
  late AppLogger logger;

  setUp(() {
    sink = _MemorySink();
    logger = AppLogger(minLevel: LogLevel.debug, sinks: [sink]);
  });

  ApiClient client(Future<Object?> Function(String, Map<String, Object?>?) handler, {Duration? timeout}) =>
      ApiClient(transport: _Transport(handler), logger: logger, timeout: timeout ?? const Duration(seconds: 1));

  test('decodes a valid response', () async {
    final api = client((_, _) async => {'total': 5});
    final total = await api.rpc('x', decode: (json) => asJsonObject(json).requireInt('total'));
    expect(total, 5);
    expect(sink.events.single.message, 'api.ok');
  });

  test('malformed response becomes invalidResponse, not a crash', () async {
    final api = client((_, _) async => {'total': 'five'});
    await expectLater(
      api.rpc('dashboard_summary', decode: (json) => asJsonObject(json).requireInt('total')),
      throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.invalidResponse)),
    );
    expect(sink.events.last.level, LogLevel.error);
    expect(sink.events.last.fields['op'], 'dashboard_summary');
  });

  test('timeouts are enforced centrally', () async {
    final api = client((_, _) => Completer<Object?>().future, timeout: const Duration(milliseconds: 20));
    await expectLater(
      api.rpc('slow', decode: (j) => j),
      throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.timeout)),
    );
  });

  test('server error codes are classified', () async {
    final api = client((_, _) async => throw const PostgrestException(message: 'rate_changed', code: 'P0001'));
    await expectLater(
      api.rpc('create_order', decode: (j) => j),
      throwsA(isA<AppFailure>().having((f) => f.kind, 'kind', FailureKind.rateChanged)),
    );
  });

  test('session rejection is published so the app can sign out', () async {
    final api = client((_, _) async => throw const PostgrestException(message: 'not_authenticated', code: 'P0001'));
    final events = <void>[];
    final sub = api.sessionRejected.listen(events.add);
    await expectLater(api.rpc('dashboard_summary', decode: (j) => j), throwsA(isA<AppFailure>()));
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    await sub.cancel();
    await api.dispose();
  });

  test('logger redacts sensitive field names and respects level', () {
    final quiet = AppLogger(minLevel: LogLevel.warning, sinks: [sink]);
    quiet.info('hidden');
    expect(sink.events, isEmpty);
    quiet.warning('auth.fail', {'password': 'p@ss', 'accessToken': 'abc', 'op': 'sign_in'});
    expect(sink.events.single.fields, {'password': '[redacted]', 'accessToken': '[redacted]', 'op': 'sign_in'});
  });

  test('JsonReader names the bad field', () {
    expect(
      () => <String, dynamic>{}.requireString('user_id'),
      throwsA(isA<FormatException>().having((e) => e.source, 'field', 'user_id')),
    );
    expect(<String, dynamic>{'n': 4.0}.requireInt('n'), 4);
    expect(() => <String, dynamic>{'n': 4.5}.requireInt('n'), throwsFormatException);
    expect(<String, dynamic>{}.stringList('p'), isEmpty);
    expect(() => asJsonObject([1]), throwsFormatException);
  });
}
