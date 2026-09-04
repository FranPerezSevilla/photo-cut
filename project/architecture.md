# Architecture

## Principles

Photo Cut is a deliberately small offline-first Flutter application. Architecture
must protect the hard part—physical geometry—without introducing enterprise
ceremony.

## Planned module boundaries

```text
lib/
├── app/                    App root, navigation and theme wiring
├── core/
│   ├── units/              PhysicalLength and point conversion
│   ├── layout/             Pure sheet-placement engine
│   └── quality/            DPI and resolution advice
├── platform/               Image, print, file and purchase gateways
└── features/
    └── print_job/          State/controller and user-facing pages
```

### Domain

The domain layer is pure Dart. It must not import Flutter widgets or plugin APIs.
It owns:

- physical units;
- paper dimensions;
- margins and gaps;
- orientation selection;
- repeated-copy placement;
- page overflow;
- crop/fit metadata;
- effective-DPI calculations.

### Platform adapters

Plugins and operating-system behaviour are wrapped behind narrow interfaces.
Tests use fakes. Planned adapters include:

- image selection;
- temporary/local files;
- PDF preview/share/print;
- lifetime purchase and restoration.

`PrintDocument` carries PDF bytes and explicit physical page dimensions. Native
share and print requests pass through `PrintGateway`; feature code never invokes
static plugin APIs. The read-only `PdfDocumentPreview` wrapper disables the
plugin's built-in actions so all user-triggered share/print operations still use
the gateway and remain replaceable by fakes in tests.

### UI and state

The app has one short-lived print-job session. Use an immutable state object and a
small `ChangeNotifier`/`ValueNotifier`-style controller when the feature begins.
Do not add a state-management framework without evidence and an ADR.

## Physical geometry

PDF uses typographic points, where 1 inch is 72 points:

```text
points = millimetres × 72 / 25.4
millimetres = points × 25.4 / 72
```

Conversions should happen at boundaries. Domain values remain explicit and are
not rounded for layout. UI formatting may round for display only.

Sheet placement uses a top-left physical origin and row-major copy order. The
engine evaluates portrait and landscape paper plus optional 90-degree photo
rotation. It selects greatest capacity, then preserves photo orientation, then
prefers portrait paper as a deterministic tie-breaker. The complete grid is
centred inside the configured minimum margin; page overflow reuses that grid.

## Supported platforms

- Flutter 3.47.2 / Dart 3.13.2.
- Android minimum SDK 24.
- iOS deployment target 15.0.
- Android and iOS only for the MVP.

Bundle identifiers are provisional until store-account validation:

```text
Android: com.frainzzel.photocut
iOS:     com.frainzzel.photocut
```

## Data and privacy

No backend and no database are needed for the MVP. A selected image is temporary
job input; it is never uploaded by Photo Cut. Purchase state is derived from the
store API and minimal local entitlement state where required.

## Dependency policy

Expected dependencies, added only in their roadmap tasks:

- `pdf` for document generation;
- `printing` for preview/share/native print;
- `image_picker` for source-image selection;
- `crop_your_image` only if its M2 spike proves suitable;
- `in_app_purchase` for the lifetime product.

Package additions and upgrades must include a reason, licence check, test impact
and updated lockfile.
