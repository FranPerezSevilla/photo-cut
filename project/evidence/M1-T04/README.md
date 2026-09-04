# M1-T04 evidence — PDF preview, share and print spike

The final task implementation was verified by GitHub Actions CI run `33859417443`. The Android quality/build job and unsigned iOS simulator build both completed successfully.

The spike renders the deterministic eight-copy 35 × 45 mm A4 document inside the app. User-triggered share and print actions pass the same in-memory PDF through `PrintGateway`; widget tests use a fake gateway to verify payload identity, cancellation, retry and error handling.

This evidence proves integration and target-platform compilation. It does not claim that a person completed a native share or print dialog, nor that a physical printer preserved dimensions. Those remain real-device and physical-validation gates.
