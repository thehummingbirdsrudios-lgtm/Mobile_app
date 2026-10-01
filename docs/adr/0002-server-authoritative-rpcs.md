# ADR-0002: Money and order writes are server-authoritative RPCs
**Status:** Accepted

**Context.** Order totals, payments and Baki must never disagree. Clients are
untrusted, and networks retry.

**Decision.**
- Orders, payments, adjustments, status changes and bills are SECURITY DEFINER
  RPCs.
- Each RPC: checks permission → takes an idempotency lock on
  `client_request_id` → validates → recomputes totals → writes the ledger,
  balance and audit in one transaction.
- No direct client writes to these tables.

**Consequences.**
- Retries are safe.
- Totals are always consistent.
- The logic lives in plpgsql, tested by `backend_tests` (including
  concurrency).
- Changes to the logic need migrations.
