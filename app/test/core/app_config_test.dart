import 'package:flutter_test/flutter_test.dart';
import 'package:vepari/core/config/app_config.dart';

void main() {
  // `flutter test` passes no --dart-define, like a plain `flutter run` from a
  // fresh clone: the build must still reach the hosted backend.
  test('a build without dart-defines is configured for the hosted project', () {
    final config = AppConfig.fromEnvironment();
    expect(config.isConfigured, isTrue);
    expect(config.supabaseUrl, AppConfig.hostedSupabaseUrl);
    expect(config.supabasePublishableKey, AppConfig.hostedPublishableKey);
    expect(config.loginDomain, 'login.vepari.invalid');
  });

  test('the built-in values are public client values only', () {
    expect(Uri.parse(AppConfig.hostedSupabaseUrl).isScheme('https'), isTrue);
    expect(AppConfig.hostedPublishableKey, startsWith('sb_publishable_'));
  });

  test('an empty or non-https URL leaves the app unconfigured', () {
    const blank = AppConfig(
      environment: 'test',
      supabaseUrl: '',
      supabasePublishableKey: 'k',
      loginDomain: 'login.vepari.invalid',
      appVersion: '0.1.0',
    );
    const plain = AppConfig(
      environment: 'test',
      supabaseUrl: 'http://example.test',
      supabasePublishableKey: 'k',
      loginDomain: 'login.vepari.invalid',
      appVersion: '0.1.0',
    );
    expect(blank.isConfigured, isFalse);
    expect(plain.isConfigured, isFalse);
  });
}
