# M3-T01 — Calibration and print guidance

## Product behaviour

Photo Cut exposes **Comprobar tamaño de impresión** from the home screen, before any purchase flow. The calibration screen generates the real PDF on-device and previews an A4 sheet containing a 50 × 50 mm reference square.

The screen explicitly instructs the user to:

- print at **100 % / Tamaño real**;
- avoid **Ajustar a página** or equivalent scaling;
- measure both sides of the square with a ruler.

It also states the system boundary: Photo Cut controls the PDF geometry but cannot control scaling applied by the operating system, printer or printer driver.

## Automated evidence

- `test/features/calibration/calibration_pdf_generator_test.dart` checks the generated A4 page metadata and the post-layout PDF widget box against 50 mm converted to PDF points.
- `test/features/calibration/calibration_screen_test.dart` checks the guidance wording and native-print gateway handoff.
- `lib/features/home/home_screen.dart` exposes calibration independently of photo selection or purchase state.

## Human gate

This task does **not** claim that a physical printer produced an exact 50 mm square. That measurement belongs to `M3-H01` and must be performed on real hardware after this task is merged.
