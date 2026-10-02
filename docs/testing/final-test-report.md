# Final test report — increments 0–16

**Date:** 2026-10-02. **Branch:** `claude/exciting-turing-cl6wu0`. **Base:** `main`, which includes thehummingbirdsrudios-lgtm/Mobile_app#3.

This report covers only what was run, and says plainly what was not.

## Verdict
- **Code-complete** for the planned scope: increments 0–16.
- **Not production-ready yet.** The app has not been deployed or run on a device. The pilot checklist below lists what is still needed.

## What ran (all passing)

| Suite | Command | Result |
|---|---|---|
| Database: functional and scale | `tool/db_test.sh --scale` (PostgreSQL 16 with the Supabase shim) | **182 passed**: 162 functional + 20 scale, twice in a row |
| Edge Functions | `deno fmt --check`, `deno lint`, `deno check --frozen */index.ts`, `deno test --frozen` | **21 passed** (`staff-admin` 12, `push-dispatch` 9) |
| App | `dart format --set-exit-if-changed`, `flutter analyze`, `tool/check_boundaries.dart`, legal sync, `flutter test` | Clean; **307 passed** |
| Visual review | `VEPARI_SCREENSHOTS=1 flutter test test/visual --update-goldens` | **28 render tests (34 images)** (gu/hi/en, phone and tablet) reviewed by eye. Selected renders are in `screenshots/`. |
| CI on the PR head | GitHub Actions | App (incl. web, debug APK and release R8 APK), database (incl. scale), Edge Functions, OSV (no known vulnerabilities in 161 + 51 Dart packages), gitleaks |

**Mutation probes** confirmed that these tests fail when the code under test is broken:
- tenant isolation (RLS and storage)
- idempotency
- bill-PDF storage policies
- `staff-admin` owner check and rollback
- forms validating off-screen fields

## What the tests cover
Traceability by requirement is in [test-matrix.md](test-matrix.md).

- **Tenant isolation:**
  - Every tenant table, including `device_tokens` and notifications.
  - Every RPC with manipulated ids.
  - Search, storage, export and provisioning.
  - Deactivated staff and suspended businesses.
- **Money:**
  - Server totals.
  - Concurrent duplicates.
  - The ledger equals Baki under random operation sequences.
  - Immutability, reversals and the rate-changed rule.
- **Privacy:**
  - Owner-only cost, supplier and notes.
  - Share and bill allow-lists.
  - Notifications without secrets.
  - Payment amounts only for `hisaab.view`, re-checked when the inbox is read.
  - CSV formula-injection guard.
  - Share temp files deleted after use.
- **Bill PDF:**
  - 1–100 lines; each row's embedded photo is decoded and matched to its design.
  - Image cases: slow, 404, broken, oversized, PNG, WebP, redirect, non-image, duplicate, offline cache.
  - Size bounds.
  - Gujarati and Hindi shaping.
- **Performance at 10k products / 5k customers / 50k orders:**
  - Every hot path is index-only.
  - Plans take 0.3–15 ms; RPCs take 12–30 ms client wall time on a shared container.
  - Details: [performance-results.md](performance-results.md).

## Defects found during this work
26 regressions are logged in [regression-suite.md](regression-suite.md), each with its test. The latest ones:

| ID | Defect |
|---|---|
| R-018 | Off-screen form fields skipped validation |
| R-019 | Owner screens loaded data before the role check |
| R-021 | Missing arrow glyph in Gujarati and Hindi |
| R-022 | Share temp files left on the phone |
| R-023 | `share` bucket open to all members |
| R-024 | Payment notifications visible after Hisaab was revoked |
| R-026 | Plan flip without a visibility map |

## Not verified (and why)

| Area | Why | Tracked |
|---|---|---|
| Real devices: camera, mic, share sheet, keystore, fonts, performance | No device or emulator in this environment. The APKs are built in CI but never installed. | KI-003 |
| Hosted Supabase: Auth settings, backups, restore drill | No hosted project yet | KI-004 |
| Deployed Edge Functions and Database Webhook | Needs the hosted project | KI-014 |
| Push delivery to a phone | Needs the business's Firebase project | KI-013 |
| WhatsApp hand-off | Needs a device. The app only opens the share sheet and never claims "sent". | KI-003 |
| User acceptance with veparis | Not run | KI-007 |
| Legal texts | Drafts with placeholders; need legal review | `docs/legal` |

## Pilot checklist
1. Create the hosted Supabase project: signups off, region, JWT expiry, PITR, then a restore drill.
2. Apply the migrations, set the secrets, and deploy `staff-admin` and `push-dispatch`. Then add the webhook.
3. Create a Firebase project and add `firebase_messaging` behind `PushTokenSource`.
4. Build a signed release with the store key. Run the regression suite by hand on three phones (API 24 low-end, mid-range, tablet).
5. Run sessions with 3–5 veparis, then fix the findings.
6. Get legal review of the privacy policy and terms, and fill in the business details.
