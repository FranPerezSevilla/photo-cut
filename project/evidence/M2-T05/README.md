# M2-T05 evidence — effective resolution guidance

Photo Cut estimates effective DPI from orientation-aware source pixels that remain after crop and the exact physical image area. Fit-inside excludes white letterboxing from the physical image-area calculation.

The product thresholds are guidance only: 300+ ppp high, 200–299 good, 150–199 caution, and below 150 low. Warnings never block review/export and never alter physical dimensions.

Preparation run `34101018943` passed focused analysis/tests. PR CI run `34101233839` passed the full Android quality/build pipeline and iOS simulator build.

Real-device UX feedback is captured in issue #14 and is deliberately scheduled as M2-T06 through M2-T08 before physical calibration.
