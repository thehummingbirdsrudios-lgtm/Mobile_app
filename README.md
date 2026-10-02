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

## Quick start
```bash
# Database: applies the Supabase shim + migrations to a throwaway Postgres 16 and runs the suite
tool/db_test.sh            # add --scale for 10k/5k/50k data + query-plan checks

# App
cd app
flutter pub get
cp env/example.json env/development.json   # fill in your Supabase URL + publishable key
flutter run --dart-define-from-file=env/development.json
```
Without configuration the app starts and says plainly that no server is set up.

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
Actions → **Pilot build** → Run workflow, with the project URL and the
publishable key (both public). It produces an installable release APK and an
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
