from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'Missing expected anchor in {path}: {old!r}')
    path.write_text(text.replace(old, new, 1), encoding='utf-8')


def main() -> None:
    screen_path = Path('lib/features/print_job/print_configuration_screen.dart')
    replace_once(
        screen_path,
        "import 'package:photo_cut/features/print_job/print_sheet_preview.dart';\n",
        "import 'package:photo_cut/features/print_job/print_sheet_preview.dart';\n"
        "import 'package:photo_cut/features/print_job/resolution_guidance.dart';\n",
    )
    replace_once(
        screen_path,
        "                      if (state.layoutError != null) ...<Widget>[\n",
        "                      ResolutionGuidance(\n"
        "                        configuration: state.configuration,\n"
        "                      ),\n"
        "                      const SizedBox(height: 12),\n"
        "                      if (state.layoutError != null) ...<Widget>[\n",
    )

    product_path = Path('project/product.md')
    product = product_path.read_text(encoding='utf-8')
    if '### Effective-resolution guidance' not in product:
        marker = '\n## Commercial model\n'
        if marker not in product:
            raise SystemExit('Missing product commercial-model marker')
        block = """

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
"""
        product_path.write_text(
            product.replace(marker, block + marker, 1),
            encoding='utf-8',
        )

    architecture_path = Path('project/architecture.md')
    architecture = architecture_path.read_text(encoding='utf-8')
    if 'effective-resolution guidance' not in architecture:
        marker = 'The native print screen is a printer handoff, not a second document editor.\n'
        addition = (
            marker
            + '\nPure `core/quality` logic calculates effective-resolution guidance from '
            + 'orientation-aware source pixels, normalized crop state and exact physical '
            + 'output size. UI warnings consume that advice but never modify geometry.\n'
        )
        if marker not in architecture:
            raise SystemExit('Missing architecture print-screen marker')
        architecture_path.write_text(
            architecture.replace(marker, addition, 1),
            encoding='utf-8',
        )

    changelog_path = Path('CHANGELOG.md')
    changelog = changelog_path.read_text(encoding='utf-8')
    addition = (
        '- Non-blocking effective-resolution guidance based on post-crop pixels '
        'and exact physical output size.\n'
    )
    if addition not in changelog:
        changelog_path.write_text(
            changelog.rstrip() + '\n' + addition,
            encoding='utf-8',
        )


if __name__ == '__main__':
    main()
