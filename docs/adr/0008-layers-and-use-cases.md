# ADR-0008: Feature modules with enforced boundaries; use cases only where logic exists
**Status:** Accepted

**Decision.**
- Each feature follows `presentation → application → domain ← data
  (local | remote | repositories)`.
- There is one public barrel per module.
- Rules R1–R5 are enforced by `tool/check_boundaries.dart` in CI.
- Use-case classes are introduced only for real business orchestration (for
  example, composing an order with a rate-change re-confirmation). Thin
  pass-throughs (fetch dashboard) go controller → repository.

**Consequences.**
- Clear ownership and replaceable data sources, without empty layers.
- Reviewers check new abstractions against this rule.
