# ADR-0003: Shared schema, RLS and composite foreign keys for multi-tenancy
**Status:** Accepted

**Options.**
1. Shared tables with `tenant_id` and RLS.
2. A schema per tenant.
3. A database per tenant.

**Decision.** Option 1, hardened in three ways:
- the tenant is resolved from the JWT only;
- composite `(tenant_id, id)` FKs;
- column-level grants and tenant stamping.

**Consequences.**
- One migration path for all tenants.
- Cheap at our scale.
- Isolation depends on discipline, so every table needs isolation tests (a CI
  release gate).
