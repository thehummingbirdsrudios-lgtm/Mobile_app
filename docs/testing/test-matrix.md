# Test matrix (traceability)

| Requirement | Tests | Type | Status |
|---|---|---|---|
| REQ-TEN-001/002/003 | `backend_tests/test/tenant_isolation_test.dart` (32) | DB integration | Pass |
| REQ-TEN-004 | `app/test/features/auth/session_controller_test.dart`, `app/test/core/tenant_cache_test.dart` | Unit | Pass |
| REQ-AUTH-001 | `app/test/features/auth/login_screen_test.dart`, `username_and_mapper_test.dart` | Widget / unit | Pass |
| REQ-AUTH-003 | `authorization_privacy_test.dart` "staff permissions…", "current_session" | DB | Pass |
| REQ-AUTH-004 | `session_controller_test.dart` (sign-out, expiry) | Unit | Pass |
| REQ-MAAL-004/005 | `orders_money_test.dart` (archived), `authorization_privacy_test.dart` (owner-only) | DB | Pass |
| REQ-SRCH-001/002 | `authorization_privacy_test.dart` "universal search", `scale_perf_test.dart` | DB | Pass |
| REQ-RATE-001/002 | `orders_money_test.dart` (special rate), `authorization_privacy_test.dart` (rates.manage, audit) | DB | Pass |
| REQ-ORD-002…008 | `orders_money_test.dart` | DB | Pass |
| REQ-HSB-001/002, REQ-PAY-001/002 | `orders_money_test.dart` | DB | Pass |
| REQ-BILL-001 | `orders_money_test.dart` "history and bills" | DB | Pass |
| REQ-SHARE-001 | `authorization_privacy_test.dart` "safe share" | DB | Pass |
| REQ-OWN-001 | `authorization_privacy_test.dart` (dashboard), `app/test/features/dashboard/home_screen_test.dart` | DB + widget | Pass |
| REQ-OWN-003 | `authorization_privacy_test.dart` (audit) | DB | Pass |
| REQ-UX-002/003 | `app_button_test.dart`, `home_screen_test.dart`, `login_screen_test.dart` | Widget | Pass |
| REQ-UX-004/005/006 | `app/test/app/shell_test.dart` | Widget | Pass |
| NFR-PERF-001/002 | `scale_perf_test.dart` | DB scale | Pass |
| NFR-A11Y-001 | Contrast table in `ui-principles.md`; semantic labels (button test) | Manual + widget | Partial |
| NFR-I18N-001 | `money_test.dart`, `formatters_test.dart` | Unit | Pass |

**Totals (2026-10-01):**
- Database: 107 functional + 16 scale = 123 tests.
- App: 74 tests, plus 7 opt-in visual renders.

**Not yet automated:**
- E2E journeys on a device
- Lifecycle (background / kill / resume)
- Permissions
- Network fault injection
- Backup/restore drill
