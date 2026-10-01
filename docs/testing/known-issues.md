# Known issues and limitations

| ID | Severity | Issue | Impact | Status / next action |
|---|---|---|---|---|
| KI-001 | High (release blocker for production) | Catalogue, customers, orders, Hisaab, payments, bills, Vaat and WhatsApp **UI not built yet**. Backend RPCs exist and are tested. | The app cannot run a business yet | Increments 1–10 in the implementation plan |
| KI-002 | High | Staff/owner account provisioning Edge Function not built; accounts can only be created by the operator with SQL / admin API | Owners cannot add staff themselves | Increment 1 |
| KI-003 | Medium | No device testing (API 24 low-end, mid-range, tablet); Android build verified only in CI | Unknown device-specific issues | Device QA in the hardening increments |
| KI-004 | Medium | Hosted Supabase project not created or configured (signups off, JWT expiry, region, backups, PITR) | Backup/restore not proven | Before the first pilot; restore drill required |
| KI-005 | Medium | No malware scanning of uploads | Risk from malicious files uploaded by authenticated staff | Evaluate with the media increment |
| KI-006 | Low | On web, the 👋 emoji needs Google's emoji font CDN; it shows as a box offline or in restricted networks. Android uses system emoji. | Cosmetic on web only | Bundle an emoji subset if web becomes a target |
| KI-007 | Medium | UX research used public listings only; competitor apps not used hands-on; no user testing yet | UX assumptions unvalidated | Hands-on review + 3–5 vepari sessions before the order UI |
| KI-008 | Medium | Personal-data erasure procedure (anonymise a customer while keeping financial history) not implemented | DPDP request handling is manual | Design with the customer increment |
| KI-009 | Low | No automated dependency CVE scan (pub has no built-in audit) | Vulnerable transitive dependencies could go unnoticed | Add OSV-Scanner to CI |
| KI-010 | Low | Release build uses R8 shrinking but has never been built or run | Possible missing keep rules | Build and smoke-test a release APK in CI or on a device |
| KI-011 | Low | Notifications, version gate and maintenance mode designed but not built | — | Increments 12–13 |
