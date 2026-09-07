# M2-T07 visual framing interaction

The Step 1 crop interaction now works on the photograph itself rather than two
abstract horizontal/vertical sliders.

- `Rellenar` shows the exact target aspect and asks the user to move the photo to
  choose what remains inside.
- Dragging maps directly into the existing normalized `focus` value through
  `VisualFramingMapper`; no second crop model or freeform editor is introduced.
- Wide sources move horizontally and tall sources move vertically, matching the
  actual overflow created by `BoxFit.cover`.
- `Centrar` resets the focus and double-tap on the crop frame does the same.
- `Encajar` is visibly different: the complete image is shown with no drag or
  crop interaction.
- Switching between `Rellenar` and `Encajar` preserves the normalized focus, so
  returning to `Rellenar` restores the prior framing.

Issue #14 remains open because the separate M2-T08 task still has to add the
persistent one-tap PDF preview with zoom, pan and reset.
