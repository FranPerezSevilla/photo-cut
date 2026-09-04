# M2-T03 evidence — crop, fit, orientation and grayscale

Focused preparation run `33912381609` and complete Android/iOS PR CI run `33912622500` passed.

The implementation stores crop state in normalized source coordinates, calculates crop-to-fill from the exact target aspect, preserves the whole image for fit-inside, bakes EXIF orientation locally and applies app-owned grayscale. The Photo Cut preview and final processing state use the same fit, focus, crop and colour choices.

`crop_your_image` was evaluated and deliberately not retained for the MVP; the narrower focus-control approach avoids a second crop state while remaining deterministic and testable.
