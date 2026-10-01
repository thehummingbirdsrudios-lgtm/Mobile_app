# Acceptance criteria (Given / When / Then)

Each criterion names its requirement and the test that proves it.
DB = `backend_tests/test/*`, APP = `app/test/*`.

| Req | Criterion | Test |
|---|---|---|
| REQ-TEN-001 | Given tenants A, B, C with identical design numbers and customer names, when A's owner reads any table, then no row of B or C is returned | DB tenant_isolation: "reads never cross tenants" (22 tables) |
| REQ-TEN-001 | Given A's owner, when A passes B's ids to any RPC, then the call fails with a not-found code and nothing changes | DB tenant_isolation: "RPCs with manipulated ids" |
| REQ-TEN-001 | Given A, when A searches "1024" or "Rajesh", then only A's records appear | DB tenant_isolation: "search does not reveal other tenants" |
| REQ-TEN-001 | Given storage objects for A and B, when A lists, uploads or deletes under B's prefix, then it is denied/empty | DB tenant_isolation: "storage objects are tenant-scoped" |
| REQ-TEN-002 | When a client inserts with another tenant_id, then it is rejected; omitted tenant_id is stamped from the session | DB tenant_isolation: "writes cannot target or forge another tenant" |
| REQ-TEN-003 | Given active staff, when the owner deactivates them, then their next request sees nothing and `current_session()` is null | DB tenant_isolation "session revocation"; authorization "current_session" |
| REQ-TEN-004 | Given cached data for A, when the user logs out, then the cache is unbound before the signed-out state is published | APP session_controller_test |
| REQ-AUTH-001 | Given empty/invalid username, when Login is tapped, then inline validation shows and no server call is made | APP login_screen_test |
| REQ-AUTH-001 | Given wrong password, then "Username or password is wrong." shows and no technical text | APP login_screen_test |
| REQ-AUTH-003 | Given staff without a permission, when they call the protected RPC/table, then it is denied server-side | DB authorization_privacy: "staff permissions are enforced server-side" |
| REQ-MAAL-005 | Given cost/supplier data, when any staff reads product_private, then 0 rows | DB authorization_privacy: "owner-only data" |
| REQ-ORD-002 | Given Rajesh's ₹600 special rate, when ordering 1024×20 + 1025×10, then total = ₹15,200 computed by the server | DB orders_money: "server computes totals" |
| REQ-ORD-003 | When 10 concurrent requests share one client_request_id, then exactly one order exists | DB orders_money: "idempotency" |
| REQ-ORD-004 | Given expected rate ₹620 but effective ₹600, then `rate_changed` with current rates | DB orders_money |
| REQ-ORD-005 | Given a billed order, when the product rate/name changes or it is archived, then the bill payload is unchanged | DB orders_money: "history and bills" |
| REQ-ORD-006 | Given a completed order, cancel fails; given confirmed, processing → confirmed fails | DB orders_money: "order lifecycle" |
| REQ-HSB-001 | After 150 random orders/payments/cancels, Baki = Σ ledger = independent model | DB orders_money: property test |
| REQ-PAY-001 | When 10 concurrent retries of one payment arrive, then one payment and Baki decreases once | DB orders_money |
| REQ-SHARE-001 | For every share payload, cost, supplier, internal notes, other customers' rates and other tenant ids are absent | DB authorization_privacy: "safe share" |
| REQ-OWN-001 | Owner sees ₹38,500 / ₹22,000 / ₹4,82,000 / 3 formatted; staff without reports.view triggers no call | APP home_screen_test |
| REQ-UX-003 | Triple tap on a busy button runs the action once | APP app_button_test, login_screen_test |
| REQ-UX-004 | Back on a non-Home tab returns to Home | APP shell_test |
| REQ-UX-005 | Shell renders without overflow at 320 dp in gu, hi and en | APP shell_test |
| NFR-PERF-001 | At scale, hot-path plans contain no sequential scans on large tables | DB scale_perf |
