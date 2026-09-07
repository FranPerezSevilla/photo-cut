#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'Expected text not found in {path}: {old[:120]!r}')
    if text.count(old) != 1:
        raise SystemExit(f'Expected exactly one match in {path}, found {text.count(old)}')
    path.write_text(text.replace(old, new), encoding='utf-8')


crop_barrel = ROOT / 'lib/core/crop/crop.dart'
replace_once(
    crop_barrel,
    "export 'source_image_size.dart';\n",
    "export 'source_image_size.dart';\nexport 'visual_framing_mapper.dart';\n",
)

print_job_barrel = ROOT / 'lib/features/print_job/print_job.dart'
replace_once(
    print_job_barrel,
    "export 'resolution_guidance.dart';\n",
    "export 'resolution_guidance.dart';\nexport 'visual_framing_editor.dart';\n",
)

controller = ROOT / 'lib/features/print_job/print_configuration_controller.dart'
controller_text = controller.read_text(encoding='utf-8')
controller_text = controller_text.replace('_changeFocus(', 'changeFocus(')
if 'void changeFocus(NormalizedPoint focus)' not in controller_text:
    raise SystemExit('Controller focus method was not promoted to the public API')
controller.write_text(controller_text, encoding='utf-8')

screen = ROOT / 'lib/features/print_job/print_configuration_screen.dart'
screen_text = screen.read_text(encoding='utf-8')
import_line = (
    "import 'package:photo_cut/features/print_job/resolution_guidance.dart';\n"
)
if "visual_framing_editor.dart" not in screen_text:
    screen_text = screen_text.replace(
        import_line,
        import_line
        + "import 'package:photo_cut/features/print_job/visual_framing_editor.dart';\n",
    )

start_marker = (
    "                      if (state.configuration.fitMode ==\n"
    "                          ImageFitMode.cropToFill) ...<Widget>[\n"
)
end_marker = (
    "                      const SizedBox(height: 14),\n"
    "                      const _ControlLabel(\n"
    "                        label: 'Color',\n"
)
start = screen_text.find(start_marker)
end = screen_text.find(end_marker, start)
if start < 0 or end < 0:
    raise SystemExit('Could not locate the old framing-slider block')

new_block = """                      const SizedBox(height: 14),
                      const _ControlLabel(
                        label: 'Encuadre',
                        topic: ConfigurationHelpTopic.framing,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.configuration.fitMode == ImageFitMode.cropToFill
                            ? 'Mueve la foto para elegir qué parte queda dentro.'
                            : 'La foto completa quedará dentro del marco, sin recorte.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      VisualFramingEditor(
                        configuration: state.configuration,
                        onFocusChanged: _controller.changeFocus,
                      ),
"""
screen_text = screen_text[:start] + new_block + screen_text[end:]

focus_start = screen_text.find('String _focusLabel(')
paper_start = screen_text.find('String _paperLabel(', focus_start)
if focus_start >= 0:
    if paper_start < 0:
        raise SystemExit('Could not locate paper label after focus helper')
    screen_text = screen_text[:focus_start] + screen_text[paper_start:]

screen.write_text(screen_text, encoding='utf-8')

print('Applied M2-T07 visual framing patch.')
