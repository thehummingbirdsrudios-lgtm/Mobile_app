# UI principles

1. **The jewellery is the colour.** Ivory surfaces, ink text, restrained gold
   accent. Photography carries the richness.
2. **One main job per screen.** Everything else is contextual or one tap away.
3. **Truthful feedback.** Success appears only after the server commits.
   "Prepared" is never shown as "Sent".
4. **Fewest decisions, not fewest taps.** Steppers, chips, recents and Regular
   Maal before keyboards.
5. **Familiar.** WhatsApp-like communication and plain vepari vocabulary
   (Maal, Baki, Hisaab, Fari Order).
6. **No raw errors.** Every failure maps through `AppFailure` to a short
   sentence plus retry when retrying can help.

## Tokens (`app/lib/core/design/tokens.dart`)
- **Type:** Hind Vadodara (Latin + Gujarati) with Hind fallback (Devanagari).
  One family across scripts. Body text is never below 16, captions are 12.
  Money uses tabular figures.
- **Spacing:** 4-pt scale, with a 16 dp phone gutter.
- **Radius:** 8 / 12 / 16 / 24 / pill.
- **Elevation:** three subtle shadow levels.
- **Touch targets:** 48 dp minimum.

## Measured contrast (WCAG 2.2; AA needs 4.5:1 for text, 3:1 for large text and UI)
| Pair | Ratio |
|---|---|
| ink `#1B1A17` on background `#FAF7F2` | 16.3:1 |
| ink `#1B1A17` on surface `#FFFFFF` | 17.4:1 |
| inkSoft `#3A3731` on surface | 11.9:1 |
| muted `#6B655C` on background | 5.4:1 |
| muted `#6B655C` on surface | 5.8:1 |
| muted `#6B655C` on surfaceMuted `#F3EEE6` | 5.0:1 |
| goldText `#7A5A1C` on surface | 6.4:1 |
| goldText `#7A5A1C` on goldTint `#F4EBD9` | 5.4:1 |
| gold `#A57C2C` on surface | 3.8:1 (large marks/icons only, never body text) |
| onInk `#FAF7F2` on ink (primary button) | 16.3:1 |
| success `#276F45` on successTint `#E6F2EA` | 5.3:1 (was 4.4:1 with `#2E7D4F`; fixed) |
| warning `#9A5B00` on warningTint `#FBF0DF` | 4.8:1 |
| error `#B3261E` on errorTint `#FBE9E7` | 5.6:1 |
| error `#B3261E` on surface | 6.5:1 |
| info `#2F5D8A` on infoTint `#E8EFF6` | 5.9:1 |

Status is never shown by colour alone: chips always carry text.

## Components (`app/lib/core/widgets/`)
| Component | Notes |
|---|---|
| AppButton | normal, pressed, disabled, busy, success, error; single-flight; spinner only after 250 ms |
| EmptyState | icon, one sentence, at most one action |
| ErrorState | message from `AppFailure`, retry only when retryable |
| Shimmer + SkeletonBox | one animation controller per region; static under reduced motion |
| AppFeedback | snackbar with success / warning / error / info tone |
| SuccessCheck | the single success mark |
| AppSearchField | debounced, clearable |
| QuantityStepper | 48 dp buttons, clamped |
| StatusChip, MoneyText, AppCard, ProductCard, CustomerTile | — |
| UnsavedChangesGuard | asks only when work would be lost |
| BrandMark | — |

## Responsive
- Below 600 dp: bottom navigation bar.
- 600 dp and up: navigation rail.
- 1100 dp and up: extended rail.

The conceptual model stays the same at every size. Content is constrained to
readable widths (forms: 400 dp; empty and error states: 360 dp).
