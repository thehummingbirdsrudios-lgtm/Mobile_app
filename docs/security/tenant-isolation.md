# Tenant isolation — test catalogue

The design is in [../architecture/tenant-security.md](../architecture/tenant-security.md).
Every row below is an automated test in `backend_tests/test/tenant_isolation_test.dart`.
It runs against three near-identical tenants (same design numbers and same
customer names).

| Attempt | Expected | Result |
|---|---|---|
| A reads each of the 22 tenant tables | 0 rows of B/C | Pass |
| A looks up B's customer, product, order, bill, payment or ledger by id | 0 rows | Pass |
| Anonymous caller reads tables or RPCs | Denied (42501) | Pass |
| Authenticated user with no membership | 0 rows; RPCs `not_authenticated` | Pass |
| A calls create_order with B's customer or B's product, reorder of B's order | not-found codes | Pass |
| A records a payment or adjustment for B's customer | `customer_not_found` | Pass |
| A changes the status of, cancels or bills B's order | `order_not_found` | Pass |
| A reads B via bill_payload, share_product, reorder_preview or regular_maal | not-found or empty | Pass |
| A manages B's staff | `member_not_found` | Pass |
| A inserts with B's tenant_id | Denied | Pass |
| A's insert without tenant_id | Stamped with A | Pass |
| A updates or archives B's rows | 0 rows affected | Pass |
| A links a remark or rate to B's parents | FK violation | Pass |
| A registers media pointing to B's storage path | CHECK violation | Pass |
| A searches "1024", "Rajesh" or B's order numbers | Only A's rows | Pass |
| A lists, uploads to or deletes from B's storage prefix | Own objects only / denied / 0 deleted | Pass |
| Staff deactivated / tenant suspended | Immediate loss of access | Pass |

Release gate: this suite must be green in CI for every change.
