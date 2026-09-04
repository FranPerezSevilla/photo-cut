# Synthetic test resources

`synthetic-35x45.png.base64` decodes to a 35 × 45 pixel RGB PNG made only of
three flat colour bands. It was generated specifically for Photo Cut and
contains no person, private metadata or third-party artwork.

The fixture is intentionally stored as Base64 text so repository tooling can
create and review it without treating a personal photograph as test data. Tests
and evidence generators decode it to `Uint8List` before calling the same PDF
renderer used by the application.

The pixel dimensions are not used to claim print quality. This fixture proves
that deterministic synthetic image bytes can pass through the PDF adapter; later
resolution guidance is a separate task.
