# Vepari

Online-first B2B app for Indian imitation-jewellery veparis: catalogue (Maal),
customer rates, orders and Fari Order, Hisaab (ledger), payments, photo bills
and WhatsApp sharing — private per business, simple for staff, complete for
owners.

| Path | What |
|---|---|
| `app/` | Flutter app (Android + web) |
| `supabase/migrations/` | Postgres schema, RLS, RPCs (the backend API) |
| `supabase/functions/` | Edge Functions: `staff-admin` (staff logins), `push-dispatch` (FCM) |
| `backend_tests/` | Database test-suite (isolation, money, concurrency, scale) |
| `brand/` | Logo sources and icon renderer |
| `docs/` | Requirements, architecture, security, privacy, legal, testing |
| `tool/` | `db_test.sh`, `sync_legal.sh` |

## Run the app (fresh clone)
```bash
git clone https://github.com/thehummingbirdsrudios-lgtm/Mobile_app.git
cd Mobile_app/app          # the Flutter project is in app/
flutter pub get
flutter run -d chrome      # or: flutter devices, then flutter run -d <phone id>
flutter build apk --release   # → build/app/outputs/flutter-apk/app-release.apk
```
No setup file is needed: a build without `--dart-define` options connects to
the hosted project `vepari` (public URL and publishable key in
`lib/core/config/app_config.dart`; Firebase push config in
`lib/firebase_options.dart`). Sign in with a username created by an operator
or owner ([docs/operations/onboarding.md](docs/operations/onboarding.md)); use
the QA business for experiments, never a real business.

**You need:**
- Flutter **3.47.x** stable (Dart 3.13.4 or newer). CI uses 3.47.5.
- For Android: Android Studio with the Android SDK, accepted licences
  (`flutter doctor --android-licenses`), and JDK 17 or newer. Gradle 9.3 and
  AGP 9.1 download on the first build; Flutter installs NDK 28.2 itself.
- Chrome for the web build. Push notifications are Android-only; on web,
  notifications stay in the in-app inbox and bell.

In VS Code, open the repository folder: the Run panel has **Vepari (Chrome)**,
**Vepari (phone / emulator)** and **Vepari (phone, release mode)**.

**Other backend** (your own Supabase project): `cp env/example.json
env/dev.json`, fill in the values, and add `--dart-define-from-file=env/dev.json`
to `flutter run` / `flutter build`. `env/*.json` is gitignored.

**Release signing:** without `android/key.properties` the release APK is
signed with the debug key. That is fine for installing on phones, but Play
rejects it.

**Windows:** if a build fails only because the path contains spaces or
brackets (for example `D:\New folder (5)\Mobile_app`), build from a junction:
`mklink /J C:\dev\Mobile_app "D:\New folder (5)\Mobile_app"`, then
`cd C:\dev\Mobile_app\app`.

## Database tests
```bash
tool/db_test.sh            # throwaway Postgres 16: Supabase shim + migrations + the suite
tool/db_test.sh --scale    # adds 10k/5k/50k data and query-plan checks
```

## Deploying the backend
The hosted project is **`vepari`** (`zzghblixuxhjxpxzugac`, ap-south-1 Mumbai),
deployed and tested on 2026-10-02. For another environment:

1. Apply `supabase/migrations/*` in order (`supabase db push`, or the Supabase
   MCP / SQL Editor). **Never apply `supabase/tests/shim/`**: it emulates
   platform pieces for local tests only.
2. Deploy the Edge Functions (`cd supabase/functions && deno test` first):
   - `supabase functions deploy staff-admin` (JWT verification on). Optional
     secret `LOGIN_DOMAIN`; the default matches the app's.
   - `supabase functions deploy push-dispatch --no-verify-jwt`. Secret
     `FCM_SERVICE_ACCOUNT` (the Firebase service-account JSON) turns push on.
3. Configure the push webhook in Vault (the trigger and the function read it;
   the secret is generated in the database and never handled by a person):
   ```sql
   select vault.create_secret('https://<ref>.supabase.co/functions/v1/push-dispatch', 'vepari_push_url');
   select vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'vepari_push_secret');
   ```
4. Authentication: turn **off** "Allow new users to sign up". Accounts are
   created only by owners (staff) and operators (owners).
5. Create each business and its owner: [docs/operations/onboarding.md](docs/operations/onboarding.md).
6. Operators can set `platform_settings.min_app_version` and `maintenance`
   (service role) to retire old builds or pause writes.

Hosted migration history notes: versions are the times they were applied
(names match the files), `20261001000500_business_rpcs` is recorded in three
parts, and five migrations were run through the SQL Editor because the MCP
connector asks for interactive approval of any `drop`/`delete` statement.

## Pilot build
Actions → **Pilot build** → Run workflow. The inputs default to the hosted
project (public URL and publishable key). It produces an installable release APK and an
AAB as artifacts. Without `android/key.properties` they are debug-signed:
fine for pilot phones, not accepted by Play.

## Status
Increments 0–16 are built and tested; see
[docs/testing/final-test-report.md](docs/testing/final-test-report.md) for
evidence and the pilot checklist (device QA, hosted project, Firebase, legal
review are still to do).

## Documentation
Start at [docs/architecture/modules.md](docs/architecture/modules.md),
[docs/requirements/SRS.md](docs/requirements/SRS.md) and
[docs/plan/implementation-plan.md](docs/plan/implementation-plan.md).
Project rules for contributors: [CLAUDE.md](CLAUDE.md).
