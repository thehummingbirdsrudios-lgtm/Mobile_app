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
1. Apply `supabase/migrations/*` in order to a Supabase project
   (`supabase db push`). **Never apply `supabase/tests/shim/`** — it emulates
   platform pieces for local tests only.
2. Deploy the Edge Functions (`cd supabase/functions && deno test` first):
   - `supabase functions deploy staff-admin` — secret `LOGIN_DOMAIN` (same as the app's).
   - `supabase functions deploy push-dispatch --no-verify-jwt` — secrets
     `PUSH_WEBHOOK_SECRET` (random, ≥ 16 chars) and optionally
     `FCM_SERVICE_ACCOUNT`; then add a Database Webhook on INSERT into
     `public.notifications` that sends the same secret as `x-webhook-secret`.
3. Create the first business and owner with `admin_create_tenant` (service
   role). Owners then create staff from the app (More → Staff).
4. Operators can set `platform_settings.min_app_version` and `maintenance`
   (service role) to retire old builds or pause writes.

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
