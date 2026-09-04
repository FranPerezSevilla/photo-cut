# ADR-006: Preview and transport PDFs with `printing` 5.15.0

- Status: Accepted
- Date: 2026-09-04

## Context

M1 already produces deterministic PDF bytes. The final spike must prove that
Android and iOS can render those bytes on screen, open the native share sheet and
hand the unchanged document to the platform print service. Reimplementing PDF
rasterisation and native print channels is outside the product's value.

The integration must remain testable without invoking operating-system dialogs.
It must also preserve the exact PDF rather than rebuilding geometry from a paper
format selected by a native dialog.

## Decision

Use the Flutter `printing` package at exactly version `5.15.0`.

- Package: `printing`
- Version: `5.15.0`
- Minimum Dart SDK declared by the package: 3.12
- Photo Cut Dart SDK: 3.13.2
- License: Apache License 2.0
- Runtime network access for Android/iOS preview/share/print: none required
- Repository: `DavBfr/dart_pdf`
- Package boundary: `lib/platform/print/`

`PrintGateway` owns the two user-triggered platform operations. Its production
implementation calls `Printing.layoutPdf` and `Printing.sharePdf`; tests supply a
fake. Printing uses `dynamicLayout: false` and returns the existing in-memory PDF
bytes so native paper suggestions cannot silently change Photo Cut's geometry.

`PdfDocumentPreview` wraps `PdfPreview` as a read-only renderer. Built-in share
and print buttons are disabled; the feature screen exposes its own actions routed
through `PrintGateway`.

The M1 screen is development-only and uses a synthetic eight-copy 35 × 45 mm A4
document. The real image-driven flow replaces it in M2.

## Alternatives considered

### Invoke `Printing` directly from the screen

This is less code but makes widget tests depend on method channels and prevents a
fake from proving cancellation, errors and payload identity.

### Render only a custom Flutter diagram

A diagram could resemble the page but would not prove that the generated PDF can
be rasterised by the plugin used in production.

### Add a separate PDF viewer plugin

That would duplicate native PDF infrastructure and dependency surface while
`printing` already provides preview, share and print for both target platforms.

## Consequences

- `pubspec.yaml` and `pubspec.lock` pin `printing` 5.15.0.
- Only platform adapter files import `package:printing`.
- Feature tests use a fake gateway and an injectable preview builder.
- Native dialogs still require real-device observation; CI proves compilation and
  isolates the platform boundary but cannot assert that a user completed a print.
- Package upgrades are explicit roadmap work with Android and iOS rebuilds.
