# Data model and data dictionary

Source of truth: `supabase/migrations/*.sql`. Diagram: [erd.mmd](erd.mmd).

## Conventions
| Rule | Why |
|---|---|
| `uuid` PKs via `gen_random_uuid()`; human numbers (`order_no`, `bill_no`, `payment_no`) per tenant | Non-guessable ids; friendly numbers scoped per business |
| Every tenant-owned table has `tenant_id NOT NULL` and `UNIQUE (tenant_id, id)` | Lets children use **composite FKs**, so a row can never reference another tenant's row, even from SECURITY DEFINER code |
| Money: `bigint` paise, with CHECK bounds (rate ≤ ₹1 crore per piece; totals ≤ ₹10,000 crore) | Exact arithmetic, overflow-safe |
| Quantity: `integer` pieces 1–1,00,000 per line; weight: `integer` milligrams | No fractional pieces; exact weights |
| Timestamps: `timestamptz` (UTC); business day computed in `business_profiles.timezone` (default Asia/Kolkata) | Correct "today" across midnight |
| Archive, not delete: products and customers use `status` / `archived_at`; no DELETE grants | History and bills stay valid |
| Append-only financial history: `ledger_entries`, `payments`, `order_items`, `audit_logs` have triggers that reject UPDATE and DELETE, even for the table owner | Tamper-evident accounts |
| `created_by`, `updated_by`, `updated_at` stamped by triggers | Audit and debugging |
| `tenant_id` stamped from the session on insert (`app.stamp_tenant`) and never granted to clients | Clients cannot forge it |

## Tables
| Table | Purpose | Key constraints and indexes |
|---|---|---|
| tenants | One business | `slug` unique; `status` active / suspended |
| app_users | Profile of an auth user | `lower(username)` unique; username format CHECK |
| tenant_members | Membership: role, active | `UNIQUE(user_id)` (one business per user) |
| member_permissions | Grantable staff permissions | PK `(tenant, user, permission)`; FK to member |
| business_profiles | Name, phones, address, GSTIN, bill footer, logo, locale, timezone | Phone/GSTIN format CHECKs; logo path must have tenant prefix |
| tenant_counters | Per-tenant sequences | Row lock serialises within one tenant only |
| categories | Catalogue grouping | Unique name per tenant (active only) |
| products | Designs | `upper(design_no)` unique per tenant; `text_pattern_ops` prefix index; trigram index on name; keyset index `(tenant, published_at desc, id desc)` for active products; status ⇔ `archived_at` CHECK |
| product_private | Owner-only cost, supplier, internal note | Separate table, so staff queries cannot select it |
| product_media | Image/video metadata (binaries live in Storage) | MIME allow-list; size ≤ 100 MB; sha256 dedupe per product; every path must start with `tenant_id/`; `ready` images need derivatives |
| customers | Buyers of a business | Phone format CHECK; trigram indexes on name and phone |
| customer_balances | Denormalised Baki | Changed only by `app.post_ledger` in the same transaction; reconciliation test; separate table so it can be hidden without `hisaab.view` |
| customer_product_rates | Special rate per customer and design | PK `(tenant, customer, product)` |
| orders | Confirmed orders | `UNIQUE(tenant, client_request_id)` (idempotency); `UNIQUE(tenant, order_no)`; status enum; indexes by customer, status, recency |
| order_items | Immutable line snapshot (design no, name, thumb, rate) | `amount = rate × qty` CHECK; one line per product |
| payments | Money received | `UNIQUE(tenant, client_request_id)`; `after = before − amount` CHECK; immutable |
| ledger_entries | Hisaab | Sign rules per kind (order +, payment −); one order entry per order, one reversal per entry, one opening per customer; `balance_after_paise` |
| bills | One per order; header snapshot (business, customer, totals, paid, Baki) | `UNIQUE(tenant, order_id)`; lines come from `order_items` |
| remarks | Vaat: voice / text / photo | Exactly one parent (CHECK `num_nonnulls = 1`); content CHECKs per kind |
| photo_enquiries | Photo of a wanted design | Tenant-prefixed path |
| share_assets | Every generated external file | Expiry (default 7 days) for cleanup |
| notifications | In-app inbox (delivery later) | Dedupe key unique per recipient |
| audit_logs | Who did what | Owner-read only; immutable; cost changes recorded as "changed", without values |

## Status machines
**Order:**

```
confirmed → processing → ready → completed
confirmed → ready
confirmed → completed
confirmed | processing | ready → cancelled   (writes a reversal ledger entry)
```

Allowed transitions are stored as data in `app.order_transitions`.

## Expected query paths and their indexes
| Path | Index used |
|---|---|
| Catalogue / Navo Maal page | `products_catalogue` (keyset) |
| Design number lookup | `products_design_no_prefix` |
| Name / phone search | trigram GIN indexes |
| Customer orders | `orders_by_customer` |
| Customer Hisaab | `ledger_by_customer` |
| Pending orders | `orders_by_status` (partial) |
| Customers by Baki | `customer_balances_baki` (partial) |
| Regular Maal | `order_items_regular` |

Plans were verified at 10k / 5k / 50k scale; see
[../testing/performance-results.md](../testing/performance-results.md).

## Migration rules
- Migrations are versioned files and never edited once applied to any environment.
- Use expand → migrate → contract for breaking changes.
- Every new tenant table needs: RLS, composite FKs, column grants, and
  isolation tests.
