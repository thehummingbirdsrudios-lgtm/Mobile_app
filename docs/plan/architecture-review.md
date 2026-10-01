# Architecture review (Phase 6 self-review)

| Question | Answer | Evidence / follow-up |
|---|---|---|
| Is this simpler than ERP software? | Six tabs, one main job per screen, contextual actions, a dashboard with four numbers and four quick actions | screen-inventory.md |
| Would a first-time vepari understand it? | Vepari vocabulary in native scripts; login has only username and password | Needs hands-on usability testing (KI-007) |
| Can the owner reach everything? | Home drill-downs, the More hub, and search (planned) | Owner settings in increment 11 |
| Can one tenant escape into another? | Not through any path tested: tables, RPCs, ids, search, storage, revocation | tenant_isolation_test plus mutation probe |
| Are the core relationships correct? | Composite FKs, snapshots, immutable history, CHECKs | data-model.md |
| What happens with 10,000 products? | Keyset catalogue ≈2 ms; trigram search ≈20–28 ms client-observed | performance-results.md |
| Thousands of photos? | Thumbnails only in lists; derivatives created once; signed and cached | media-architecture.md (increment 2) |
| Can money totals ever disagree? | Server recomputes; `amount = rate × qty` CHECK; balance reconciled with the ledger | Property test, reconciliation test |
| Can confidential data leave via WhatsApp? | Only allow-listed RPC payloads; secrets seeded in tests | authorization_privacy "safe share" |
| What if the network fails? | Typed failures, retry buttons, idempotent writes, splash never shows stale data | api_client_test, session tests |
| Can we add a staff app or white-label later? | The permission model is server-side; modules are replaceable behind ports | modules.md |

**Risks accepted for now:**
- Client-side image derivatives (ADR-0006).
- No malware scanning (KI-005).
- No offline write queue: drafts are local only.
