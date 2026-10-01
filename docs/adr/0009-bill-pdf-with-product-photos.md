# ADR-0009: Bill PDF with a real product photo on every line

Status: accepted · 2026-10-01

## Context
A bill must show, on every line, the actual photo of the design next to its
design number, product, qty, rate and amount, whether the bill has 1 or
100+ lines. It must be small enough for WhatsApp, readable when zoomed,
work offline once photos are cached, never break because one photo is
unavailable, and keep tenants' photos private. The `pdf` package draws
images only from bytes (a URL in a PDF is not an image) and has no
Gujarati/Devanagari shaping.

## Decision
- **Canonical source = existing `product_media` row** (object-storage keys
  per derivative + width/height/sha256/mime). No new image tables or URL
  columns; no image bytes and no long-lived URLs on bills. `bill_payload`
  returns per line the key of the photo *as ordered* (800px catalogue
  derivative; never the multi-MB original). Buckets are private, so keys are
  turned into short-lived signed HTTPS URLs at fetch time.
- **Pipeline** (`core/media/remote_images`, reusable): source → fetch →
  validate → optimise → cache, orchestrated by `OptimizedImageLoader`.
  - Fetch: HTTPS on the storage host only, no redirects, timeout, idle
    timeout while streaming, hard byte cap (cancelled when exceeded),
    content-type check, one retry for transient failures.
  - Validate by content (JPEG/PNG/WebP/GIF/BMP), pixel cap (25 MP).
  - Optimise in an isolate: EXIF orientation, alpha → white, downscale only,
    JPEG q85–88 with 4:4:4 chroma (fine jewellery detail stays crisp), no
    metadata.
  - Cache: memory LRU + bounded disk LRU (app support dir), keyed by
    sha256(source key + size spec); storage keys are write-once, so this is a
    content key. Cleared on sign-out/identity change.
  - Never throws for image problems: the line gets a placeholder; the
    failure is logged with storage key + design no (never the signed URL).
- **Sizes by line count** (`BillImageTier`): 1–15 lines 64 pt cells /
  360 px; 16–20 → 56 pt / 300 px; 21+ → 48 pt / 240 px. Always ≥ 5 px/pt
  (≈ 360 dpi): sharp on zoom and in print, ~10–30 KB per photo.
- **Typesetting**: `pdf` package `MultiPage` + `Table` with a repeating
  header row; rows are atomic (never split); first-page business/customer
  header, "continued" header and page x/y footer on later pages; totals
  block after the table. Each distinct photo is one `MemoryImage` → embedded
  once even if it appears on many lines. Fonts (Hind) are subset-embedded.
  Indic text runs are shaped by Flutter (`rasterizeText`, 4×) and embedded as
  small images; Latin text, numbers and ₹ stay vector. Typesetting runs in a
  background isolate.
- **Memory**: at most 3 downloads/optimisations in flight; each holds one
  original at a time; only small JPEGs are retained.

## Consequences
- Measured per-photo size on a deliberately hard (textured + noisy) 800px
  source: 49 KB at 360 px, 30 KB at 300 px, 17 KB at 240 px. Worst-case
  bills therefore stay around 0.8 MB (15 lines), 0.65 MB (20) and 1.8 MB
  (100 lines, 9 pages); smooth real photos compress further. Every line's
  photo is verified in the right row by decoding the embedded JPEGs in
  drawing order (`bill_pdf_test.dart`).
- Generation happens on the device that shares the bill (no custom server,
  ADR-0001/0006); a server-side generator could reuse the same pipeline
  design later.
- Indic text in the PDF is an image (not selectable/searchable); numbers and
  Latin text remain text.
