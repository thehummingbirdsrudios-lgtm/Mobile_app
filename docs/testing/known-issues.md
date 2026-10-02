# Known issues and limitations

Last reviewed 2026-10-02, after increments 1–16. Each closed item names the
change that closed it; open items say what would close them.

## Open

| ID | Severity | Issue | Impact | Next action |
|---|---|---|---|---|
| KI-003 | Medium | No device testing yet (API 24 low-end, mid-range, tablet). The Android debug and release (R8) APKs are built in CI, but they have not been installed or run. | Device-specific issues are unknown: camera, mic, share sheet, keystore and fonts on real phones | Pilot device QA: install the release APK on 3 phones and run the regression suite by hand |
| KI-004 | Medium | No hosted Supabase project has been created or configured: signups off, JWT expiry, region, backups, PITR. | Backup and restore are not proven | Before the first pilot; a restore drill is required |
| KI-005 | Medium | Uploads are not scanned for malware. Images are re-encoded on the device, and originals are stored as uploaded. | Risk from malicious files uploaded by authenticated staff | Originals are now readable only by the owner and catalogue managers (KI-012 fix). Evaluate a scanning hook before opening uploads wider. |
| KI-006 | Low | On web, the 👋 emoji needs Google's emoji font CDN. It shows as a box offline. Android uses system emoji. A scan of every UI string against the bundled Hind fonts found no other missing glyph. | Cosmetic, web only | Bundle an emoji subset if web becomes a target |
| KI-007 | Medium | UX research used public listings only, and no user testing has been done | UX assumptions are unvalidated | 3–5 vepari sessions with the pilot build |
| KI-008 | Medium | There is no procedure for personal-data erasure (anonymise a customer while keeping financial history) | DPDP requests are handled manually | Design an anonymise-customer RPC (name, phones, notes, remarks), keeping ledger amounts |
| KI-013 | Medium | The push client is not wired: `firebase_messaging` and `google-services.json` need the business's own Firebase project. The server side (`push-dispatch` and device tokens) is built and tested, and the app has the `PushTokenSource` seam. | Notifications appear only in the in-app inbox and bell | Create the Firebase project, add the plugin behind `PushTokenSource`, set `FCM_SERVICE_ACCOUNT` and add the Database Webhook |
| KI-014 | Medium | The Edge Functions (`staff-admin`, `push-dispatch`) and the Database Webhook have not been deployed to a hosted project. The Supabase Auth admin error codes are mapped from the documentation and have not been exercised live. | Account creation and push are unproven end to end | After KI-004: deploy, then create a staff login, reset a password, and send a push on a real device |
| KI-015 | Low | Resetting a staff password does not end that person's existing sessions; the Auth admin API has no per-user revoke. Turning **access off** does take effect immediately on their next request. | A compromised staff password stays usable on an already signed-in phone until access is turned off | The UI tells owners to turn access off for a lost phone. Add this to the owner help text. |
| KI-016 | Low | Maintenance mode pauses business data writes (orders, payments, customers, designs, members and others). It does not pause storage uploads, device-token registration or marking notifications read. | A photo uploaded during maintenance can be left without its design row | Fine for short maintenance windows; add storage to the pause if longer windows are needed |
| KI-017 | Low | Notifications are never purged | The table grows by a few rows per event. Reads stay index-only: under 1 ms with about 190k rows. | Add a retention job (for example, delete read notifications older than 90 days) |
| KI-018 | Low | The OSV scan covers the Dart lockfiles (161 + 51 packages, no known vulnerabilities on 2026-10-02). `deno.lock` is not an OSV format. | The Edge Functions' one npm dependency (`@supabase/supabase-js` 2.58.0, pinned and locked) is reviewed by hand | Re-check on each version bump |
| KI-019 | Low | A member who obtains another device's FCM token could register it to their own login, which moves that device's pushes to them. Tokens are per-install secrets that the app never displays. | That device would get the other member's business pushes (lock-screen-safe text only) | Accept. Revisit if tokens are ever shown or logged. |
| KI-020 | Info | Widget tests run under fake time. `compute` isolates, real font loading and real image decoding are replaced by synchronous seams there. The real paths are covered by unit tests outside fake time (image pipeline, PDF typesetter, CSV encoder). A Future completed in the root zone (for example `StreamSubscription.cancel`) never resumes under fake time; such futures are not awaited in app code. | Test-only | — |

## Closed

| ID | Closed by |
|---|---|
| KI-001 | UI for catalogue, customers, orders, Hisaab, payments, bills, Vaat and WhatsApp built (increments 1–10, merged in thehummingbirdsrudios-lgtm/Mobile_app#3) |
| KI-002 | `staff-admin` Edge Function plus owner staff screens (live deploy tracked in KI-014) |
| KI-009 | OSV-Scanner runs in CI on every push (KI-018 covers the remaining gap) |
| KI-010 | The release APK (R8) is built in CI on every push. Running it on a device is KI-003. |
| KI-011 | Notifications (inbox, fan-out, push dispatch), the version gate and maintenance mode built |
| KI-012 | The `share` bucket is closed to app users: the app shares from the device. Share temp files are deleted after each share and swept at start-up. |
