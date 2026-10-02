# Backend API contract

The API is **PostgREST over Postgres** (Supabase). All callers are authenticated
(`authenticated` role). The tenant is derived from the JWT and is never a
parameter.

- **Reads** use RLS-protected tables or SECURITY INVOKER RPCs.
- **Writes that move money or create orders or bills** go only through SECURITY
  DEFINER RPCs.

## Column visibility
Idempotency keys (`client_request_id` on `orders`, `payments` and
`ledger_entries`) are never readable by clients. Query these tables with
explicit column lists; PostgREST `select=*` on them is denied by design.

## Error model
RPC failures raise `SQLSTATE P0001` with `message` set to a **stable code**.
`detail` is JSON or empty. The client maps codes in
`app/lib/core/errors/app_failure.dart`. Raw SQL errors are never shown to users.

| Code | Meaning | Client kind |
|---|---|---|
| `not_authenticated` | No active membership (signed out, disabled, suspended) | sessionExpired |
| `permission_denied` | Caller lacks the permission | permissionDenied |
| `customer_not_found` / `product_not_found` / `order_not_found` / `bill_not_found` / `member_not_found` | Missing, or belongs to another tenant (indistinguishable by design) | notFound |
| `customer_inactive` | Archived customer | invalidInput |
| `product_unavailable` | Archived or unavailable design; `detail = [{product_id, design_no}]` | productUnavailable |
| `rate_changed` | The expected rate differs; `detail = [{product_id, rate_paise}]` | rateChanged |
| `order_empty`, `order_too_large`, `invalid_quantity`, `invalid_amount`, `invalid_request`, `invalid_transition`, `note_required`, `order_cancelled`, `amount_too_large` | Validation | invalidInput |
| `opening_exists` | Opening balance already recorded | alreadyExists |
| `username_taken` | Login name exists (any business) | alreadyExists |
| `maintenance` | Business writes are paused by the operator | maintenance |
| `immutable_record` | Attempt to change history | (should not occur via the API) |

Postgres codes:
- `42501`: privilege or RLS denial.
- `23503` / `23514`: FK or CHECK violation.

Both map to permission and validation kinds respectively.

## Write RPCs (idempotent on `client_request_id`)

### `create_order(p_customer_id, p_items, p_client_request_id, p_note?, p_reorder_of?, p_payment?) → order`
`orders.create`; also `payments.record` when `p_payment` is given. Items:
`[{product_id, qty, expected_rate_paise?}]`, at most 200 lines. Duplicate products are merged. `p_payment` is `{amount_paise, mode, reference?}`
and is recorded atomically with the order.

Returns `{order_id, order_no, customer_id, status, total_qty, total_paise,
total_weight_mg, created_at, replayed, payment?}`. A replay returns the same
order, and the same payment if one was taken with it. Each line's effective
rate is resolved once per call.

### `record_payment(p_customer_id, p_amount_paise, p_mode, p_client_request_id, p_reference?, p_note?, p_order_id?) → payment`
`payments.record`. Returns `{payment_id, payment_no, amount_paise, mode,
balance_before_paise, balance_after_paise, received_at, replayed}`.

### `record_adjustment(p_customer_id, p_kind 'opening'|'adjustment', p_amount_paise (signed), p_client_request_id, p_note?)`
`hisaab.adjust`. A note is required for adjustments.

### `transition_order(p_order_id, p_to)`
`orders.manage`. Only valid transitions. Repeating the same status replays.

### `cancel_order(p_order_id, p_reason?)`
`orders.manage`. Reverses the order's ledger entry once.

### `issue_bill(p_order_id) → {bill_id, bill_no, replayed}`
`bills.issue`. One bill per order. Cancelled orders cannot be billed.

### `set_member_permissions(p_user_id, p_permissions[])`, `set_member_active(p_user_id, p_active)`
Owner only, and staff targets only.

### `admin_create_tenant(...)`, `admin_add_member(...)`
`service_role` only. Used by operators to set up a business and its owner.

