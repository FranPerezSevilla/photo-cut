# M2-T06 evidence — contextual help and configuration hierarchy

Photo Cut now exposes concise offline help for every configuration parameter requested in issue #14. Each help sheet explains what changes, when to use the setting, one example and whether the PDF itself changes.

Margin, separation and cut marks moved to a collapsed Advanced options section while the existing defaults remain usable without opening it. The old framing sliders are clearer but intentionally remain temporary until M2-T07 replaces them with direct visual positioning.

Preparation run `34103512295` and full implementation PR CI run `34103900438` passed analysis, tests, Android builds and the iOS simulator build.

The repository-owned roadmap now records M2-T06 as done and exposes M2-T07 as the next executable task. This human-authored evidence commit exists to obtain full Android/iOS CI for that exact completed state before merge.
