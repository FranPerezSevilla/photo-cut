# Testing strategy

## Automated layers

1. **Pure Dart unit tests** — conversions, paper sizes, copy placement, page
   overflow, crop metadata and effective DPI.
2. **Flutter widget tests** — validation, navigation, state transitions and
   accessibility labels.
3. **Integration tests with fakes** — select/configure/preview/export flow without
   invoking native pickers or stores.
4. **Platform build checks** — Android debug APK and unsigned iOS simulator build.
5. **Targeted real-device checks** — plugins, memory/lifecycle recovery and store
   sandbox behaviour.

## Geometry evidence

A visual preview is not proof of exact size. Tests should assert:

- page width/height in points;
- each image box in points and converted millimetres;
- margins and gaps;
- non-overlap and page containment;
- deterministic layout for the same specification;
- copy count across page boundaries.

## Physical print gate

CI cannot prove printer output. M3 includes a 50 mm calibration square and a human
record containing:

- device and OS;
- printer model and print route;
- “actual size / 100%” setting used;
- measured width/height;
- date and app commit.

Never use OCR or a photographed ruler as the sole measurement evidence.
