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

### Select and understand the photo

1. Select one image from the device.
2. Show its pixel dimensions immediately.
3. Show illustrative physical sizes at reference resolutions such as 300 and
   600 ppp, while stating clearly that a digital image has no single physical
   size until the user chooses one.

### Guided configuration

4. Ask for the exact final width and height first, in mm, cm or inches.
5. Keep a live sheet preview visible while the user advances through the wizard.
6. Choose crop-to-fill or fit-inside and adjust the visual framing when needed.
7. Choose paper and copy count and see the layout update immediately.
8. Choose colour/grayscale and optionally open advanced margin, spacing and
   cut-mark controls.
9. Review a compact summary before producing the final PDF.

The wizard presents one decision group at a time. It must not expose the whole
configuration form at once or make the user switch between a settings screen and
a separate preview screen for ordinary configuration.

### Review and print

10. Review the immutable final PDF and a compact settings summary.
11. Go back to edit, share the PDF or explicitly open native printing.
12. Use the matching paper at 100% / actual size in the operating-system dialog.

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

### Effective-resolution guidance

Photo Cut estimates effective image resolution from the pixels that remain after
crop and the exact physical image size. `Fit inside` measures only the physical
area occupied by the image, not any white letterboxing.

The MVP thresholds are deliberately guidance, not print guarantees:

- **300 ppp or more:** high reference quality; no warning.
- **200–299 ppp:** good reference quality; no warning.
- **150–199 ppp:** caution; detail may look softer.
- **Below 150 ppp:** low-resolution warning; softness or pixelation is likely.

Warnings never block PDF generation and never change requested physical
measurements. Printer, paper, viewing distance and source-image quality still
affect the final result.

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
