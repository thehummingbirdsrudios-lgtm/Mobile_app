# Vepari

Online-first B2B app for Indian imitation-jewellery veparis: catalogue (Maal),
customer rates, orders and Fari Order, Hisaab (ledger), payments, photo bills
and WhatsApp sharing — private per business, simple for staff, complete for
owners.

| Path | What |
|---|---|
| `app/` | Flutter app (Android + web) |
| `supabase/migrations/` | Postgres schema, RLS, RPCs (the backend API) |
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
Apply `supabase/migrations/*` in order to a Supabase project
(`supabase db push`). **Never apply `supabase/tests/shim/`** — it emulates
platform pieces for local tests only. Accounts are created by the business
owner through a service-role function (see docs/security/auth.md).

## Documentation
Start at [docs/architecture/modules.md](docs/architecture/modules.md),
[docs/requirements/SRS.md](docs/requirements/SRS.md) and
[docs/plan/implementation-plan.md](docs/plan/implementation-plan.md).
Project rules for contributors: [CLAUDE.md](CLAUDE.md).
