# Security results

| Area | What was tested | Result | Evidence |
|---|---|---|---|
| Tenant isolation | 22 tables; id manipulation on every RPC; forged tenant_id; composite-FK linking; storage list, upload and delete; search; deactivation; suspension | 32 tests pass | `tenant_isolation_test.dart` |
| Isolation tests detect leaks | Mutation probe: one RLS policy made permissive and the storage helper always true | 5 tests failed as expected | Session log, 2026-10-01 |
| Authorization | Staff without permission on Hisaab, catalogue, rates, customers, dashboard and remarks; escalation through RPC, direct table write and admin functions | Pass | `authorization_privacy_test.dart` |
| Owner-only data | Cost, supplier and notes invisible to all staff; audit redacts cost values | Pass | same |
| Financial integrity | Server totals; concurrent duplicate orders and payments; ledger property test (150 operations); reconciliation; immutability triggers | Pass | `orders_money_test.dart` |
| Idempotency tests detect regressions | Mutation probe: idempotency lock removed | 2 tests failed as expected | Session log |
| Code-review fixes | Payment permission via create_order; bill PDF reads; cross-bucket moves; replay with payment; session rejection → client sign-out | Pass; storage fixes mutation-probed | R-006 to R-014 in regression-suite.md |
| Safe share | Seeded secrets absent from product and bill payloads; allow-listed keys | Pass | `authorization_privacy_test.dart` |
| Input abuse | Malformed JSON items, non-integer and out-of-range quantities, huge line counts, LIKE wildcards in search, oversized queries | Pass | `orders_money_test.dart`, `authorization_privacy_test.dart` |
| Client error leakage | Every failure kind renders without codes, SQL or exception names | Pass | `app_failure_test.dart` |
| Logging | Sensitive field names redacted; payloads never logged | Pass | `api_client_test.dart` |
| Secrets | gitleaks across full history | Pass (CI) | CI "Secret scan" |
| Android data | Backups and device transfer disabled; session in the keystore | Configured, not device-tested | AndroidManifest, `data_extraction_rules.xml` |

**Not yet tested:**
- Hosted Supabase project settings
- The Edge Function for provisioning (not built)
- DAST against a deployed API
- A dependency vulnerability audit (`flutter pub outdated` is advisory only; no CVE scanner wired yet; KI-009)
- Upload malware scanning
