# Google Play assets

This directory separates two kinds of store imagery:

## Feature graphic

`feature-graphic-1024x500.jpg` is marketing artwork. It is intentionally
illustrative and may simplify the printing outcome to communicate Photo Cut's
core value quickly. It must not be treated as a literal app screenshot.

## Phone screenshots

The Google Play phone screenshots are generated from Photo Cut's **real Flutter
widgets**, not recreated UI mockups. A Flutter integration test drives the same
Home and GuidedPrintWizard widgets used by the app, and ChromeDriver captures the
rendered app at a deterministic phone-shaped viewport.

The dedicated `Google Play Store Screenshots` GitHub Actions workflow runs:

```text
integration_test/store_screenshots_test.dart
```

through Flutter Driver and writes six PNG files to:

```text
build/store-screenshots/
```

The reviewed store-ready copies are also versioned in:

```text
store/google-play/screenshots/
```

Each screenshot is captured at 450 × 900 pixels with a fixed 1:2 phone aspect
ratio. The deterministic viewport and committed copies make the listing assets
both reproducible and reviewable in normal source history.

Current set:

1. `01-home-selected.png` — real Home screen after selecting a photo.
2. `02-size-10x15.png` — real Size step with the 10 × 15 cm preset.
3. `03-framing-focus.png` — real focused Adjust framing screen.
4. `04-sheet-a4.png` — real Sheet step on A4 with the default copy count.
5. `05-sheet-10x15.png` — real 10 × 15 cm photo-paper setup with one copy.
6. `06-review.png` — real wizard Review step before final PDF generation.

The photo shown inside the app is a synthetic scenic fixture created only for
Photo Cut store imagery. No personal photograph is used.

The screenshots are literal app UI renders. Marketing headlines, phone frames,
invented navigation, or controls that do not exist in Photo Cut must not be
added to these files.
