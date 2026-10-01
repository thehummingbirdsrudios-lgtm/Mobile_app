# Backend API contract

The API is **PostgREST over Postgres** (Supabase). All callers are authenticated
(`authenticated` role). The tenant is derived from the JWT and is never a
parameter.

- **Reads** use RLS-protected tables or SECURITY INVOKER RPCs.
- **Writes that move money or create orders or bills** go only through SECURITY
  DEFINER RPCs.

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
`service_role` only. Called by the provisioning Edge Function.

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

## Versioning
- Changes are additive: new optional parameters and new JSON fields.
- Clients ignore unknown fields. Unknown permission codes are ignored too
  (`session_dto.dart`).
- Breaking changes need a new RPC name, and the old one is removed only after
  the minimum supported app version moves past it.
