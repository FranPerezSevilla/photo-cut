# Google Play assets

This directory separates two kinds of store imagery:

## Feature graphic

`feature-graphic-1024x500.jpg` is marketing artwork. It is intentionally
illustrative and may simplify the printing outcome to communicate Photo Cut's
core value quickly. It must not be treated as a literal app screenshot.

## Phone screenshots

The Google Play phone screenshots are generated from Photo Cut's **real Flutter
widgets**, not recreated UI mockups. Run:

```bash
flutter test tool/store_screenshots/store_screenshots_test.dart
```

The command writes six PNG files to:

```text
build/store-screenshots/
```

Each image is rendered at an Android-like 390 x 780 logical-pixel viewport and
captured at 3x density, producing 1170 x 2340 PNGs.

Current set:

1. `01-home-selected.png` — real Home screen after selecting a photo.
2. `02-size-10x15.png` — real Size step with the 10 x 15 cm preset.
3. `03-framing-focus.png` — real focused Adjust framing screen.
4. `04-sheet-a4.png` — real Sheet step on A4 with the default copy count.
5. `05-sheet-10x15.png` — real 10 x 15 cm photo-paper sheet setup with one copy.
6. `06-review.png` — real wizard Review step before final PDF generation.

The demo image shown inside the app is generated synthetically by the screenshot
harness, so no personal or third-party photo is committed or uploaded.

The dedicated `Google Play Store Screenshots` GitHub Actions workflow renders
and uploads these files as a downloadable artifact. If product UI changes, rerun
that workflow instead of editing the screenshots by hand.
