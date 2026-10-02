# Vepari — Privacy Policy

> **Status: reviewed by the operator's legal counsel (confirmed by the operator,
> 2 October 2026). Not legal advice.** Everything in `[SQUARE BRACKETS]` must be
> filled in by the operator before publication. Updated after that review, for
> counsel to confirm: push notifications through Firebase Cloud Messaging
> (sections 2 and 4), the hosting region (section 3) and how share files are
> deleted (section 5). This text describes what the app does as of version
> 0.1.0 and must be updated whenever data collection changes (see
> docs/privacy/data-inventory.md).

**Last updated:** [DATE]
**Operator:** [LEGAL ENTITY NAME], [REGISTERED ADDRESS] ("we", "us")
**Contact / Grievance Officer:** [NAME], [EMAIL], [PHONE]

## 1. Who this policy is for

Vepari is a business-to-business app used by jewellery businesses ("Businesses")
and their staff to manage catalogue, customers, orders, accounts (Hisaab),
payments and bills. Each Business decides what information it records about
its own customers. For that customer information, the Business is responsible
for it, and we process it on the Business's behalf to provide the service.

## 2. Information the app stores

| What | Examples | Why |
|---|---|---|
| Account | username, display name, role, permissions | To sign you in and control what you can see and do |
| Business profile | business name, phone, WhatsApp number, address, GSTIN (optional), logo | To show on bills and shared messages |
| Catalogue | design numbers, names, rates, weights, photos, owner-only cost/supplier notes | To run the catalogue and orders |
| Customers of the Business | name, shop name, city, phone/WhatsApp number, notes, special rates | To take orders and keep accounts |
| Transactions | orders, payments (amount, mode, reference), ledger entries, bills | To keep accurate accounts |
| Remarks | text notes, voice recordings, photos attached to orders/customers/products | Communication the user chooses to record (voice/photo features are being introduced) |
| Activity record | who changed rates, received payments, issued bills, etc. | Security and dispute resolution (visible to the Business owner) |
| On the device | your sign-in session (in the phone's secure keystore) and your chosen language | To keep you signed in and show the right language |
| Push token | a random identifier for this installation of the app, issued by Google Firebase | To deliver notifications to your phone; removed when you log out |

We do **not** collect location, contacts, advertising identifiers, or analytics
about your behaviour, and the app contains no advertising.

## 3. Where information is stored

Data is stored with our hosting provider, Supabase (managed PostgreSQL database,
authentication and file storage), in the ap-south-1 region (Mumbai, India). Data is
encrypted in transit (TLS). Each Business's data is kept separate from every
other Business by database-level access rules.

## 4. Sharing

- **Within a Business:** the owner and staff see data according to the
  permissions the owner gives them. Cost, supplier and internal notes are
  visible only to the owner.
- **WhatsApp and other apps:** when you tap Share, the app prepares a message,
  image or PDF containing only customer-safe information (for example design
  number, photo and rate) and hands it to the app you pick using your phone's
  share sheet. We do not send messages on your behalf and do not read WhatsApp.
- **Service providers:** Supabase, as described above, and Google Firebase
  Cloud Messaging, which delivers notifications to your phone. For that it
  receives your phone's push token and the short notification text (for
  example a design number and name, an order number or a customer name).
  Amounts are never included. You can turn notifications off in your phone's
  settings; the app keeps working and shows them inside the app.
- **Legal requirements:** where required by law, [DESCRIBE PROCESS].

We do not sell personal information.

## 5. Retention

Business records (orders, payments, ledger, bills) are kept while the Business's
account is active, and afterwards for [PERIOD] or as required by applicable tax
and accounting law. Archived customers and products remain in historical
records so past bills stay correct. Files you share (bills, receipts, photos)
are prepared on your phone and deleted right after sharing (or at the next app
start if sharing was interrupted); no copy is kept on our servers.

## 6. Your choices and rights

Subject to applicable law (including India's Digital Personal Data Protection
Act, 2023), individuals may request access, correction or erasure of their
personal data, or raise a grievance, by contacting the Grievance Officer above.
Customers of a Business should usually contact that Business first.

## 7. Security

Passwords are handled by our authentication provider and never stored in plain
text. Sessions are stored in the device's secure keystore and are cleared on
logout. Access is checked on the server for every request.

## 8. Children

Vepari is a business tool and is not intended for children.

## 9. Changes

We will update this policy when the app's data use changes and show the new
version in the app.
