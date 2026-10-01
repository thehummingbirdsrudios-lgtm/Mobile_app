# Software Requirements Specification — Vepari

Version 0.1 · 2026-10-01 · Status: baseline for increment 1 (foundation)

Requirement IDs are stable; trace them through
[acceptance-criteria.md](acceptance-criteria.md) → code → tests
([../testing/test-matrix.md](../testing/test-matrix.md)).
Status: **Built** (implemented + tested), **Partial**, **Planned** (later increment, see
[../plan/implementation-plan.md](../plan/implementation-plan.md)).

## 1. Purpose and scope
An online-first B2B application for Indian imitation-jewellery wholesalers and
retailers (veparis). Core jobs: *Maal jovo, Rate jovo, Order karo, Fari order,
Customer jovo, Hisaab jovo, Payment lo, Bill moklo, WhatsApp karo.* Not a
consumer marketplace. ~5 independent businesses (tenants) initially.

## 2. Users and roles
| Role | Description |
|---|---|
| Owner | Full control of one business: data, staff, settings, cost/supplier data, audit log |
| Staff | Belongs to exactly one business; capabilities granted by the owner |
| Customer of a business | Does not use the app; receives shared content via WhatsApp |
| Platform operator | Provisions businesses and owner accounts (service role) |

## 3. Functional requirements

### Tenancy & security (TEN)
| ID | Requirement | Status |
|---|---|---|
| REQ-TEN-001 | Each business's data is private; no other tenant can read, infer, link to or modify it via UI, API, IDs, search, files, URLs or notifications | Built (DB) |
| REQ-TEN-002 | Tenant is resolved server-side from the authenticated identity; client-supplied tenant ids are never trusted | Built |
| REQ-TEN-003 | Disabled staff and suspended businesses lose access immediately | Built |
| REQ-TEN-004 | Local caches are tenant-scoped and cleared on logout/account switch; no stale data shown before identity is verified | Built |

### Authentication & staff (AUTH)
| ID | Requirement | Status |
|---|---|---|
| REQ-AUTH-001 | Login with username + password; no public signup, no Google signup | Built (client) |
| REQ-AUTH-002 | Accounts created by owner/operator; passwords never stored in plain text | Partial (DB + provisioning RPC; Edge Function planned) |
| REQ-AUTH-003 | Owner grants/revokes staff permissions; server enforces them | Built (DB) / Planned (UI) |
| REQ-AUTH-004 | Session stored in platform keystore; logout clears session and cache | Built |

### Catalogue (MAAL)
| ID | Requirement | Status |
|---|---|---|
| REQ-MAAL-001 | Photo-first catalogue with design no, name, rate, availability; keyset pagination | Built (DB) / Planned (UI) |
| REQ-MAAL-002 | Product detail with multiple images / optional video | Partial (schema) |
| REQ-MAAL-003 | Navo Maal: recently published designs | Built (DB) / Planned (UI) |
| REQ-MAAL-004 | Archive (never delete) designs; history unaffected | Built |
| REQ-MAAL-005 | Owner-only cost/supplier/internal notes | Built |

### Search (SRCH)
| ID | Requirement | Status |
|---|---|---|
| REQ-SRCH-001 | One search box for design no/name, customer name/phone, order no | Built (DB) / Planned (UI) |
| REQ-SRCH-002 | Indexed, bounded, debounced; no full-table scans | Built (DB) |

### Customers & rates (CUST, RATE)
| ID | Requirement | Status |
|---|---|---|
| REQ-CUST-001 | Customer profile: Baki, orders, Hisaab, Regular Maal, Vaat, WhatsApp | Partial (DB) |
| REQ-CUST-002 | Regular Maal list per customer | Built (DB) |
| REQ-CUST-003 | Archive customers without breaking history | Built |
| REQ-RATE-001 | Effective rate = customer-specific override else product rate | Built |
| REQ-RATE-002 | Rate changes are permissioned and audited | Built |

