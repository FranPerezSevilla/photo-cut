# M2-T04 evidence — immutable final review and native handoff

GitHub Actions CI run `33918765113` passed analysis, all unit and widget tests, deterministic PDF generation, Android debug and release builds, artifact upload and the unsigned iOS simulator build.

`PrintJobDocumentFactory` applies stored crop, fit, colour, rotation and cut-mark choices and produces a stable named `PrintDocument`. The Step 2 screen uses that same document instance for read-only preview, sharing and native printing. Returning from the system screen or selecting `Volver y editar` preserves the underlying configuration route.

This automated evidence does not claim that a real share sheet, native print dialog or physical printer was operated. Those remain device and M3 gates.
