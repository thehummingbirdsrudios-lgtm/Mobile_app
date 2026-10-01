# ADR-0006: Image derivatives generated on the uploading device
**Status:** Accepted (for the media increment)

**Context.**
- Uploads are infrequent: the owner adds new designs.
- Browsing is constant.
- Server-side image transformation has a cost.

**Decision.**
- Generate the catalogue, thumb and share derivatives once, at upload, in a
  background isolate on the device.
- Store all of them.
- Never transform on view.

**Consequences.**
- No server image cost.
- Quality depends on the client encoder.
- Revisit and move to an Edge Function or worker if quality or consistency
  issues appear, or if web uploads need it.
