# M2-T02 product evidence — two-step preparation and print handoff

Issue #9 records the accepted product split:

1. Photo Cut owns image selection, exact dimensions, paper, copies, margins,
   spacing and cut marks. Every valid change updates an app-owned preview.
2. A later review screen presents immutable PDF bytes and explicitly launches
   the Android/iOS native print service. The system dialog is not a second
   document-layout editor.

M2-T02 implements the first step and labels it as `Paso 1 de 2`. The review
button currently exposes an explicit development message until M2-T04 connects
the final PDF review and native handoff.
