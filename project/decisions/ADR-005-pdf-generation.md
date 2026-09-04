# ADR-005: Generate documents with `pdf` 3.13.0

- Status: Accepted
- Date: 2026-09-03

## Context

Photo Cut must turn an already-tested `SheetPlan` into a PDF whose page box and
image rectangles retain the requested physical dimensions. The adapter must run
on Android and iOS, accept in-memory image bytes, support multiple pages and stay
independent from any printer or cloud service.

Writing and maintaining a PDF serializer would add a large, security-sensitive
format surface that is unrelated to the product's differentiating logic.

## Decision

Use the Dart `pdf` package at exactly version `3.13.0`.

- Package: `pdf`
- Version: `3.13.0`
- License: Apache License 2.0
- Runtime network access: none
- Repository: `DavBfr/dart_pdf`
- Package boundary: only `lib/platform/pdf/` imports `package:pdf`.

The package uses PDF points, where one point is 1/72 inch. Domain geometry
remains expressed through Photo Cut value objects and is converted to points only
inside the PDF adapter. The adapter consumes `SheetPlan`; it does not calculate
rows, columns, orientation, margins or page overflow again.

The first renderer disables document-stream compression in tests and evidence so
serialized page boxes remain inspectable. That is not a product guarantee about
printer output. Physical printing remains a separate human validation gate.

## Alternatives considered

### Write a minimal PDF serializer

This could reduce dependency count, but image embedding, cross-reference tables,
metadata, multi-page resources and format compatibility would become owned
maintenance and security work. The risk outweighs the small binary saving.

### Use `printing` alone

`printing` is intended for preview, sharing and native print transport. It still
uses or expects generated PDF bytes, so it does not replace a PDF producer. It is
considered separately in M1-T04.

### Commercial PDF SDK

A commercial SDK would provide broader editing and parsing features, but those
features are outside the MVP and would introduce licensing and integration cost.

## Consequences

- `pubspec.yaml` and `pubspec.lock` pin the chosen version.
- PDF APIs cannot leak into domain or feature state.
- Tests inspect the serialized `MediaBox` and the actual widget rectangles after
  the package layout pass.
- Package upgrades must be explicit tasks with regenerated evidence.
- Apache-2.0 notices must remain represented in release dependency records.
