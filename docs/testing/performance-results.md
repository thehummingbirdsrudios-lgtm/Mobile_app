# Performance results

## Database at production-like scale
**Command:** `tool/db_test.sh --scale` (`backend_tests/test/scale_perf_test.dart`)

**Environment:** local PostgreSQL 16.14 on a 4-vCPU / 15 GB container, default
settings plus `shared_buffers=256MB`. Measurements run **as an authenticated
owner with RLS active**.

**Data:**

| | Products | Customers | Orders | Order items | Ledger entries | Product media |
|---|---|---|---|---|---|---|
| Tenant A (measured) | 10,000 | 5,000 | 50,000 | 150,000 | — | — |
| Total, 3 tenants | 16,015 | 7,006 | 70,000 | 210,000 | 70,000 | 16,018 |

**Data load:** 17 s.

| Path | Measure | ms | Seq scans on large tables |
|---|---|---:|---|
| Catalogue first page | EXPLAIN ANALYZE | 2.03 | none |
| Catalogue deep keyset page | EXPLAIN ANALYZE | 2.32 | none |
| Navo Maal (last 7 days) | EXPLAIN ANALYZE | 0.77 | none |
| Product detail | EXPLAIN ANALYZE | 0.30 | none |
| Customers sorted by Baki | EXPLAIN ANALYZE | 1.71 | none |
| Customer Hisaab (latest 50) | EXPLAIN ANALYZE | 0.83 | none |
| Customer orders (latest 20) | EXPLAIN ANALYZE | 0.46 | none |
| Pending orders | EXPLAIN ANALYZE | 0.32 | none |
| Regular Maal | EXPLAIN ANALYZE | 9.36 | none |
| search_all: design number | median of 7 client calls | 20.52 | n/a |
| search_all: design name | median of 7 client calls | 27.82 | n/a |
| search_all: customer name | median of 7 client calls | 24.17 | n/a |
| search_all: phone digits | median of 7 client calls | 28.37 | n/a |
| dashboard_summary | median of 7 client calls | 24.90 | n/a |
| create_order (3 lines) | median of 7 client calls | 16.01 | n/a |
| record_payment | median of 7 client calls | 9.99 | n/a |

Client-call figures include about 5 ms of per-request overhead from the test
harness (a transaction, `SET ROLE` and setting the claims), which mirrors
PostgREST.

### Finding fixed during measurement
`catalogue_page` first measured **61 ms**. Its `SET search_path` clause
stopped Postgres from inlining the SQL function, so the planner could not use
the keyset index through the parameters.

Removing the clause from the SECURITY INVOKER read functions (names are fully
qualified and RLS still applies) brought it to **2–3 ms**. It also made their
plans visible to the seq-scan check.

## Re-run 2026-10-02 (after increments 11–16)
Same data and environment. New this run:
- The notification triggers fire during the bulk load, so the data load rose
  from 17 s to about 70 s (the load is followed by `VACUUM (ANALYZE)`, as autovacuum would do).
- Every seeded design notifies 3 members and every order 2 (owner + order manager):
  about 190k notification rows across the three tenants (16k × 3 + 70k × 2).
- Plans were added for the inbox, the unread count (busy owner, and a member
  with nothing unread) and an export page.
- One run without the vacuum showed the unread count flipping to a seq scan:
  without a visibility map, index-only scans look expensive. It is now
  stable over repeated runs (R-026).

| Path | Measure | ms | Seq scans on large tables |
|---|---|---:|---|
| Catalogue first page | EXPLAIN ANALYZE | 2.65 | none |
| Catalogue deep keyset page | EXPLAIN ANALYZE | 2.91 | none |
| Navo Maal (last 7 days) | EXPLAIN ANALYZE | 1.17 | none |
| Product detail | EXPLAIN ANALYZE | 0.35 | none |
| Customers sorted by Baki | EXPLAIN ANALYZE | 1.82 | none |
| Customer Hisaab (latest 50) | EXPLAIN ANALYZE | 0.74 | none |
| Customer orders (latest 20) | EXPLAIN ANALYZE | 0.54 | none |
| Pending orders | EXPLAIN ANALYZE | 0.42 | none |
| Regular Maal | EXPLAIN ANALYZE | 14.73 | none |
| Export: Hisaab entries, one month page | EXPLAIN ANALYZE | 1.39 | none |
| Notification inbox (latest 30) | EXPLAIN ANALYZE | 0.66 | none |
| Unread count, member with nothing unread | EXPLAIN ANALYZE | 0.34 | none |
| Unread notification count (capped) | EXPLAIN ANALYZE | 0.63 | none |
| search_all: design number | median of 7 client calls | 28.14 | n/a |
| search_all: design name | median of 7 client calls | 29.60 | n/a |
| search_all: customer name | median of 7 client calls | 26.72 | n/a |
| search_all: phone digits | median of 7 client calls | 25.91 | n/a |
| dashboard_summary | median of 7 client calls | 13.65 | n/a |
| create_order (3 lines) | median of 7 client calls | 19.86 | n/a |
| record_payment | median of 7 client calls | 10.25 | n/a |

All hot paths stay index-only. Client-call figures vary run to run on this
shared container (±50%), and Regular Maal varied the same way with no code
change. Budgets are unchanged.

### Regression gate
- CI runs the same suite.
- Latency budgets are 50 ms for plans and 100–150 ms for RPCs, multiplied by
  `VEPARI_PERF_BUDGET_FACTOR=4` on shared runners.
- The "no sequential scan on large tables" assertion is strict everywhere.

## App
**Bill PDF with product photos** (unit-measured, `bill_pdf_test.dart`):
- Size:
  - 25 lines: about 78 KB.
  - 100 lines over 9 pages: about 270 KB.
- Worst case per embedded photo: 49 / 30 / 17 KB at the 64 / 56 / 48 pt tiers.
- At most 3 photo downloads run in flight.

Not yet measured on devices. Planned for the catalogue increment and the
hardening increment:
- startup time
- catalogue scroll frame times with 10k items
- image memory
- measured with Flutter DevTools on a low-end Android device (2–3 GB RAM, API 24–26)
