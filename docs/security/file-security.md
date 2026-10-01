# File security

| Control | Implementation |
|---|---|
| Private by default | All buckets `public = false`; reads via signed URLs |
| Tenant scoping | Keys start with `tenant_id/`; storage RLS compares the first folder with the caller's tenant (`app.object_in_my_tenant`) |
| Write permissions | `product-media` needs `catalogue.manage`; `bills` needs `bills.issue`; `branding` is owner only; `remarks` and `share` are any member |
| Immutability | Originals are not updatable; only regenerable derivatives (bills, share, branding) can be overwritten |
| Allowed types and sizes | Bucket `allowed_mime_types` and `file_size_limit`; DB CHECK on media MIME and size; client also validates magic bytes (media increment) |
| Path integrity | DB CHECKs require every stored path to start with the row's tenant |
| Lifecycle | `share_assets.expires_at` (7 days) → cleanup job; orphaned uploads cleaned after 24 h |
| Names | Random UUID-based keys; no customer or business data in filenames |
| Malware | Not scanned yet (risk accepted for images/PDF/audio from authenticated staff; tracked KI-005) |

Tests: `tenant_isolation_test.dart` covers listing, uploading into and
deleting from another tenant's prefix, and registering media rows that point
at another tenant's paths.
