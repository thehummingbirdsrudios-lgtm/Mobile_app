# Changelog

All notable changes are documented here ([Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
[SemVer](https://semver.org/)).

## [Unreleased]

### Added (increments 11–16, 2026-10-02)
- Owner admin: business details (with logo), staff logins and permissions,
  stop/restore access, new passwords, readable activity log.
- `staff-admin` Edge Function (create staff, reset password) with
  service-role-only provisioning RPCs; `push-dispatch` Edge Function (FCM v1).
- Notifications: in-app inbox and unread bell; fan-out for new designs,
  orders, status changes and payments; device tokens.
- Owner CSV export: customers + Baki, designs with cost, Hisaab, orders,
  order lines (Excel-ready UTF-8, formula-injection safe).
- Version gate and maintenance mode (writes paused, reads continue).
- CI: Edge Functions job, release APK build, OSV dependency scan.

### Security (increments 11–16)
- `share` bucket closed to app users; photo originals restricted to the
  owner and catalogue managers; share temp files deleted after sharing.
- Inbox re-checks Hisaab permission before showing payment amounts.

### Fixed (increments 11–16)
- Forms validate fields scrolled off-screen (lazy lists skipped them).
- Audit log records what a delete removed; rate changes read correctly in
  Gujarati/Hindi.

### Added (foundation and increments 1–10)
- Multi-tenant Supabase schema with RLS on every table, composite tenant
  foreign keys, column-level grants and tenant-scoped storage policies.
- Server-authoritative RPCs: `create_order`, `record_payment`,
  `record_adjustment`, `transition_order`, `cancel_order`, `issue_bill`,
  staff permission management, `current_session`, and read RPCs
  (`search_all`, `catalogue_page`, `regular_maal`, `reorder_preview`,
  `share_product`, `bill_payload`, `dashboard_summary`).
- Database test-suite (115 tests incl. scale) via a Supabase-compatible shim.
- Flutter app foundation: design system, motion system, error model, API
  client, structured logging, tenant-scoped cache, login, protected splash,
  Home dashboard, adaptive navigation shell, language selection (gu/hi/en),
  legal screens; module-boundary checker.
- Vepari brand mark and launcher/web icons.
- CI for app, database and secret scanning.

### Security
- `create_order` replay returns a payment only to callers with
  `payments.record` or `hisaab.view`. `client_request_id` is no longer
  readable by clients (found by security review; regression-tested).

### Fixed (from code review, before first release)
- `create_order` requires `payments.record` to take a payment; it resolves
  rates once per line; a replay returns its payment.
- Storage: bill PDFs need `bills.issue` / `hisaab.view`; objects cannot be
  moved across buckets.
- Opening-balance race returns `opening_exists`.
- The app signs out when the server rejects the session. Error
  classification fixed for SQLSTATE vs HTTP codes and GoTrue codes.
- Android application id `com.thehummingbirdstudio.vepari` (`in.*` is invalid).
- Success colour contrast raised to AA.
