# M1-T03 evidence — exact-size sample PDF

The final implementation was verified by GitHub Actions CI run `33797250917`. Both the Android quality/build job and the unsigned iOS simulator build completed successfully.

## Generated artifact

- Artifact ID: `9909790251`
- Digest: `sha256:2f16065be07c8d87c793baa83d1ef0f1c23cde23d6bccd922e5125e092616c44`
- Files: `sample-35x45-a4.pdf`, geometry JSON, Android debug APK and coverage.

The sample is generated from a synthetic 35 × 45 pixel PNG and contains eight rectangles whose PDF model measures 35 × 45 mm on an A4 page. Automated tests inspect the serialized page `MediaBox` and the actual PDF widget boxes with a 0.1 mm tolerance.

This evidence proves PDF geometry only. It does not claim that a printer driver will preserve scale; that remains a later physical human gate.
