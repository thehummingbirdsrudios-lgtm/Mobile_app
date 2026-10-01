# ADR-0004: Money as integer paise
**Status:** Accepted

**Decision.**
- `bigint` paise in SQL and `Money(int paise)` in Dart.
- No floating point anywhere.
- Rates are per piece. Totals are capped at ₹10,000 crore so they can never
  overflow.

**Consequences.**
- Exact arithmetic.
- Formatting (Indian grouping, paise only when non-zero) is centralised in
  `Money.format`.
