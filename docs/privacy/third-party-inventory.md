# Third-party inventory

| Component | Data it receives | Why | Processing location | Failure mode | Licence / terms |
|---|---|---|---|---|---|
| Supabase (Postgres, PostgREST, Auth, Storage) | All business data, credentials | Backend | Project region [TBD, recommend ap-south-1 Mumbai] | App shows retry states; nothing is faked | Supabase ToS/DPA |
| WhatsApp / other share targets (via OS share sheet) | Only allow-listed share content the user chooses to send | Communication | Meta / chosen app | Fallback to other apps or copy; never marked "sent" | Their terms |
| Google Play (distribution) | App metadata | Distribution | Google | — | Play policies |
| Hind, Hind Vadodara fonts (bundled) | None | Typography | On device | — | SIL OFL 1.1 (`app/assets/fonts/OFL-*.txt`) |
| Material Icons (Flutter SDK) | None | Icons | On device | — | Apache 2.0 |
| Flutter packages: flutter_riverpod, go_router, supabase_flutter, flutter_secure_storage, shared_preferences, intl, meta | Local only (supabase_flutter talks to Supabase) | App framework | On device | — | MIT / BSD-3 (pub.dev) |

**Not used:** analytics SDKs, crash reporting, ad networks. Adding any of them
requires:
1. a row here;
2. a privacy policy update;
3. a consent review.
