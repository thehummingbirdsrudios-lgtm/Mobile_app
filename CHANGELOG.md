# Changelog

All notable changes are documented here ([Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
[SemVer](https://semver.org/)).

## [Unreleased]

### Added
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
