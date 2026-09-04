# ADR-009: Review and hand off one immutable final PDF

- Status: Accepted
- Date: 2026-09-04

## Context

Photo Cut owns exact geometry, crop/fit and colour. The operating-system print
screen owns printer selection and printer-specific options. Mixing those two
responsibilities made the M1 spike appear to have paper and monochrome controls
that should update Photo Cut's preview even though the native service was only
receiving an already-generated PDF.

## Decision

Adopt the two-step flow recorded in issue #9:

1. **Prepare in Photo Cut.** Every document setting updates app-owned state and
   preview.
2. **Review and print.** `PrintJobDocumentFactory` processes the source image,
   builds the final layout, renders one named PDF and returns a `PrintDocument`.
   The same `PrintDocument` instance is shown by the read-only preview and passed
   to sharing or `PrintGateway`.

The native print button is explicitly labelled for the current platform. It
opens the existing `PrintingPrintGateway`, which passes the document page format
and immutable PDF bytes with `dynamicLayout: false`. Returning from the system
screen leaves both the review document and the underlying configuration route in
memory, so the user can share again or go back and edit.

`PrintJobFilenameBuilder` creates a deterministic ASCII-safe name containing the
source stem, exact size, copy count, paper and colour mode.

## Consequences

- Native paper controls never reflow Photo Cut content.
- Preview, sharing and printing use the same PDF payload.
- Crop, fit, rotation, grayscale and cut marks are baked before native printing.
- Action cancellation and errors are recoverable without rebuilding the job.
- No backend, account or network access is introduced.
- Actual-size printer guidance and physical measurement remain M3 gates.
