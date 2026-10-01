# Compatibility matrix

## Minimum supported Android: API 24 (Android 7.0)
**Rationale:**
- API 24 is Flutter 3.47's default minimum SDK, and its tooling warns below it.
  Verified in `flutter_tools/gradle/.../FlutterExtension.kt` and
  `DependencyVersionChecker.kt`.
- Supporting less would fight the toolchain and its plugins.
- flutter_secure_storage relies on the Keystore features that are reliable on
  these versions.
- The share of target users on Android < 7 is assumed negligible. Confirm with
  Play Console data after the pilot.

Set in `app/android/app/build.gradle.kts` (`minSdk = 24`).

| Target | Status | Notes |
|---|---|---|
| Android API 24 (7.0), low-end 2 GB | **Not tested** | Needs a physical device or emulator. The Android SDK cannot be downloaded in the dev container. |
| Android 10–14 mid-range | **Not tested** | — |
| Android 15+ (edge-to-edge, predictive back) | **Not tested** | `PopScope` is used, so it is compatible with predictive back |
| Android debug APK build | CI | `flutter build apk --debug` in CI |
| Web (Chromium) | Tested | Login rendered at 360 / 768 / 1280 in gu/hi/en; see `screenshots/` |
| Phone layout 320 dp / 360 dp | Tested (widget tests) | 6 tabs in gu/hi/en, no overflow |
| Tablet / desktop layout (rail) | Tested (widget and visual) | `screenshots/home-*-tablet.png` |
| Gujarati, Hindi, English rendering | Tested | Bundled Hind / Hind Vadodara fonts |
| Emoji (👋) on web | Depends on Google's emoji font CDN | Shows tofu offline; Android uses the system emoji font (KI-006) |
| iOS | Out of scope | Android-first |
