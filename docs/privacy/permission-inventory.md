# OS permission inventory

| Permission | Status | Requested when | Purpose | If denied |
|---|---|---|---|---|
| `INTERNET` | Declared | Install time (normal permission) | All data lives on the server | — |
| Camera | Not declared yet | When the user taps 📷 Photo or QR scan (Vaat/catalogue increments) | Design photos, enquiry photos, QR | Explain, then offer the gallery path and an "Open settings" link |
| Microphone (`RECORD_AUDIO`) | Declared | When the user taps 🎙 Voice | Voice notes (original audio) | Explain, then offer Text instead and an "Open settings" link |
| Photos/media | Not declared (system photo picker needs none on modern Android) | Picking an existing photo | Product/enquiry images | Picker unavailable message |
| Notifications (`POST_NOTIFICATIONS`, Android 13+) | Declared (by firebase_messaging) | After sign-in, when the device registers for push | Order, payment and new Maal alerts | App works fully; inbox and bell only |

Rules:
- Never request at startup.
- Explain why in one sentence before the system prompt.
- Remove the declaration when the feature is removed.
