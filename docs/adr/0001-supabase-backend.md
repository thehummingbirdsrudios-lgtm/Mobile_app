# ADR-0001: Supabase as the backend
**Status:** Accepted (2026-10-01)

**Context.** We need a relational database, row-level tenant isolation, auth,
private file storage, and low operating cost and effort for a small team serving
about 5 businesses.

**Options.**
1. Supabase (managed Postgres + RLS + Auth + Storage + Edge Functions).
2. A custom Dart server with Postgres.
3. Firebase.

**Decision.** Supabase (chosen by the user).

**Consequences.**
- The API is PostgREST plus Postgres RPCs, so business rules live in SQL and
  are tested against real Postgres.
- We avoid running servers, at the cost of some coupling to Supabase
  conventions (`auth.uid()`, Storage policies). That coupling is isolated in
  the data layer and the migrations.
- Firebase was rejected: it has no relational integrity or RLS-equivalent row
  isolation for financial records.
