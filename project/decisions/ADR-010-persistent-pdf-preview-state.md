# ADR-010: Keep Step 1 PDF preview and zoom as viewer-only state

- Status: Accepted
- Date: 2026-09-07

## Context

Real-device feedback in issue #14 showed that the sheet preview at the top of a
long settings form was too hard to revisit. Users also need to inspect small
details without confusing on-screen zoom with physical print scaling.

## Decision

Step 1 gets a persistent `Ajustes | Vista previa` switch in the fixed app bar.
Both views live in one `IndexedStack`, so the same `PrintConfigurationController`
and immutable `PrintJobConfiguration` remain alive while switching views.

The preview tab lazily builds the actual `PrintDocument` with the existing
`PrintJobDocumentFactory`. It does so only when the tab is opened and caches that
document while configuration identity is unchanged. A settings change invalidates
the cache on the next preview visit. Invalid settings never show a stale PDF.

The existing `PdfDocumentPreview` remains the PDF renderer. A new
`ZoomablePdfDocumentPreview` wraps that read-only renderer in Flutter's
`InteractiveViewer` to provide pinch zoom and pan. Its `TransformationController`
is widget/viewer state only and is never stored in `PrintJobConfiguration`.
`Encajar página` resets that transform to identity, which returns the PDF renderer
to its normal fit-page layout.

No new runtime dependency is introduced.

## Consequences

- The current PDF is reachable in one tap even after scrolling far down settings.
- Switching views never creates a second print job or loses edited values.
- Preview generation is deferred until requested instead of running on every edit.
- Zoom, pan and reset cannot change PDF bytes or exact physical geometry.
- Final review/share/native print still uses the same document factory and remains
  the authoritative Step 2 handoff.
