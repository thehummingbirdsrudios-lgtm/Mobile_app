# Screen inventory

"Main job" is the one thing the user came to do. States: L = loading,
E = empty, X = error, S = success feedback.

| Screen | Main job | States | Owner/staff difference | Status |
|---|---|---|---|---|
| Splash | Verify identity safely | brand only | — | Built |
| Login | Get in | inline validation, X (plain message), not-configured banner | — | Built |
| Home | Understand today in seconds | L skeleton stats, X + retry, quick actions | Stats need `reports.view` | Built |
| Maal (catalogue) | Find a design and its rate | L skeleton cards, E "Haju maal nathi", X | Edit/archive needs `catalogue.manage` | Placeholder |
| Product detail | Check design, rate, photos; order/share | L image + content skeleton, X | Cost visible to owner only | Planned |
| Search | Find anything by number/name/phone | compact L, E, X | Results are already RLS-scoped | Planned |
| Order (sheet) | Build and place an order | button L→S, `rate_changed` re-confirm, unsaved guard | `orders.create` | Planned |
| Quick order | Type `1024 × 20` lines | same as order | same | Planned |
| Order history/detail | See status, Fari Order, bill | L, E, X | Status change needs `orders.manage` | Planned |
| Customer list | Find a customer, see Baki | L, E "Haju koi customer nathi", X | Baki needs `hisaab.view` | Placeholder |
| Customer profile | Baki, order, payment, Hisaab, Regular Maal, Vaat | L, X | — | Planned |
| Hisaab | Read a customer's ledger | L, E "Haju koi hisaab nathi" | `hisaab.view` | Placeholder |
| Payment | Receive a payment | button L→S with old/new Baki | `payments.record` | Planned |
| Bill | Generate and send a photo bill | progress, S "Bill ready", X | `bills.issue` | Planned |
| Navo Maal | See and share new designs | L, E "Aaje navo maal nathi" | — | Planned |
| Vaat (remark) | Voice / text / photo note | recording states, permission flow | — | Planned |
| More | Profile, language, legal, logout | — | Owner sections later | Built |
| Legal | Read privacy policy or terms | L skeleton, X | — | Built |
| Owner settings | Business, users, rates, bills, branding, security, export | per section | Owner only | Planned |
