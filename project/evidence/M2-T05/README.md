# M2-T05 evidence — effective resolution guidance

Photo Cut estimates effective DPI from orientation-aware source pixels that remain after crop and the exact physical image area. Fit-inside excludes white letterboxing from the physical image-area calculation.

The product thresholds are guidance only: 300+ ppp high, 200–299 good, 150–199 caution, and below 150 low. Warnings never block review/export and never alter physical dimensions.

Preparation run `34101018943` passed focused analysis/tests. PR CI run `34101233839` passed the full Android quality/build pipeline and iOS simulator build.

The repository-owned roadmap now records M2-T05 as done, schedules the real-device UX feedback from issue #14 as M2-T06 through M2-T08, and makes M2-T06 the next executable task. This commit exists to obtain full CI on that exact completed state before merge.

Real-device UX feedback is deliberately scheduled before physical calibration; no printer-quality guarantee is claimed by this automated evidence.
