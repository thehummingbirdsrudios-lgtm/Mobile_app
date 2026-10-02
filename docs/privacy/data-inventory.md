# Data inventory

Keep this synchronised with the schema and the privacy policy
(`docs/legal/privacy-policy.md`). Roles:
- Each **business is the data fiduciary/controller** for its customers' data.
- The platform operator processes that data on the business's behalf.

| Data | Fields | Why | Where stored | Who can access | Retention | Third parties | Deletion |
|---|---|---|---|---|---|---|---|
| Account identity | username, display name, auth id, password hash | Sign-in, attribution | Supabase Auth + `app_users` | The user; same-business members see names; operator | While the account exists | Supabase | Operator deletes the auth user (cascades the profile); history keeps the user id only |
| Membership & permissions | role, active flag, permissions | Authorisation | `tenant_members`, `member_permissions` | Owner (all); staff (own) | While the business is active | Supabase | Deactivate (kept for audit) |
| Business profile | name, phones, address, GSTIN, footer, logo | Bills, shares | `business_profiles`, `branding` bucket | Business members | Business lifetime | Supabase | Operator on business closure |
| Customer identity | name, shop, city, phone, WhatsApp, notes | Orders, accounts, contact | `customers` | Business members (notes: same) | Business lifetime; archive keeps history | Supabase | Archive; erasure on request by anonymising name/phone/notes (procedure to build — KI-008) |
| Commercial | rates, special rates, cost, supplier, internal notes | Pricing, owner decisions | `products`, `customer_product_rates`, `product_private` | Rates: members; cost/supplier: owner only | Business lifetime | Supabase | Archive |
| Transactions | orders, items, payments (amount, mode, reference), ledger, bills | Accounting | Respective tables | Orders: members; money: `hisaab.view` / `payments.record` | Business lifetime + statutory period [TBD] | Supabase | Not deletable (immutable financial history) |
| Media | product photos/videos | Catalogue | `product-media` bucket + metadata | Members | Until archived + cleanup | Supabase | Archive, then object cleanup |
| Remarks (Vaat) | text, original voice recordings, photos | Communication | `remarks`, `remarks` bucket | Members; archive by author or owner | Business lifetime | Supabase | Archive |
| Shared files | generated share images/PDFs/CSVs | WhatsApp sharing, export | Device temp folder only (the `share` bucket is closed to the app) | The app | Deleted right after the share; swept at next start if interrupted | Recipient's chosen app once shared | Automatic |
| Notifications | kind, subject id, short args (design no/name, order no, customer name; payment amount only for `hisaab.view`) | In-app inbox and push | `notifications` | The recipient | Business lifetime (no purge yet, KI-017) | Supabase; push text (no amounts) via Google FCM | Not user-deletable |
| Device push token | FCM registration token for this install | Deliver pushes | `device_tokens` (max 10 per member) | The member (own rows) | Until logout (deleted on server and phone), uninstall or FCM reports it invalid | Supabase; Google FCM | Logout; uninstall |
| Audit trail | actor, action, entity, changed fields | Security, disputes | `audit_logs` | Owner | Business lifetime [TBD] | Supabase | Not deletable |
| Device: session | Supabase session | Stay signed in | Android Keystore-backed secure storage | The app | Until logout or expiry | — | Logout; uninstall |
| Device: preference | chosen language | UX | shared_preferences | The app | Until changed or uninstall | — | Uninstall |

**Not collected:**
- location, contacts, advertising ids
- analytics or behavioural tracking
- crash reports with personal data

Push tokens are collected only after sign-in and only if the person allows
notifications (Android 13+ asks). Without one, the inbox and bell still work.