### Orders (ORD)
| ID | Requirement | Status |
|---|---|---|
| REQ-ORD-001 | Catalogue order and quick order (design × qty) | Built (DB) / Planned (UI) |
| REQ-ORD-002 | Server recomputes all totals; client totals never accepted | Built |
| REQ-ORD-003 | Duplicate submissions/retries never create a second order | Built |
| REQ-ORD-004 | If a rate changed since the draft, the order is rejected with new rates for re-confirmation | Built |
| REQ-ORD-005 | Confirmed orders preserve historical rate/name/photo | Built |
| REQ-ORD-006 | Valid status transitions only (confirmed→processing→ready→completed; cancel before completion reverses Baki) | Built |
| REQ-ORD-007 | Fari Order: reorder whole/partial previous order with today's rates | Built (DB) / Planned (UI) |
| REQ-ORD-008 | Archived/unavailable designs and archived customers cannot be ordered | Built |

### Hisaab & payments (HSB, PAY)
| ID | Requirement | Status |
|---|---|---|
| REQ-HSB-001 | Append-only ledger; Baki always equals the sum of ledger entries | Built |
| REQ-HSB-002 | Opening balance once; adjustments require a note | Built |
| REQ-PAY-001 | Payment (cash/UPI/bank/cheque) recorded exactly once with old/new Baki | Built |
| REQ-PAY-002 | Payment with order is atomic with the order | Built |

### Bills & sharing (BILL, SHARE)
| ID | Requirement | Status |
|---|---|---|
| REQ-BILL-001 | Bill issued from the authoritative order, one per order, idempotent | Built (DB) |
| REQ-BILL-002 | Photo bill PDF readable on phone, shareable | Planned |
| REQ-SHARE-001 | Every external share passes a privacy filter (allow-listed fields only) | Built (DB) |
| REQ-SHARE-002 | WhatsApp via platform share; never claim "sent" when only prepared | Planned |

### Communication (VAAT)
| ID | Requirement | Status |
|---|---|---|
| REQ-VAAT-001 | Voice / Text / Photo remarks on customer, order, product, enquiry; original voice stored | Partial (schema) |

### Owner (OWN)
| ID | Requirement | Status |
|---|---|---|
| REQ-OWN-001 | Dashboard: today's sale, payments, total Baki, pending orders; drill-down | Built |
| REQ-OWN-002 | Settings in few sections with progressive disclosure | Partial (language, legal) |
| REQ-OWN-003 | Audit log of sensitive actions, owner-only | Built (DB) |

### UX (UX)
| ID | Requirement | Status |
|---|---|---|
| REQ-UX-001 | Primary navigation: Home, Maal, Order, Customer, Hisaab, More | Built |
| REQ-UX-002 | Every async surface has loading, empty, error and success states | Built for current screens |
| REQ-UX-003 | Buttons show pressed/loading/success/disabled and block double taps | Built |
| REQ-UX-004 | Correct Back: keyboard → sheet → route; tabs return to Home first | Built |
| REQ-UX-005 | Gujarati, Hindi, English; no hard-coded UI strings | Built |
| REQ-UX-006 | Phone and tablet/desktop layouts from one design system | Built (shell) |

## 4. Non-functional requirements
| ID | Requirement | Target / evidence |
|---|---|---|
| NFR-PERF-001 | Hot queries index-only at 10k products / 5k customers / 50k orders | No seq scans; catalogue ≈2 ms (docs/testing/performance-results.md) |
| NFR-PERF-002 | Order/payment RPC latency | create_order ≈16–20 ms, record_payment ≈8–10 ms (local) |
| NFR-PERF-003 | No full-resolution images in lists; thumbnails only | Planned (media increment) |
| NFR-SEC-001 | No secrets in client; TLS only; least privilege | Built |
| NFR-REL-001 | No duplicate financial records under retry/concurrency | Built + tested |
| NFR-A11Y-001 | WCAG 2.2 AA contrast, 48 dp targets, semantic labels, reduced motion | Built for current screens |
| NFR-COMP-001 | Android 7.0 (API 24)+; low-end devices supported | Configured; device testing pending |
| NFR-I18N-001 | Locale-aware dates/currency; Indian digit grouping | Built |
| NFR-PRIV-001 | Data minimisation; inventory and policies maintained | Built (docs) |

## 5. Constraints
Small team, cost-conscious hosting (Supabase), Android-first, online-first
(no offline sync engine), official WhatsApp mechanisms only.
