# M2-T04 product evidence — final review and native handoff

The implementation follows issue #9:

1. Photo Cut owns all document settings and the live preparation preview.
2. `PrintJobDocumentFactory` creates one immutable, stable-named PDF.
3. A separate `Paso 2 de 2` screen previews that PDF and summarises its settings.
4. `Volver y editar` restores the still-live configuration route.
5. `Compartir PDF` and `Abrir impresión de Android/iPhone` receive the same
   `PrintDocument`; the native service is not allowed to reflow the document.

The integration-style widget test uses fake platform gateways to verify the
complete happy path without claiming that CI operated a real printer or share
sheet.
