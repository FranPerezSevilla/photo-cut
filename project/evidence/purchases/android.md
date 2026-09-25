# Android purchase validation

- Date: 2026-09-24
- Track: Google Play internal testing
- App: Photo Cut
- Package: `com.frainzzel.photocut`
- Version: `0.1.0` (version code 1)
- Product: `photo_cut_lifetime`
- Product type: one-time / non-consumable
- Device model: not yet recorded; required before M4-H01 can be completed

## Human result

The tester reported that the installed internal-track build and the lifetime
purchase flow worked end to end on Android.

The same real-device session exposed two product issues:

1. the first free final PDF was generated without an explicit warning that the
   successful generation consumes the only free use;
2. after applying visual framing and returning to the wizard, the live preview
   image could be blank until advancing to the next wizard screen.

Both findings are addressed by M4-T03 and must be rechecked on the internal-track
build produced after that task lands.

Implementation verification: GitHub Actions CI run `35956748398` passed both
Quality/Android and iOS simulator jobs for the M4-T03 product changes. A fresh
final-head PR check is still required before merge.

## Still required for M4-H01

- re-test the M4-T03 build on Android;
- record the Android device model;
- explicitly validate purchase cancellation leaves entitlement unchanged;
- explicitly validate Restore purchase;
- validate purchase, cancellation and restoration on an iPhone sandbox account.

This file records only what the human tester actually reported; it does not
claim the remaining checks have passed.
