# Vepari — project rules for Claude Code and contributors

Vepari is a multi-tenant B2B app for Indian imitation-jewellery veparis
(Maal, Rate, Order, Fari Order, Customer, Hisaab, Payment, Bill, WhatsApp).
Correct first → simple second → fast third → beautiful throughout.

## Development cycle (never skip a phase; scale depth to the change)
Discover → Define (REQ-IDs + acceptance criteria) → Design (ADR if a decision
is non-trivial) → Plan → Implement → Verify → Review → Integrate → Operate.
Never claim "done" or "production-ready" without test/build evidence.

## Stack and commands
| Area | Command |
|---|---|
| DB tests (throwaway Postgres 16) | `tool/db_test.sh` · with scale data: `tool/db_test.sh --scale` |
| App deps | `cd app && flutter pub get` |
| App quality gate | `dart format --set-exit-if-changed . && flutter analyze && dart run tool/check_boundaries.dart && flutter test` |
| Legal texts | edit `docs/legal/*.md`, then `tool/sync_legal.sh` |
| Icons | edit `brand/*.svg`, then `NODE_PATH=<playwright> node brand/render.mjs` |
| Run app | `flutter run --dart-define-from-file=env/<env>.json` (copy `env/example.json`) |

Flutter 3.47.5 / Dart 3.13. Backend: Supabase (Postgres + RLS, Auth, Storage).

## Non-negotiable invariants
1. **Tenant isolation.** The tenant comes only from the verified JWT
   (`app.current_tenant_id()`); RPCs never take `tenant_id`. Every
   tenant-owned table has RLS and `UNIQUE (tenant_id, id)`; children use
   composite FKs. New tables MUST get isolation tests in
   `backend_tests/test/tenant_isolation_test.dart`.
2. **Money** is `bigint` paise in SQL and `Money` (int paise) in Dart. Never
   `double`. Totals are computed on the server only.
3. **Writes that move money or create orders/bills** are SECURITY DEFINER
   RPCs: permission check → idempotency (`client_request_id`) → validation →
   ledger + balance + audit in one transaction. Never direct table writes.
4. **History is immutable.** Ledger, payments and order items are append-only;
   confirmed orders snapshot rate/design/name.
5. **Safe share.** External content comes only from `share_product` /
   `bill_payload` (explicit allow-lists). Cost, supplier, internal notes and
   other customers' rates never leave.
6. **Truthful UI.** Never show success before the server commits. No fake
   data, no fake success, no raw errors (map through `AppFailure`).
7. **Migrations** are versioned and never edited once applied to any
   environment; add a new migration instead.

## App architecture (enforced by `app/tool/check_boundaries.dart`)
```
presentation → application → domain ← data (local | remote | repositories)
```
- `lib/core/` = shared kernel only (design, motion, errors, network,
  logging, money, storage, widgets). Core never imports features (R1).
- A feature imports another feature only via its barrel
  `lib/features/<x>/<x>.dart` (R2).
- `domain/` is pure Dart (R3). Presentation/application never import
  `data/` (R4). Supabase is used only in `data/`, `core/network`,
  `core/errors` and `lib/main.dart`, the single composition root (R5).
- All backend calls go through `ApiClient` (timeouts, error mapping,
  response validation, redacted structured logs).
- Use-case classes only where real business logic exists; no empty layers.
- Every user-facing string lives in `lib/l10n/app_{gu,hi,en}.arb`.

## Git
Conventional Commits, small focused commits, each one green. Never commit
secrets, `env/*.json` (except `example.json`), `key.properties` or build output.
