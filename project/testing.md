# Testing strategy

## Automated layers

1. **Pure Dart unit tests** — conversions, paper sizes, copy placement, page
   overflow, crop metadata and effective DPI.
2. **Flutter widget tests** — validation, navigation, state transitions and
   accessibility labels.
3. **Integration tests with fakes** — select/configure/preview/export flow without
   invoking native pickers or stores.
4. **Platform build checks** — Android debug APK and unsigned iOS simulator build.
5. **Targeted real-device checks** — plugins, memory/lifecycle recovery and store
   sandbox behaviour.

## Geometry evidence

A visual preview is not proof of exact size. Tests should assert:

- page width/height in points;
- each image box in points and converted millimetres;
- margins and gaps;
- non-overlap and page containment;
- deterministic layout for the same specification;
- copy count across page boundaries.

## Store purchase gate

CI can verify entitlement state transitions and purchase-adapter behaviour with
fakes, but it cannot prove real store checkout or restoration. M4 therefore keeps
a human sandbox gate for Android and iPhone that records:

- app version and exact commit;
- device and operating system;
- purchase, cancellation and restoration outcomes;
- store product name and one-time pricing shown to the tester.

Normal print guidance still tells users to choose 100% / actual size. Printer
hardware and driver scaling remain outside Photo Cut's control and are not a
separate calibration workflow.
