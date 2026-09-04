# ADR-008: Use normalized crop state and local `image` processing

- Status: Accepted
- Date: 2026-09-04

## Context

Photo Cut must map arbitrary gallery images into an exact physical output
rectangle without distortion. It must also make grayscale visible in the
app-owned preview and apply the same choice to the final PDF instead of relying
on printer-specific monochrome settings.

Source JPEG files may store orientation only as EXIF metadata. Crop state must
remain stable across widgets, preview and final rendering, and must be testable
without a native editor.

## Decision

Use pure domain types in `lib/core/crop/`:

- `SourceImageSize` for orientation-aware pixel dimensions;
- `NormalizedPoint` for the user-selected focus;
- `NormalizedCropRect` for the resolved source rectangle;
- `ImageFitMode.cropToFill` and `ImageFitMode.fitInside`;
- `ImageColorMode.color` and `ImageColorMode.grayscale`.

Use the Dart `image` package at exactly version `4.9.2` behind
`ImageProcessor`.

- Package: `image`
- Version: `4.9.2`
- License: MIT
- Runtime network access: none
- Package boundary: only `lib/platform/image_processing/` imports it

The production processor runs decoding and transformation in a separate isolate,
bakes EXIF orientation before reporting dimensions, crops from normalized source
coordinates, flattens transparency over white, applies grayscale when selected
and encodes a high-quality JPEG for PDF embedding.

## Crop editor spike

`crop_your_image` 2.0.0 was evaluated but is not retained in the MVP. It offers
an interactive crop viewport, but Photo Cut currently needs only a fixed target
aspect plus a normalized focus point. Retaining another UI dependency would
duplicate the app-owned preview and introduce a second crop state to reconcile.

The preparation screen therefore uses two explicit modes:

- **Rellenar:** `BoxFit.cover` plus horizontal and vertical focus controls,
  resolved to a normalized crop rectangle by the domain planner.
- **Encajar:** `BoxFit.contain` with the full normalized source rectangle and
  white letterboxing where necessary.

A freeform draggable crop editor can be reconsidered only with new evidence that
the focus controls are insufficient.

## Consequences

- Crop and fit calculations are deterministic and unit-testable.
- Preview and final processing share the same normalized state.
- EXIF-rotated images have one physical pixel coordinate system.
- App-owned grayscale is visible before the native print dialog.
- Full-resolution processing can happen off the UI isolate.
- Processed bytes are temporary and remain on-device.
- JPEG re-encoding is accepted for the MVP; effective resolution is assessed in
  M2-T05.
