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
│   ├── crop/               Normalized crop/fit geometry
│   └── quality/            DPI and resolution advice
├── platform/
│   ├── image_picker/       Gallery boundary
│   ├── image_processing/   EXIF, crop and colour transformations
│   ├── pdf/                Exact-size document generation
│   └── print/              Preview/share/native print
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
- normalized crop/fit metadata;
- effective-DPI calculations.

Crop state uses source-normalized coordinates in the closed range 0–1. A
`CropPlanner` derives the crop rectangle from orientation-aware source dimensions,
the exact physical target aspect and a normalized focus point. Fit-inside retains
the complete source rectangle.

### Platform adapters

Plugins and operating-system behaviour are wrapped behind narrow interfaces.
Tests use fakes. Adapters include:

- image selection;
- orientation-aware image inspection and processing;
- exact-size PDF generation;
- PDF preview/share/native print;
- future temporary/local files and lifetime purchase restoration.

Gallery selection is exposed through `ImagePickerGateway`. The production
adapter requests one image, immediately copies its bytes into short-lived app
state, drops provider paths and checks Android lost data once at startup.

`ImageProcessor` is the only boundary that imports `package:image`. It decodes
bytes off the UI isolate, physically bakes EXIF orientation, applies the normalized
crop when required, performs app-owned grayscale conversion and returns encoded
bytes without uploading them.

### UI and state

The app has one short-lived print-job session. Use immutable state objects and
small `ChangeNotifier` controllers. Do not add a state-management framework
without evidence and an ADR.

The product flow is intentionally split:

1. Photo Cut prepares the document and owns every setting that changes PDF
   content or geometry.
2. A read-only final review passes the same immutable PDF bytes to share or the
   operating-system print service.

The native print screen is a printer handoff, not a second document editor.

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
job input; it is never uploaded by Photo Cut. Provider paths and full metadata are
not retained. EXIF orientation is applied locally and removed from processed
output. Purchase state is derived from the store API and minimal local entitlement
state where required.

## Dependency policy

Current runtime dependencies have narrow boundaries:

- `pdf` for document generation;
- `printing` for preview/share/native print;
- `image_picker` for source-image selection;
- `image` for orientation-aware crop and colour processing.

`crop_your_image` was evaluated for M2-T03 and not retained because the narrow
MVP only needs normalized focus within a fixed output aspect. Reconsidering a
freeform crop editor requires a new task and evidence.

`in_app_purchase` remains planned for the lifetime product. Package additions and
upgrades must include a reason, licence check, test impact and updated lockfile.
