# Assumptions and open questions (defaults chosen)

| # | Assumption / question | Default taken | Revisit when |
|---|---|---|---|
| A1 | Backend platform | Supabase (user decision) | — |
| A2 | Product/app name | "Vepari" (working name), app id `com.thehummingbirdstudio.vepari` (`in.*` is invalid: `in` is a Java keyword) | Before store listing |
| A3 | A user belongs to exactly one business | Enforced by `UNIQUE(user_id)` | A multi-business user is requested |
| A4 | Login identity | Username mapped to a never-emailed identifier `<username>@login.vepari.invalid` | Supabase changes email validation |
| A5 | Prices | Per piece, INR, integer paise; no GST computation yet (GSTIN shown if configured) | Tax rules are specified by the businesses |
| A6 | Quantities | Whole pieces, 1–1,00,000 per line, ≤200 lines | Weight-based selling is needed |
| A7 | Rate changed after draft | Reject with `rate_changed`, user re-confirms | — |
| A8 | Order edit after confirmation | Not allowed: cancel + Fari Order (keeps ledger simple and auditable) | Owners ask for in-place edits |
| A9 | Bill "Paid" | Payments recorded against that order; "Baki" = customer balance at issue | Payment allocation is required |
| A10 | Cancelling an order with money received | Money stays as customer credit (visible in Hisaab) | Refund flow needed |
| A11 | Gujarati/Hindi UI | Native scripts; English UI uses vepari vocabulary (Maal, Baki, Hisaab) | User testing feedback |
| A12 | Navigation | Six tabs as specified; verified to fit at 320 dp in all languages | Usability testing shows crowding |
| A13 | Minimum Android | API 24 (Android 7.0) | Plugin requirements change |
| A14 | Image derivatives | Generated on device in an isolate at upload | Cost/quality data suggests server-side |
| A15 | Hosting region | To be chosen (recommend ap-south-1, Mumbai) | Project creation |
| A16 | Legal entity, grievance officer | Placeholders in legal drafts | Before publication |
