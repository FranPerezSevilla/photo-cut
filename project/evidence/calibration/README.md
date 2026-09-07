# Physical calibration evidence

This folder is for the human-only `M3-H01` gate. Automated PDF tests do **not** prove that a printer driver, print service or physical printer preserves size.

## How to perform the check

1. Use the Photo Cut calibration feature and select the paper that will actually be loaded.
2. Print the generated calibration PDF through the normal Android/iPhone print route.
3. In the native print service select the same paper size.
4. Select **100% / Actual size / Tamaño real** if the print service exposes scaling.
5. Disable **Fit to page / Ajustar a página** and any borderless expansion that changes scale.
6. Measure both the horizontal and vertical sides of the reference square with a ruler.
7. Record the result in a new file named `YYYY-MM-DD-printer.md` using the template below.
8. If either dimension differs from 50 mm by more than 1 mm, investigate before release.

## Evidence template

```text
# Photo Cut physical calibration

Date:
Photo Cut commit / app version:
Phone / tablet:
Operating system:
Printer make and model:
Connection / print route:
Native print service:
Paper selected in Photo Cut:
Paper selected in print service:
Scaling setting (must be 100% / Actual size):
Fit to page disabled: yes/no
Borderless expansion disabled or accounted for: yes/no
Measured width of 50 mm square: ___ mm
Measured height of 50 mm square: ___ mm
Result: pass / investigate
Notes:
```

Do not fill this template from CI or from a simulated device. `M3-H01` requires a real print and a real measurement.
