# Product definition

## Working name

**Photo Cut**. Store naming will be validated later; likely descriptive variants
include “Print Exact Size” and “Foto a Medida”.

## User problem

Printing an image at an exact physical size is unnecessarily awkward. General
editors and printer apps often require the user to reason about page layout,
scaling, margins, duplication and “fit to page” behaviour.

## Core job

> Given one image, exact physical dimensions, a paper size and a copy count,
> produce a print-ready PDF with repeated copies and optional cut marks.

## Primary flow

### Step 1 — Prepare in Photo Cut

1. Select one image from the device.
2. Enter width and height in mm, cm or inches.
3. Choose crop-to-fill or fit-inside and adjust the focus when cropping.
4. Choose colour or app-owned grayscale.
5. Choose A4, Letter or 10 × 15 cm paper.
6. Choose the number of copies, margins, spacing and cut marks.
7. See the Photo Cut preview update from the same document state.

### Step 2 — Review and print

8. Review the immutable final PDF and a compact settings summary.
9. Go back to edit, share the PDF or explicitly open native printing.
10. Use the matching paper at 100% / actual size in the operating-system dialog.

The native print dialog controls the destination printer and printer-specific
options. It is not a second editor for Photo Cut geometry.

## MVP requirements

- One source image per print job.
- Width and height in explicit physical units.
- A4, US Letter and 10 × 15 cm paper presets.
- Automatic portrait/landscape page orientation when it fits more copies.
- Repeated copies, page overflow and deterministic ordering.
- Crop-to-fill and fit-inside modes.
- App-owned colour or grayscale output.
- Optional cut marks.
- Resolution warning based on effective DPI.
- PDF preview, share and native print hand-off.
- One free export, then a lifetime unlock.
- Spanish and English before public release.
- Offline use and local-only image processing.

## Quality bar

The PDF page box and placed image boxes must be geometrically correct. The app
must not claim that a printer driver will honour those dimensions; it must tell
the user to print at 100% / actual size and offer a calibration sheet.

Target domain tolerance for generated PDF geometry: **±0.1 mm**. The separate
physical-print acceptance target is initially **±1 mm over 50 mm**, because
printer hardware, drivers and paper handling are outside the app's control.

## Commercial model

Planned model:

- one complete export free;
- lifetime unlock as a non-consumable in-app purchase;
- no subscription, advertising or consumable credits.

Prices and product IDs remain provisional until the store milestone.

## Explicit non-goals

- Multiple different images on the same sheet.
- Free-form element placement.
- Text, decorative templates, filters or stickers.
- Background removal or AI enhancement.
- Passport/visa/legal compliance guarantees.
- Printer-brand integrations.
- Cloud storage, account creation or multi-device sync.
- Web or desktop release in the MVP.
