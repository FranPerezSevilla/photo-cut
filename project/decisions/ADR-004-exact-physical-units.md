# ADR-004: Model exact physical sizes explicitly

- Status: Accepted
- Date: 2026-09-03

## Context

The product fails if dimensions are ambiguous or are rounded too early. Pixels,
logical Flutter pixels, millimetres, inches and PDF points are different units.

## Decision

Introduce explicit physical-length value types in M1. Keep domain calculations in
millimetres (or an equivalently explicit canonical representation) and convert to
PDF points only at the rendering boundary using 72 points per inch.

## Consequences

- APIs are slightly more verbose but prevent unit confusion.
- Unit conversion and tolerance tests are mandatory.
- Printer-driver scaling remains outside the geometry guarantee and is handled by
  calibration guidance.
