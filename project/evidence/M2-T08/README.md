# M2-T08 evidence — persistent zoomable PDF preview

Focused preparation run `34129229485` and complete Android/iOS PR CI run `34129453514` passed.

Step 1 keeps a single print-job controller while exposing `Ajustes` and `Vista previa` as a persistent one-tap switch. The preview lazily builds the actual current PDF, invalidates stale documents after setting changes, and keeps zoom/pan/reset state entirely inside the viewer. No viewer transformation changes PDF bytes, layout geometry or physical dimensions.

The repository-owned roadmap records `M2-T08` as done, closes milestone M2 and exposes `M3-T01` as the next executable task. This human-authored evidence commit exists so the exact completed state receives full Android and iOS CI before merge.

This automated evidence does not claim real-handset gesture quality; that remains a useful smoke test of the generated APK.
