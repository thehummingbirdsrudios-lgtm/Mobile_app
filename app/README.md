# Vepari — Flutter app

See the repository [README](../README.md) for the product overview and
[docs/architecture/modules.md](../docs/architecture/modules.md) for the module rules.

```bash
flutter pub get
flutter run            # hosted backend `vepari` by default; another one: --dart-define-from-file=env/<env>.json
flutter analyze && flutter test && dart run tool/check_boundaries.dart
```
