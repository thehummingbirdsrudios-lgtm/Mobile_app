# Regression suite

**Run before every merge (CI):** app format, analyze, boundaries, `flutter
test`, legal sync, web build, debug and release (R8) APK builds;
`tool/db_test.sh --scale`; Edge Functions (`deno fmt`, `lint`, `check
--frozen`, `test`); OSV dependency scan; gitleaks.

## Bugs found and their regression tests
| ID | Bug | Root cause | Regression test |
|---|---|---|---|
| R-001 | Catalogue page took 61 ms at scale | `SET search_path` blocked SQL-function inlining | `scale_perf_test.dart` latency and plan checks |
| R-002 | Android build failed in CI | Package `in.hummingbird.vepari`: `in` is a Java keyword | CI `flutter build apk --debug` |
| R-003 | Status chip text failed AA contrast (4.4:1) | Success colour too light for 12 px text | Contrast table in `ui-principles.md` (manual) |
| R-004 | Legal screen would show raw Markdown | Plain `Text` of `.md` | `app/test/features/legal_text_test.dart` |
| R-005 | Tablet Home stretched edge to edge | No max content width | Visual render `home-*-tablet` (manual review) |
| R-006 | A payment could be taken with an order without `payments.record` | `create_order` only checked `orders.create` | `authorization_privacy_test` "taking a payment with an order needs payments.record too" |
| R-007 | Order lines and the order total could diverge under a concurrent rate change | Rate re-resolved in three statements | Single resolution plus invariant check; `orders_money_test` "order lines always sum to the order total" |
| R-008 | A replayed order with a payment returned no payment (risk of double payment) | Replay path omitted the payment | `orders_money_test` "a replayed order returns the payment taken with it" |
| R-009 | Concurrent opening balances raised a raw 23505 | Check before lock | `orders_money_test` "concurrent opening balances" |
| R-010 | Any staff could read bill PDFs in Storage | Bucket-wide SELECT policy | `authorization_privacy_test` "bill PDFs in storage…" (mutation-probed) |
| R-011 | A share file could be moved into `bills` | UPDATE WITH CHECK checked only the tenant prefix | `authorization_privacy_test` "a share file cannot be moved…" (mutation-probed) |
| R-012 | SQLSTATEs like `23502` were treated as HTTP 5xx | Numeric parse of the code | `app_failure_test` "5-digit SQLSTATEs…", "3-digit codes are HTTP statuses" |
| R-013 | A banned user saw "wrong password"; offline auth showed a generic error | Status 400 checked before specific codes | `app_failure_test` "auth: specific codes win…" |
| R-014 | Deactivated staff kept a signed-in UI with cached data | Server rejection not fed back to the session | `api_client_test` "session rejection is published", `session_controller_test` |
| R-015 | AppSearchField could dispose a parent's controller | Ownership read from the current widget | Code fix (ownership fixed at init) |
| R-016 | Staff with only `orders.create` could replay any order and read its payment and Baki (security review, MEDIUM) | Replay returned the payment before the permission check; `client_request_id` was readable by every member | `authorization_privacy_test` "replaying an order never reveals its payment…", "idempotency keys are not readable…" |
| R-017 | No product photo ever loaded (signed URL never resolved) | `whenComplete` returned the removed in-flight future, which waited on itself | `signed_url_cache_test`, `catalogue_test` "photo resolves through a signed URL" |
| R-018 | A form field scrolled far off-screen was not validated; the save went to the server | Lazy `ListView` disposed the field, unregistering it from its `Form` | `form_validation_test` (fails on the old layout: an empty-name customer was submitted) |
| R-019 | Admin screens loaded data before checking the owner role | `ref.watch` ran before the `OwnerOnly` gate | `admin_test` "a staff deep link to owner screens is refused without a request" |
| R-020 | Audit log could not say which permission was removed | DELETE rows stored an empty change set | `owner_admin_test` "a removed permission records what was removed" |
| R-021 | "₹600 → ₹620" drawn with a missing-glyph box in Gujarati/Hindi | Hind fonts have no U+2192 | Glyph-coverage scan of every string; `admin_test` wording |
| R-022 | Bill PDFs, receipts and owner exports (with cost) were left in the phone's temp folder | share_plus writes in-memory files to a new temp folder per share and never deletes them | `file_sharer_test` (deleted after the sheet, swept at start-up) |
| R-023 | Any member could read, overwrite or delete every `share` bucket object (KI-012) | Bucket-wide policies | `hardening_test` "the share bucket is closed to app users" |
| R-024 | Staff who lost Hisaab permission still saw earlier payment notifications (amounts) | Inbox filtered only by recipient | `notifications_test` "losing Hisaab permission hides earlier payment notifications" |
| R-025 | Push registrar never resumed after sign-out under test time | Awaited `StreamSubscription.cancel()`, whose Future completes in the root zone | `notifications_test` "sign-out unregisters the device before signing out" |
| R-026 | Unread-count plan flipped to a seq scan in one scale run | Bulk load left no visibility map (no vacuum), so index-only scans looked expensive; production autovacuum maintains it | `scale_perf_test` vacuums after load; plans for a busy owner and a member with nothing unread, stable over repeated runs |
| R-027 | `push-dispatch` crashed at start-up on a malformed `FCM_SERVICE_ACCOUNT` (a partial paste), failing every webhook call | The secret was parsed at module load without a guard | `senderFromSecret` reports and disables push instead; `handler_test.ts` "the FCM secret: absent means off, malformed is reported and off, never a crash" |
| R-028 | Six RLS policies re-evaluated `auth.uid()` per row (Supabase advisor `auth_rls_initplan`) | Direct calls instead of a scalar subquery | `20261002000200_rls_initplan.sql`; isolation suite unchanged and passing; advisor clean for this lint |
