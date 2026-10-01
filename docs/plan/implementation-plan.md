# Implementation plan

Every increment follows the same pipeline:

```
requirement → acceptance criteria → design → implement → tests → build →
manual check → review → merge
```

Each increment ships with DB tests for every new table or RPC (isolation
included) and app tests for its states.

## Done — Increment 0: foundation (this PR)
- Schema, RLS, money RPCs, DB test-suite including scale.
- App core: design, motion, errors, ApiClient, logger, cache.
- Auth (login and session), Home dashboard, shell and navigation, settings
  (language and legal).
- Brand and CI.

## Next increments (ordered by dependency and risk)

**1. Staff and account provisioning.**
- Edge Function: owner creates staff.
- Owner "Users" screen: permissions, deactivate.
- Tests: function auth, duplicate username, escalation attempts.

**2. Catalogue and media.**
- Product grid (`catalogue_page`, keyset) and product detail with Hero.
- Owner add/edit/archive.
- Media upload job module (isolate derivatives, resumable, finalise RPC),
  signed URLs, cleanup job.
- Tests: 10k grid scroll profiling, corrupt/oversized images, wrong-tenant paths.

**3. Universal search.**
- `search_all` UI with debounce, grouped results and recent searches.

**4. Customers.**
- List sorted by Baki, profile, add/edit/archive, special rates, Regular Maal.

**5. Order.**
- Catalogue order and quick order (`1024 × 20`).
- Local draft (tenant-scoped).
- Submit with `client_request_id`; `rate_changed` re-confirm.
- Success state.

**6. Hisaab and payment.**
- Ledger timeline (keyset), payment sheet (modes, amount keypad), receipt with
  old/new Baki.

**7. Bills.**
- `issue_bill`, PDF in an isolate with thumbnails, stored in the `bills` bucket.

**8. Vaat.**
- Voice (record → preview → send), text, photo.
- Permission flows (explain → request → denied → settings).
- Photo enquiries.

**9. WhatsApp safe share.**
- Product, Navo Maal, order, bill, receipt, Hisaab via the share sheet.
- Fallbacks; never claim "sent".

**10. Navo Maal and Fari Order UI.**
- Built on the existing RPCs.

**11. Owner admin.**
- Business profile, branding/watermark, rates, bills, security, export
  (audited).

**12. Notifications.**
- FCM, channels, deep links with server re-authorisation, preferences.

**13. Version gate and maintenance mode.**
- Minimum version, maintenance message.

**14. Performance hardening.**
- Profile on a low-end device, image memory, startup.

**15. Security hardening.**
- Hosted project checklist, dependency audit, penetration-style review.

**16. Full QA.**
- Devices, languages, network failure matrix, backup/restore drill, final report.

## Definition of Ready
- Requirement IDs exist.
- Acceptance criteria are written.
- Screens are listed in the screen inventory.
- Any new tables or RPCs are designed in data-model.md / api.md.

## Definition of Done
- Acceptance criteria are covered by tests.
- Format, analyze, boundaries, app tests and DB tests (with isolation) are
  green in CI.
- The screen has been visually checked in gu/hi/en at 320 / 360 / tablet.
- Docs, CHANGELOG and known-issues are updated.
- No fake data or fake success.
