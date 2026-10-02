import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridable in tests.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

/// Build-time configuration.
///
/// A plain `flutter run` / `flutter build` uses the hosted pilot project
/// `vepari` (see [hostedSupabaseUrl]). Any value can be overridden per
/// environment with `--dart-define-from-file=env/<env>.json` (see
/// env/example.json) or `--dart-define=NAME=value`.
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
    supabaseUrl: String.fromEnvironment('SUPABASE_URL', defaultValue: hostedSupabaseUrl),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: hostedPublishableKey),
    loginDomain: String.fromEnvironment('LOGIN_DOMAIN', defaultValue: 'login.vepari.invalid'),
    appVersion: String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0'),
  );

  /// The hosted project `vepari` (ap-south-1). Public client values.
  static const hostedSupabaseUrl = 'https://zzghblixuxhjxpxzugac.supabase.co';
  static const hostedPublishableKey = 'sb_publishable_NCnjAfRo6RcrrBBWJx3Nrg_of2bQe4R'; // gitleaks:allow (public key)

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