### `staff_admin_create(p_actor, p_user_id, p_username, p_display_name, p_permissions[])`, `staff_admin_check_target(p_actor, p_user_id)`, `staff_admin_record_password_reset(p_actor, p_user_id)`
`service_role` only, called by the `staff-admin` Edge Function.
- The tenant is derived from `p_actor`'s active owner membership. The request never supplies it.
- Audit rows are attributed to the actor.
- Errors: `permission_denied`, `member_not_found`, `username_taken`, `invalid_request` (with `{field}`).

### `register_device_token(p_token, p_platform, p_locale)`, `unregister_device_token(p_token)`
Any member. A token belongs to the login that registered it last. Each member keeps at most 10 devices.

### `mark_notifications_read(p_ids[]?) → integer`
Own notifications only, under RLS. `null` marks them all read.

## Edge Functions
| Function | Auth | Request | Responses |
|---|---|---|---|
| `staff-admin` | Caller's JWT; active owner | `{action: "create_staff", username, display_name, password, permissions[]}` or `{action: "reset_password", user_id, password}` | `200 {user_id}`. Errors: `400 invalid_request {field}`, `401 not_authenticated`, `403 permission_denied`, `404 member_not_found`, `409 username_taken`, `500 server_error`. |
| `push-dispatch` | `x-webhook-secret` (the `notifications_push` trigger, via `pg_net`; secret in Vault) | `{type: "INSERT", table: "notifications", record: {id}}` | `200 {sent, invalid, failed}`, or `{sent: 0, skipped: "not_configured"}` without FCM; `401` wrong secret. Push data: `{notification_id, kind, target_kind?, target_id?}` (ids only). |

## Read RPCs
| RPC | Auth | Returns |
|---|---|---|
| `current_session()` | any member | `{user_id, tenant_id, username, display_name, role, permissions[], business_name, default_locale}` or `null` |
| `search_all(q, limit ≤ 25)` | member | rows `(kind product\|customer\|order, id, title, subtitle, rank)` |
| `catalogue_page(after_published_at?, after_id?, limit ≤ 100, category_id?, new_since?)` | member | keyset page with thumbnail and catalogue paths |
| `regular_maal(customer_id, limit ≤ 50)` | member | designs by frequency, with today's rate and orderability |
| `reorder_preview(order_id)` | member | previous lines with the old rate, today's rate and orderability |
| `share_product(product_id, customer_id?)` | member | allow-listed share payload |
| `bill_payload(bill_id)` | `bills.issue` or `hisaab.view` | allow-listed bill document data |
| `dashboard_summary()` | `reports.view` | `{sales_today_paise, orders_today, payments_today_paise, total_baki_paise, pending_orders, new_maal_7d, day_start}` |
| `member_list()` | owner | members with role, active flag, permissions |
| `audit_page(before_id?, limit ≤ 200)` | owner | `(id, action, entity, entity_id, data, actor_name, created_at, subject)` |
| `notification_page(before_at?, before_id?, limit ≤ 100)` | member (own rows) | `(id, kind, target_kind, target_id, args, read_at, created_at)`; payment rows only with `hisaab.view` |
| `unread_notification_count()` | member | integer, capped at 100 |
| `export_customers / export_designs(after?, limit ≤ 1000)` | owner | keyset by id; designs include cost and supplier |
| `export_ledger / export_orders(from, to, after_at?, after_id?, limit ≤ 1000)` | owner | keyset by `(created_at, id)` within `[from, to)` |
| `export_order_items(from, to, after_at?, after_id?, limit ≤ 500 orders)` | owner | lines of whole orders |
| `app_status()` | anyone (also before sign-in) | `{min_app_version, maintenance}` |
| `push_targets(notification_id)`, `forget_device_tokens(tokens[])` | `service_role` | devices of an active recipient while the notification is unread; returns token, platform, locale, kind, args, target_kind, target_id |
| `push_webhook_secret()` | `service_role` | the Vault secret shared by the trigger and `push-dispatch` |

## Versioning
- Changes are additive: new optional parameters and new JSON fields.
- Clients ignore unknown fields. Unknown permission codes are ignored too
  (`session_dto.dart`).
- Breaking changes need a new RPC name, and the old one is removed only after
  the minimum supported app version moves past it.
