# ADR-011 — Localize core product and remove calibration

## Status
Accepted — 2026-09-14

## Context
Real-device use showed that the calibration sheet does not add enough value to justify a dedicated product flow or physical-print gate. The product should instead spend that complexity budget on a polished multilingual experience before monetisation.

## Decision
- Remove the calibration entry point and calibration feature from the user-facing product.
- Remove any release dependency on a physical 50 mm calibration print.
- Keep the normal print guidance that users should print the generated PDF at 100% / actual size; Photo Cut still does not claim control over printer-driver scaling.
- Ship five UI languages: Spanish (`es`), English (`en`), French (`fr`), Portuguese (`pt`) and German (`de`).
- Follow the operating-system locale by default. If the user chooses a language manually in the app, that override wins; choosing “System” returns to OS locale resolution.
- Keep the product name `Photo Cut` language-neutral.

## Consequences
- Calibration-specific UI, tests and roadmap gates can be deleted.
- Product-visible strings in the main production flow move behind one localization layer.
- Locale selection becomes an app-level concern owned by `PhotoCutApp`; print geometry remains locale-independent.
- Decimal parsing continues to accept both comma and dot so the underlying physical values remain stable across locales.
