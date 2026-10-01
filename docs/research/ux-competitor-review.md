# UX research — B2B jewellery catalogue apps

**Method and limitation.** This review uses only public store listings and
company websites (October 2026). The apps were **not installed or used**, so
nothing here claims how a specific screen works. Per-app UI details (quantity
controls, reorder flows, photo enquiry) must be verified hands-on with real
devices before final UI decisions; this is tracked as KI-007 in
[../testing/known-issues.md](../testing/known-issues.md).

## What public listings show

| App (from the brief or search) | Public evidence | Observation |
|---|---|---|
| Manek Ratna | Play/App Store listing, website | Positions as B2B-only (not consumer), "10,000+ designs", daily updates, categories by style (Kundan, Polki, CZ, Temple, Kemp…) and type (sets, earrings, anklets…), serves 20+ countries |
| Nivishka | Play listing `app.sellon.nivishka` | B2B app for imitation-jewellery business owners, category browsing |
| Bhagvat Imitation, Vrinda Jewels | Play listings `in.sellonapp.*` | Same white-label platform family as Nivishka (package prefix) |
| Kanhai Jewels, Siya Sales, Fancyla | Play listings | Manufacturer/wholesaler catalogue apps for retailers and resellers |
| VM, M V GOLD, JEWELACC Connect, HR Sales, RP Sales, Sadguru, Varni, Sweta, Shri Ram | Not found / not verifiable in this research pass | No claims made |

## Patterns the market converges on (from listings)
1. **Catalogue scale is the product.** Listings lead with design counts and
   daily new arrivals → Vepari needs fast, photo-first browsing and a visible
   *Navo Maal* surface (REQ-MAAL-001, REQ-MAAL-003).
2. **Style- and type-based categories** (Kundan, Polki, CZ, Temple…; sets,
   earrings, anklets…) → categories in the schema; collections deferred.
3. **B2B, not B2C.** Apps explicitly exclude end consumers → wholesale order
   sheet UX, not a consumer cart/checkout (brief §14).
4. **White-label catalogue platforms are common.** Many veparis already run a
   branded catalogue app; Vepari's differentiation is the parts those
   listings do not emphasise: **Hisaab/Baki, payments, photo bills, customer-
   specific rates, staff permissions and safe sharing**.

## Decisions taken for Vepari
| Area | Decision | Rationale |
|---|---|---|
| Discovery | Photo-first grid; design no + rate on the card; universal search | Matches catalogue-first expectations, adds design-number speed for experienced veparis |
| Ordering | Two paths: catalogue order and quick order (`1024 × 20`) | Experienced users know design numbers; browsing should not be forced |
| Reorder | Fari Order from any previous order with today's rates | Repeat orders are the most frequent B2B action |
| Quantity | Stepper + direct entry; server validates | Minimises keyboard use (brief §36) |
| Accounts | Hisaab timeline, Baki on customer rows, payment with receipt | Gap in catalogue-only apps |
| Sharing | Platform share sheet with allow-listed content | Official mechanism only; no data leakage |
| Branding | Tenant branding on bills and shares; app brand stays neutral | Each business is its own brand |

## Sources
- [Manek Ratna — Google Play](https://play.google.com/store/apps/details?id=com.manekr.ctrlplusu&hl=en)
- [Manek Ratna — App Store](https://apps.apple.com/in/app/manek-ratna/id6504612207)
- [Manek Ratna — website](https://www.manekratna.com/)
- [Nivishka — Google Play](https://play.google.com/store/apps/details?id=app.sellon.nivishka&hl=en_IN)
- [Bhagvat Imitation — Google Play](https://play.google.com/store/apps/details?id=in.sellonapp.bhagvatimitation&hl=en_IN)
- [Vrinda Jewels — Google Play](https://play.google.com/store/apps/details?id=in.sellonapp.vrindajewels&hl=en_IN)
- [Kanhai Jewels B2B — Google Play](https://play.google.com/store/apps/details?id=com.kanhaijewels&hl=en_US)
- [Siya Sales — Google Play](https://play.google.com/store/apps/details?id=com.siyasales&hl=en)
- [Fancyla Jewellery — Google Play](https://play.google.com/store/apps/details?id=com.hdtechnooworx.fancyla.jewellery&hl=en_US)
