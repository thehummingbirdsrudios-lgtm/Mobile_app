import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, critical }

/// One structured log event. `fields` must never contain secrets or
/// business payloads (passwords, tokens, Hisaab, customer data, voice):
/// log operation names, durations, outcomes and error categories only.
@immutable
class LogEvent {
  const LogEvent(this.level, this.message, {this.fields = const {}, required this.time});

  final LogLevel level;
  final String message;
  final Map<String, Object?> fields;
  final DateTime time;
}

/// Where log events go. Development: console. Production: a crash/telemetry
/// sink (added only after the privacy review in docs/privacy/).
abstract interface class LogSink {
  void write(LogEvent event);
}

class ConsoleLogSink implements LogSink {
  const ConsoleLogSink();

  @override
  void write(LogEvent event) {
    final fields = event.fields.entries.map((e) => '${e.key}=${e.value}').join(' ');
    debugPrint('[${event.level.name.toUpperCase()}] ${event.time.toIso8601String()} ${event.message} $fields');
  }
}

/// Structured logger with a minimum level and defensive redaction.
class AppLogger {
  AppLogger({required this.minLevel, this._sinks = const [ConsoleLogSink()], DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Debug detail in development builds; warnings and above in release.
  factory AppLogger.forBuild() => AppLogger(minLevel: kReleaseMode ? LogLevel.warning : LogLevel.debug);

  final LogLevel minLevel;
  final List<LogSink> _sinks;
  final DateTime Function() _clock;

  static final _sensitiveKey = RegExp(r'pass|token|secret|key|auth|cookie|session', caseSensitive: false);

  void log(LogLevel level, String message, [Map<String, Object?> fields = const {}]) {
    if (level.index < minLevel.index) return;
    final safe = {for (final e in fields.entries) e.key: _sensitiveKey.hasMatch(e.key) ? '[redacted]' : e.value};
    final event = LogEvent(level, message, fields: safe, time: _clock().toUtc());
    for (final sink in _sinks) {
      sink.write(event);
    }
  }

  void debug(String message, [Map<String, Object?> fields = const {}]) => log(LogLevel.debug, message, fields);
  void info(String message, [Map<String, Object?> fields = const {}]) => log(LogLevel.info, message, fields);
  void warning(String message, [Map<String, Object?> fields = const {}]) => log(LogLevel.warning, message, fields);
  void error(String message, [Map<String, Object?> fields = const {}]) => log(LogLevel.error, message, fields);
}
