# Test matrix (traceability)

Updated 2026-10-02 (after the hosted deployment). Paths are relative to `app/test/`, `backend_tests/test/` or
`supabase/functions/`.

| Requirement | Tests | Type | Status |
|---|---|---|---|
| REQ-TEN-001/002/003 | `tenant_isolation_test.dart` (tables incl. `device_tokens`, RPCs, search, storage, notifications, token hand-over), `owner_admin_test.dart` (provisioning never crosses tenants) | DB | Pass |
| REQ-TEN-004 | `features/auth/session_controller_test.dart`, `core/tenant_cache_test.dart`, `core/signed_url_cache_test.dart` | Unit | Pass |
| REQ-AUTH-001 | `features/auth/login_screen_test.dart`, `username_and_mapper_test.dart` | Widget, unit | Pass |
| REQ-AUTH-002 | `staff-admin/handler_test.ts` (12, mutation-probed), `owner_admin_test.dart`, `features/admin/admin_test.dart` (add staff, taken username, reset password); live checks on the hosted project | Deno, DB, widget, live | Pass |
| REQ-AUTH-003 | `authorization_privacy_test.dart`, `features/admin/admin_test.dart` (permissions, stop access) | DB, widget | Pass |
| REQ-AUTH-004 | `session_controller_test.dart` (sign-out, expiry, refresh, before-sign-out hook) | Unit | Pass |
| REQ-MAAL-001…005 | `features/catalogue/catalogue_test.dart`, `navo_maal_test.dart`, `core/image_pipeline_test.dart`, `read_models_test.dart`, `hardening_test.dart` (originals) | Widget, unit, DB | Pass |
| REQ-SRCH-001/002 | `features/search/*`, `authorization_privacy_test.dart`, `scale_perf_test.dart` | Widget, DB | Pass |
| REQ-CUST-001…003 | `features/customers/*`, `read_models_test.dart`, `features/form_validation_test.dart` | Widget, DB | Pass |
| REQ-RATE-001/002 | `orders_money_test.dart`, `authorization_privacy_test.dart`, `owner_admin_test.dart` (audit subjects) | DB | Pass |
| REQ-ORD-001…008 | `features/orders/orders_flow_test.dart`, `orders_unit_test.dart`, `orders_money_test.dart` | Widget, unit, DB | Pass |
| REQ-HSB-*, REQ-PAY-* | `features/hisaab/hisaab_test.dart`, `orders_money_test.dart` (incl. random-sequence ledger model) | Widget, DB | Pass |
| REQ-BILL-001/002 | `features/bills/bills_test.dart`, `bill_pdf_test.dart` (1–100 lines, every image case), `orders_money_test.dart` | Widget, unit, DB | Pass |
| REQ-SHARE-001/002 | `authorization_privacy_test.dart` (allow-lists), `features/sharing/sharing_test.dart`, `core/file_sharer_test.dart` (temp files) | DB, widget, unit | Pass |
| REQ-VAAT-001 | `features/remarks/vaat_test.dart` | Widget | Pass |
| REQ-NOTIF-001 | `notifications_test.dart` (fan-out rules, no secrets, stopped staff), `tenant_isolation_test.dart`, `features/notifications/notifications_test.dart` | DB, widget | Pass |
| REQ-NOTIF-002 | `push-dispatch/handler_test.ts` (11), `push_webhook_test.dart` (5), `features/notifications/push_messages_test.dart` (7: tap, launch push, foreground note, sign-out reset), registration in `features/notifications`; live trigger → function on the hosted project | Deno, DB, widget, live | Pass up to FCM (device push: KI-013) |
| REQ-EXP-001 | `export_test.dart` (owner-only, isolation, paging), `features/export/export_test.dart` (CSV rules, injection, Indic, screen) | DB, unit, widget | Pass |
| REQ-OPS-001 | `hardening_test.dart` (maintenance, app_status), `features/settings/app_gate_test.dart` | DB, widget | Pass |
| REQ-OWN-001…003 | `features/dashboard/home_screen_test.dart`, `features/admin/*`, `owner_admin_test.dart`, `authorization_privacy_test.dart` | Widget, DB | Pass |
| REQ-UX-001…006 | `app/shell_test.dart`, `core/app_button_test.dart`, `features/form_validation_test.dart`, 320dp/three-language checks | Widget | Pass |
| NFR-PERF-001/002 | `scale_perf_test.dart` (10k/5k/50k, plus inbox, unread count and export plans) | DB scale | Pass |
| NFR-SEC-001 | `hardening_test.dart`, isolation and privacy suites, gitleaks and OSV in CI | DB, CI | Pass |
| NFR-A11Y-001 | Contrast table in `ui-principles.md`, semantic labels, badge contrast (gold text 6:1) | Manual, widget | Partial |
| NFR-I18N-001 | `money_test.dart`, `formatters_test.dart`, glyph-coverage scan of all strings | Unit, script | Pass |

**Totals (2026-10-02, local runs, all passing):**
- **Database:** 167 functional tests. With `--scale`: 187, which adds the 10k products / 5k customers / 50k orders plans.
- **Edge Functions:** 23 Deno tests, plus `deno fmt`, `lint` and `check --frozen`.
- **App:** 314 tests, plus 28 opt-in visual renders (gu/hi/en).
- **Hosted (live):** the checks listed under "Hosted, live" in security-results.md.
- **CI:** app (format, analyze, boundaries, tests, web, debug and release APK), database (incl. scale), Edge Functions, OSV dependency scan, and gitleaks.

**Not yet automated:**
- E2E journeys on a device (KI-003)
- Lifecycle (background / kill / resume)
- OS permission prompts
- Network fault injection
- Backup/restore drill (KI-004)
- Push delivery to a phone (KI-013)
- The launch-push test passes even without the one-frame wait in `PushMessages.start`; the wait is a defensive safeguard, not proven necessary
