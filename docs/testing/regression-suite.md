# Regression suite

**Run before every merge (CI):** app format, analyze, boundaries, `flutter
test`, legal sync, web and APK builds; `tool/db_test.sh --scale`; gitleaks.

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
