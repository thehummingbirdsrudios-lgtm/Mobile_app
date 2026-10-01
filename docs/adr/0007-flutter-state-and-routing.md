# ADR-0007: Riverpod (no codegen) and go_router
**Status:** Accepted

**Decision.**
- **State:** one state-management approach, Riverpod `Notifier` /
  `FutureProvider`. Providers are also the dependency-injection seam: ports are
  overridden in `main.dart` and in tests.
- **Routing:** go_router with a session-aware `redirect` and a
  `StatefulShellRoute` for tabs.
- **No codegen:** keeps the build simple.

**Consequences.**
- Testable without a backend.
- Server state, session state and UI state stay clearly separated.
