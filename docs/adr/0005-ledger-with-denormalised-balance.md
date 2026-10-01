# ADR-0005: Append-only ledger with a denormalised balance
**Status:** Accepted

**Context.** Hisaab must be auditable, and Baki lists and the dashboard must be
fast.

**Decision.**
- `ledger_entries` is append-only and immutable (enforced by triggers).
- `customer_balances.balance_paise` changes only inside `app.post_ledger`, in
  the same transaction, under the balance row lock.
- Corrections are new entries (reversal or adjustment), never edits.
- Orders cannot be edited after confirmation: cancel plus Fari Order instead.

**Consequences.**
- O(1) Baki reads.
- A reconciliation test asserts that `balance = Σ ledger` for every customer.
- A property test checks it over 150 random operations.
