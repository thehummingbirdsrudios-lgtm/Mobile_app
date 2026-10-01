import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridable in tests.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

/// Build-time configuration, injected per environment with
/// `--dart-define-from-file=env/<env>.json` (see env/example.json).
///
/// Only PUBLIC values belong here: the Supabase URL and the publishable (anon)
/// key are designed to ship in clients — data is protected by RLS, not by
/// hiding them. Service-role keys and other secrets must never be in the app.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.loginDomain,
    required this.appVersion,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    loginDomain: String.fromEnvironment('LOGIN_DOMAIN', defaultValue: 'login.vepari.invalid'),
    appVersion: String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0'),
  );

  final String environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Domain of the synthetic auth identifier derived from a username
  /// (docs/security/auth.md). Must match the account-provisioning function.
  final String loginDomain;

  /// Shown in More → footer; CI injects the pubspec version.
  final String appVersion;

  bool get isConfigured => supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
  bool get isProduction => environment == 'production';
}
