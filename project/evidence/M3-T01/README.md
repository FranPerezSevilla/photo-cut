# M3-T01 — Print scale verification and guidance

## Product behaviour

Photo Cut generates its PDFs with explicit physical dimensions. The 50 × 50 mm sheet is therefore **not an app calibration step** and does not modify the generated photo sizes.

A secondary **Prueba de escala de impresión** remains available from the app's overflow menu before any purchase flow. It exists only to verify the external PDF-to-paper path: operating system, print dialog, driver and printer.

The screen explicitly explains that distinction and instructs the user to:

- print at **100 % / Tamaño real**;
- avoid **Ajustar a página** or equivalent scaling;
- measure the 50 × 50 mm square with a ruler.

It also states the system boundary: Photo Cut controls the PDF geometry but cannot control scaling applied after the PDF leaves the app.

## Automated evidence

- `test/features/calibration/calibration_pdf_generator_test.dart` checks the generated A4 page metadata and the post-layout PDF widget box against 50 mm converted to PDF points.
- `test/features/calibration/calibration_screen_test.dart` checks the actual-size guidance, the explicit no-calibration wording and native-print gateway handoff.
- `test/features/calibration/home_calibration_entry_test.dart` checks that the scale test is secondary (hidden in the overflow menu) while remaining available before photo selection/purchase.
- `lib/features/home/home_screen.dart` keeps the normal choose/configure-photo flow free of calibration UI.

## Human gate

This task does **not** claim that a physical printer produced an exact 50 mm square. That measurement belongs to `M3-H01` and must be performed on real hardware after this task is merged.
