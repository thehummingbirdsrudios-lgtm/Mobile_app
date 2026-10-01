# Tenant security model

**Goal:** tenant A can never see, change, link to or infer tenant B. This is a
release blocker.

## Layers of defence
| # | Layer | Mechanism | Where |
|---|---|---|---|
| 1 | Identity | Supabase Auth JWT; `auth.uid()` is the only identity input | Supabase |
| 2 | Tenant resolution | `app.current_tenant_id()` resolves membership (active member, active tenant). SECURITY DEFINER, STABLE | `…0100_foundation.sql` |
| 3 | Row Level Security | Every tenant table: `tenant_id = (select app.current_tenant_id())`, plus permission checks per table | All migrations |
| 4 | Grants | Clients get SELECT and column-specific INSERT/UPDATE only; no DELETE on business data; `tenant_id` is never writable | All migrations |
| 5 | Tenant stamping | `app.stamp_tenant` overwrites `tenant_id` from the session on insert | `…0200` |
| 6 | Composite FKs | `(tenant_id, x_id)` references `(tenant_id, id)`, so cross-tenant links are impossible | All migrations |
| 7 | RPC discipline | DEFINER RPCs derive the tenant themselves and filter every statement by it | `…0500`, `…0600` |
| 8 | Storage | Object keys start with `tenant_id/`; policies compare the first folder with the caller's tenant; buckets are private | `…0700` |
| 9 | Path checks | Media, remark, bill, logo and share paths must start with the row's own `tenant_id` | CHECK constraints |
| 10 | Client cache | `TenantCache` is namespaced by tenant and user, and wiped on identity change or logout | `app/lib/core/storage` |
| 11 | Startup | Splash shows no data until `current_session()` succeeds | `SessionUnknown` state |

## Not-found vs forbidden
For another tenant's ids, RPCs return the same `*_not_found` as for
non-existent ids. That way the existence of B's records cannot be probed.

## Session revocation
Membership is checked on every request (layer 2). Deactivating staff or
suspending a business takes effect immediately, even while the JWT is still
valid.

## Evidence
`backend_tests/test/tenant_isolation_test.dart` covers:
- 22 tables
- direct id lookups and manipulated ids on every RPC
- forged `tenant_id`
- composite-FK linking
- storage list, upload and delete
- search
- revocation
- suspension

A mutation probe (RLS policy replaced by `true`) made 5 tests fail, which
proves they detect leaks.
