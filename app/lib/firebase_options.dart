// Firebase client configuration for push (public identifiers, not secrets).
//
// Generated from the Firebase project's google-services.json for the Android
// app com.thehummingbirdstudio.vepari. While [DefaultFirebaseOptions.android]
// is null the app runs without push and notifications stay in the in-app
// inbox and bell.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  /// Options for this platform, or null where push is not available.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return android;
  }

  static const FirebaseOptions? android = null;
}
