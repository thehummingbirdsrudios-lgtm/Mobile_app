# Motion system (`app/lib/core/motion/motion.dart`)

Priority: **response → correctness → polish**. Motion explains a change; it
never delays work and never hides slow architecture.

| Token | Duration | Used for |
|---|---|---|
| `instant` | 100 ms | press scale (0.98), stepper value swap |
| `quick` | 180 ms | button state cross-fade, inline error reveal, chip changes |
| `standard` | 260 ms | page transitions, bottom sheets |
| `emphasized` | 360 ms | success check draw (the longest animation in the app) |
| `loadingDelay` | 250 ms | spinners appear only after this, so fast responses never flash |

Curves:
- `standardCurve`: easeOutCubic.
- `enterCurve`: emphasized decelerate.
- `exitCurve`: emphasized accelerate.

## Transitions
- **Pages:** `FadeThroughPageTransitionsBuilder` uses a fade plus a 0.98 → 1.0
  scale. Back is the exact mirror. iOS keeps its native transition.
- **Sheets:** Material bottom-sheet motion.
- **Product image continuity:** a Hero from the catalogue card to product detail
  (catalogue increment).

## Rules
- Reduced motion: every duration goes through `AppMotion.of(context, …)` and
  becomes zero when the platform asks.
- The shimmer is static and the success check is drawn complete.
- No bounce, no parallax, no looping decoration, no particles.
- Haptics only for:
  - success confirmation (light impact)
  - quantity change (selection click)
- Animation controllers live in `State` and are disposed. There is one
  controller per skeleton region, not one per box.
