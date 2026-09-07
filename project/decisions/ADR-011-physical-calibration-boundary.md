# ADR-011: Separate PDF calibration geometry from physical printer validation

- Status: Accepted
- Date: 2026-09-07

## Context

Photo Cut can guarantee the geometry it writes into a PDF, but it cannot force a printer driver, operating-system print service or printer hardware to preserve that geometry. The product therefore needs a useful calibration tool without turning an automated PDF test into a false physical-print claim.

## Decision

Photo Cut exposes a calibration feature before any purchase gate. It generates a deterministic PDF on A4, US Letter or 10 × 15 cm paper with one reference square whose laid-out outer box is exactly **50 × 50 mm** in PDF space.

The feature instructs the user to:

- choose the same paper in Photo Cut and the native print service;
- print at **100% / Actual size / Tamaño real**;
- disable **Fit to page / Ajustar a página**;
- measure both axes of the 50 mm square with a ruler.

The PDF renderer records its laid-out square geometry so automated tests can verify the page box and square dimensions to the normal ±0.1 mm document tolerance. The separate `M3-H01` gate records real device, print route, printer and physical measurements. A deviation greater than 1 mm on either axis must be investigated before release.

## Consequences

- Calibration is independent of photo selection and future export entitlement.
- Existing `PrintGateway` and `PdfDocumentPreview` are reused; no printer-brand integration is added.
- Native printing remains `dynamicLayout: false`.
- Automated success means only that PDF geometry is correct.
- Physical printer accuracy can be claimed only after human evidence exists.
