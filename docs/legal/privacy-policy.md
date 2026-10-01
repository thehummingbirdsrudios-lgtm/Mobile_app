# Vepari — Privacy Policy (DRAFT)

> **Status: draft for qualified legal review. Not published. Not legal advice.**
> Everything in `[SQUARE BRACKETS]` is a placeholder the operator must fill in.
> This draft describes what the app does as of version 0.1.0 and must be
> updated whenever data collection changes (see docs/privacy/data-inventory.md).

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

We do **not** collect location, contacts, advertising identifiers, or analytics
about your behaviour, and the app contains no advertising.

## 3. Where information is stored

Data is stored with our hosting provider, Supabase (managed PostgreSQL database,
authentication and file storage), in [REGION — e.g. ap-south-1 Mumbai]. Data is
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
- **Service providers:** Supabase, as described above.
- **Legal requirements:** where required by law, [DESCRIBE PROCESS].

We do not sell personal information.

## 5. Retention

Business records (orders, payments, ledger, bills) are kept while the Business's
account is active, and afterwards for [PERIOD] or as required by applicable tax
and accounting law. Archived customers and products remain in historical
records so past bills stay correct. Temporary share files are deleted after
[7 DAYS].

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
