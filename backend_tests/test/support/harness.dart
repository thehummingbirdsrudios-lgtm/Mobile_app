import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// A fresh database cloned from the migrated `vepari_template`, plus helpers
/// to act as specific authenticated users exactly the way PostgREST does
/// (`SET LOCAL ROLE authenticated` + `request.jwt.claims`).
class TestDb {
  TestDb._(this.name, this._adminEndpoint, this.admin);

  final String name;
  final Endpoint _adminEndpoint;

  /// Superuser connection to the test database (fixtures / assertions only).
  final Connection admin;
  final List<Connection> _actorConnections = [];

  static final _random = Random.secure();

  static Future<TestDb> create() async {
    final url = Platform.environment['VEPARI_ADMIN_URL'];
    final template = Platform.environment['VEPARI_TEMPLATE_DB'];
    if (url == null || template == null) {
      throw StateError('Run through tool/db_test.sh (VEPARI_ADMIN_URL / VEPARI_TEMPLATE_DB unset).');
    }
    final base = _endpointFromUrl(url);
    final name = 'vt_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 30)}';
    final server = await Connection.open(base, settings: _settings);
    try {
      await server.execute('create database "$name" template "$template"');
    } finally {
      await server.close();
    }
    final endpoint = Endpoint(
      host: base.host,
      port: base.port,
      database: name,
      username: base.username,
      password: base.password,
    );
    final admin = await Connection.open(endpoint, settings: _settings);
    return TestDb._(name, endpoint, admin);
  }

  static const _settings = ConnectionSettings(sslMode: SslMode.disable);

  static Endpoint _endpointFromUrl(String url) {
    final uri = Uri.parse(url);
    final userInfo = uri.userInfo.split(':');
    return Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.isEmpty ? 'postgres' : uri.pathSegments.first,
      username: userInfo.first.isEmpty ? 'postgres' : userInfo.first,
      password: userInfo.length > 1 ? userInfo[1] : null,
    );
  }

  /// Opens a dedicated connection that acts as [userId] (or anonymous).
  Future<Actor> actor(String? userId) async {
    final conn = await Connection.open(_adminEndpoint, settings: _settings);
    _actorConnections.add(conn);
    return Actor._(conn, userId);
  }

  Future<void> dispose() async {
    for (final c in _actorConnections) {
      await c.close();
    }
    await admin.close();
    final server = await Connection.open(
      Endpoint(
        host: _adminEndpoint.host,
        port: _adminEndpoint.port,
        database: 'postgres',
        username: _adminEndpoint.username,
        password: _adminEndpoint.password,
      ),
      settings: _settings,
    );
    try {
      await server.execute('drop database if exists "$name" with (force)');
    } finally {
      await server.close();
    }
  }

  static String newId() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}

/// Executes SQL as an API caller. Every call is its own transaction, like a
/// PostgREST request.
class Actor {
  Actor._(this._conn, this.userId);

  final Connection _conn;
  final String? userId;

  Future<Result> query(String sql, [Map<String, Object?> params = const {}]) {
    return _conn.runTx((tx) async {
      if (userId == null) {
        await tx.execute('set local role anon');
        await tx.execute("select set_config('request.jwt.claims', '{\"role\":\"anon\"}', true)");
      } else {
        await tx.execute('set local role authenticated');
        await tx.execute(
          Sql.named("select set_config('request.jwt.claims', @claims, true)"),
          parameters: {
            'claims': jsonEncode({'sub': userId, 'role': 'authenticated'}),
          },
        );
      }
      return tx.execute(Sql.named(sql), parameters: params);
    });
  }

  Future<Object?> scalar(String sql, [Map<String, Object?> params = const {}]) async {
    final result = await query(sql, params);
    return result.isEmpty ? null : result.first.first;
  }

  Future<Map<String, dynamic>> json(String sql, [Map<String, Object?> params = const {}]) async {
    final value = await scalar(sql, params);
    return Map<String, dynamic>.from(value! as Map);
  }

  Future<int> count(String sql, [Map<String, Object?> params = const {}]) async {
    final result = await query(sql, params);
    return result.length;
  }
}

/// Matches a database error by stable app error code (`app.fail`) or SQLSTATE.
Matcher throwsDbError(String codeOrSqlState) => throwsA(
  isA<ServerException>().having(
    (e) => e.message == codeOrSqlState || e.code == codeOrSqlState,
    'message "$codeOrSqlState" or SQLSTATE $codeOrSqlState',
    isTrue,
  ),
);

/// Postgres denies a privilege / violates RLS with SQLSTATE 42501.
const insufficientPrivilege = '42501';
