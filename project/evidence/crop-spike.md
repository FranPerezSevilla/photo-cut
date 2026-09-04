# M2-T03 crop spike

## Question

Does Photo Cut need a third-party interactive crop widget for the MVP, or can a
smaller app-owned model provide a reliable crop-to-fill and fit-inside flow?

## Evaluation

`crop_your_image` 2.0.0 was reviewed. It can provide a movable crop area and
fixed aspect ratios, but adopting it would introduce a second visual editor and a
second source of crop coordinates alongside Photo Cut's sheet preview.

The product requirement is narrower:

- one exact output aspect;
- either show the whole image or fill the output rectangle;
- let the user choose which part remains visible;
- persist state independently from widgets;
- reproduce exactly the same choice in the final PDF.

## Result

The package is **not retained** for the MVP.

Photo Cut stores a focus point and a normalized source rectangle. `CropPlanner`
uses the orientation-aware source ratio and exact target ratio to calculate that
rectangle. The preparation screen shows the result directly in the real sheet
layout and exposes horizontal/vertical focus sliders only when cropping is
necessary.

`ImageProcessor`, backed by `image` 4.9.2, bakes EXIF orientation and applies the
same normalized crop and colour mode to output bytes. Fit-inside preserves the
full image without distortion. Grayscale is app-owned, so it is visible before
Android's printer dialog.

## Revisit trigger

Reconsider an interactive crop package only if real users cannot place the
subject adequately with the focus controls or need arbitrary rotation/freeform
crop. That change must preserve normalized state and final-PDF parity.
