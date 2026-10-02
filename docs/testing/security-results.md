# Security results

| Area | What was tested | Result | Evidence |
|---|---|---|---|
| Tenant isolation | 23 tables incl. `device_tokens`; id manipulation on every RPC; forged tenant_id; composite-FK linking; storage list, upload and delete; search; deactivation; suspension; inbox, mark-read and token hand-over | Pass | `tenant_isolation_test.dart` |
| Isolation tests detect leaks | Mutation probe: one RLS policy made permissive and the storage helper always true | 5 tests failed as expected | Session log, 2026-10-01 |
| Authorization | Staff without permission on Hisaab, catalogue, rates, customers, dashboard and remarks; escalation through RPC, direct table write and admin functions | Pass | `authorization_privacy_test.dart` |
| Owner-only data | Cost, supplier and notes invisible to all staff; audit redacts cost values | Pass | same |
| Financial integrity | Server totals; concurrent duplicate orders and payments; ledger property test (150 operations); reconciliation; immutability triggers | Pass | `orders_money_test.dart` |
| Idempotency tests detect regressions | Mutation probe: idempotency lock removed | 2 tests failed as expected | Session log |
| Code-review fixes | Payment permission via create_order; bill PDF reads; cross-bucket moves; replay with payment; session rejection → client sign-out | Pass; storage fixes mutation-probed | R-006 to R-014 in regression-suite.md |
| Security review (focused, high-confidence) | Full branch: RLS, grants, DEFINER RPCs, storage, client | 1 MEDIUM finding (R-016) fixed with regression tests; no cross-tenant path found | regression-suite.md |
| Safe share | Seeded secrets absent from product and bill payloads; allow-listed keys | Pass | `authorization_privacy_test.dart` |
| Input abuse | Malformed JSON items, non-integer and out-of-range quantities, huge line counts, LIKE wildcards in search, oversized queries | Pass | `orders_money_test.dart`, `authorization_privacy_test.dart` |
| Client error leakage | Every failure kind renders without codes, SQL or exception names | Pass | `app_failure_test.dart` |
| Logging | Sensitive field names redacted; payloads never logged | Pass | `api_client_test.dart` |
| Secrets | gitleaks across full history | Pass (CI) | CI "Secret scan" |
| Staff provisioning (Edge Function) | Caller from own JWT; owner-only; tenant never taken from the body; input rules; rollback of half-created logins; passwords/tokens never logged | 12 Deno + 8 DB tests pass (mutation-probed: owner check and rollback) | `staff-admin/handler_test.ts`, `owner_admin_test.dart` |
| Push dispatch | Webhook secret (constant-time, ≥16 chars); lock-screen text without amounts; data payload id+kind only; invalid tokens forgotten; RS256 JWT verified | 9 Deno tests pass | `push-dispatch/handler_test.ts` |
| Notifications | Never to the actor or stopped staff; payment amounts only to `hisaab.view` (re-checked at read time); no cost/supplier/notes in any row | Pass | `notifications_test.dart` |
| Export | Owner-only even for all-permission staff; own business only; CSV formula injection defused | Pass | `export_test.dart` (DB + app) |
| Storage hardening | `share` bucket closed; photo originals owner/catalogue-manager only; no cross-bucket moves (share and remarks → bills) | Pass | `hardening_test.dart`, `authorization_privacy_test.dart` |
| Maintenance / version gate | Writes paused for app users (RPC and direct), reads and operators unaffected; platform settings not readable/writable by app users; gate fails open | Pass | `hardening_test.dart`, `app_gate_test.dart` |
| Device temp files | Shared bills/receipts/exports deleted after the share sheet; leftovers swept; names cannot escape the folder | Pass | `file_sharer_test.dart` |
| Dependencies | OSV-Scanner over `app/pubspec.lock` (161 packages) and `backend_tests/pubspec.lock` (51) | No known vulnerabilities (CI, 2026-10-02) | CI "Dependencies — known vulnerabilities (OSV)" |
| Focused review of increments 11–16 | RLS/grants of new tables and RPCs, SECURITY DEFINER/INVOKER choice, Edge Function trust boundaries, client storage and logging | 1 finding fixed (R-024); accepted risks KI-015/KI-019 documented | regression-suite.md, known-issues.md |
| Android data | Backups and device transfer disabled; session in the keystore | Configured, not device-tested | AndroidManifest, `data_extraction_rules.xml` |

**Not yet tested:**
- Hosted Supabase project settings (KI-004)
- Deployed Edge Functions and Database Webhook (KI-014)
- DAST against a deployed API
- `deno.lock` dependency audit (not an OSV format; KI-018)
- Upload malware scanning (KI-005)
