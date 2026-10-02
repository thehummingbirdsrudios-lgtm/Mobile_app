# Final test report — increments 0–16 and the hosted deployment

**Date:** 2026-10-02. **Branch:** `claude/exciting-turing-cl6wu0`.
**Hosted project:** `vepari` (`zzghblixuxhjxpxzugac`, ap-south-1 Mumbai).

This report covers only what was run, and says plainly what was not.

## Verdict
- **Backend deployed and verified live**: migrations, both Edge Functions, the push webhook and the money flow, exercised through the real APIs (below).
- **Push**: wired end to end and verified up to Firebase; it switches on when the Firebase project is connected. No push has reached a phone yet.
- **Not production-ready yet.** The app has not run on a device, and the operator items in the pilot checklist are open.

## What ran (all passing)

| Suite | Command | Result |
|---|---|---|
| Database: functional and scale | `tool/db_test.sh --scale` (PostgreSQL 16 with the Supabase shim) | **167 functional + 20 scale** |
| Edge Functions | `deno fmt --check`, `deno lint`, `deno check --frozen */index.ts`, `deno test --frozen` | **23 passed** (`staff-admin` 12, `push-dispatch` 11) |
| App | `dart format --set-exit-if-changed`, `flutter analyze`, `tool/check_boundaries.dart`, legal sync, `flutter test`, `flutter build web --release` | Clean; **314 passed**; web build OK |
| Visual review | `VEPARI_SCREENSHOTS=1 flutter test test/visual --update-goldens` | 28 render tests (34 images), from increments 11–16 |
| CI | GitHub Actions on the PR head | App (incl. web, debug and release APK), database (incl. scale), Edge Functions, OSV, gitleaks |
| **Hosted, live** | Real Auth / REST / Edge Function endpoints of `vepari`, called from inside the database with `pg_net` (the build container cannot reach `*.supabase.co`) | See next section |

## Hosted checks (2026-10-02)

| Check | Result |
|---|---|
| Owner sign-in (`/auth/v1/token`) | 200 |
| `current_session` via REST | role owner, business "Vepari QA (test)" |
| `staff-admin` create staff | 200 (live Auth admin API) |
| Duplicate username (different case) | 409 `username_taken` |
| No token | 401 |
| Staff calling `staff-admin` | 403 |
| Owner resets a staff password | 200; the old password is then rejected, the new one works |
| Staff reads the owner-only cost table | `[]` (RLS) |
| Staff adds a design via REST | 201, tenant set by the server |
| Notification → trigger → `pg_net` → `push-dispatch` | 200 `skipped: not_configured` (the webhook secret came from Vault; no FCM secret yet) |
| Forged webhook secret | 401 |
| Order + cash payment sent twice concurrently | One order (#1) and one payment (#1); the second reply is a replay |
| Bill | #1 issued |
| Books | Baki ₹1,000 = ledger sum; audit trail complete (staff created, password reset, order, payment, bill) |
| Advisors | No ERROR; RLS init-plan warnings fixed; the rest accepted (KI-021) or plan-dependent (KI-004) |

**Mutation probes** confirmed that these tests fail when the code under test is broken:
- tenant isolation (RLS and storage)
- idempotency
- bill-PDF storage policies
- `staff-admin` owner check and rollback
- forms validating off-screen fields
- the push webhook body (no data beyond the id)

One honest gap: the launch-push test passes even without the one-frame wait, so that wait is a safeguard, not a proven fix.

## Defects found during this work
28 regressions are logged in [regression-suite.md](regression-suite.md), each with its test. The deployment itself found:
- a `push-dispatch` crash on a malformed secret (R-027, fixed);
- per-row `auth.uid()` in six policies (R-028, fixed);
- sign-ups still enabled (operator setting, KI-004).

## Not verified (and why)

| Area | Why | Tracked |
|---|---|---|
| Real devices: camera, mic, share sheet, keystore, fonts, performance, push | No device or emulator here (the Android SDK download is blocked); APKs are built in CI only | KI-003, KI-013 |
| The app UI against the hosted backend | This container's network policy blocks `*.supabase.co` for the browser; the backend was tested through its APIs instead | — |
| Backups, PITR and a restore drill | Free plan; needs the operator's plan decision | KI-004 |
| WhatsApp hand-off | Needs a device. The app only opens the share sheet and never claims "sent". | KI-003 |
| User acceptance with veparis | Not run | KI-007 |

## Pilot checklist (operator)
1. Supabase: turn off sign-ups. Decide on the Pro plan (PITR, daily backups), then run a restore drill.
2. Firebase: Android app `com.thehummingbirdstudio.vepari`; `google-services.json` becomes `lib/firebase_options.dart`; set the `FCM_SERVICE_ACCOUNT` function secret.
3. Run **Pilot build**; install the APK on 3 phones (API 24 low-end, mid-range, tablet) and run the regression suite by hand, including a real push.
4. Create each vepari's business and owner ([operations/onboarding.md](../operations/onboarding.md)).
5. Fill in the `[placeholders]` in the legal texts and have counsel confirm the push/region/share-file additions.
6. Create a release signing key before any Play Store upload.
