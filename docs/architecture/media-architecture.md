# Media architecture (designed; implemented in the catalogue increment)

## Storage split
- **Postgres** `product_media` is the authoritative index: tenant, product,
  kind, status, sort order, MIME, size, sha256, dimensions and one storage key
  per derivative.
- **Supabase Storage** (private buckets) holds the binaries:
  `product-media/{tenant}/products/{product}/{media}/{variant}.{ext}`.

## Derivatives
| Variant | Size | Used by |
|---|---|---|
| original | as uploaded (≤ 25 MB image) | Not used by any screen. Storage currently lets every member read it; restrict to owners in the media increment |
| catalogue | 800 px long edge, JPEG/WebP q≈82 | Product detail |
| thumb | 256 px | Catalogue grid, bill thumbnails, order lines |
| share | 1280 px with optional business watermark | WhatsApp |
| video poster | 800 px | Video tile; video plays only on request |

Derivatives are produced **once at upload, on the device, in a background
isolate** (ADR-0006). This saves server cost and only the uploader's device
pays. Each derivative is uploaded, then an RPC finalises the media row to
`ready`. Re-processing never happens on view.

## Upload lifecycle
`pick/capture → validate (type by magic bytes, size, dimensions) → compute
sha256 (dedupe) → derivatives in an isolate → upload (resumable job) →
finalise RPC (idempotent) → ready`.

Failures leave the row `pending` or `failed`. A cleanup job removes orphaned
objects and `pending` rows older than 24 h.

## Delivery
- Short-lived signed URLs, minted only for an authorised session.
- `cached_network_image` keyed by `tenant/media/variant`.
- Lists request `thumb` only. Full-size images load on demand.
- Memory: `cacheWidth`/`cacheHeight` decode at display size.

## Security
- Storage policies keep everything inside the tenant prefix.
- DB CHECKs ensure a media row can only point inside its own tenant.
- Shares use the `share` derivative, never the original.
- Filenames carry no business data.
