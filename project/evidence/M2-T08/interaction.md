# M2-T08 persistent PDF preview interaction

Issue #14's remaining preview feedback is implemented as a fixed Step 1 switch:

- `Ajustes` preserves the existing configuration form and its state.
- `Vista previa` generates the actual current PDF on demand with the same
  `PrintJobDocumentFactory` used by final review.
- The generated PDF is cached while settings remain unchanged, so switching back
  and forth does not create another print job or reprocess the image needlessly.
- Invalid form values show a clear preview-unavailable state instead of reusing a
  stale document.
- The PDF viewer supports pinch-to-zoom, pan and `Encajar página` reset.
- Zoom transformation state lives only in the viewer and is explicitly described
  in-app as not changing physical PDF measurements.

The lightweight sheet preview at the top of Ajustes is retained for now as quick
feedback while editing. The fixed preview switch removes the need to scroll back
to it for detailed PDF inspection; a later UX pass may remove the quick preview
if real-device testing finds the duplication unnecessary.
