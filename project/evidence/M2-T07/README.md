# M2-T07 evidence — direct visual framing

Preparation run `34125704380` and full PR CI run `34126333498` passed after the responsive framing controls and the app smoke test were updated.

The two abstract framing sliders are no longer the primary interaction. In `Rellenar`, the user moves the photograph itself inside the exact target aspect; the drag updates the existing normalized `focus` value and therefore the same `CropPlanner` state used by final PDF generation. Wide images move horizontally and tall images vertically. `Encajar` visibly shows the complete image and disables crop movement.

Switching between fit modes preserves normalized focus, while `Centrar` and double-tap reset it. No second crop model or freeform editor was introduced.

The repository-owned roadmap now records `M2-T07` as done and exposes `M2-T08` as the next executable task. This final human-authored evidence commit exists so the exact completed state receives full Android and iOS PR CI before merge.

Issue #14 remains open because M2-T08 still needs to add persistent one-tap `Ajustes | Vista previa` navigation and viewer-only zoom/pan/reset.
