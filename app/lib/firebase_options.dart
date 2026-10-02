// Firebase client configuration for push (public identifiers, not secrets).
//
// From the Firebase project `imition-4e9ce` (google-services.json for the
// Android app com.thehummingbirdstudio.vepari). Firebase client API keys
// identify the project; they are not credentials. Restrict this key to the
// Android app (package + signing SHA-1) in the Google Cloud console.
// Without options the app runs without push and notifications stay in the
// in-app inbox and bell.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  /// Options for this platform, or null where push is not available.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcg5nvrPdaUBzLfiGu-ncheKmStoABA-w', // gitleaks:allow (public Firebase client key)
    appId: '1:884297956401:android:85c982d6e7b543a9eee910',
    messagingSenderId: '884297956401',
    projectId: 'imition-4e9ce',
    storageBucket: 'imition-4e9ce.firebasestorage.app',
  );
}
