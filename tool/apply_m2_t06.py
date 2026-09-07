from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    if old not in text:
        raise SystemExit(f'Missing {label} anchor')
    return text.replace(old, new, 1)


def replace_range(text: str, start_marker: str, end_marker: str, replacement: str, label: str) -> str:
    start = text.find(start_marker)
    if start < 0:
        raise SystemExit(f'Missing {label} start marker')
    end = text.find(end_marker, start)
    if end < 0:
        raise SystemExit(f'Missing {label} end marker')
    return text[:start] + replacement + text[end:]


def main() -> None:
    screen_path = Path('lib/features/print_job/print_configuration_screen.dart')
    screen = screen_path.read_text(encoding='utf-8')
    screen = replace_once(
        screen,
        "import 'package:photo_cut/features/print_job/length_unit.dart';\n",
        "import 'package:photo_cut/features/print_job/configuration_help.dart';\n"
        "import 'package:photo_cut/features/print_job/length_unit.dart';\n",
        'configuration-help import',
    )

    adjustment_start = (
        "                      const _SectionTitle(\n"
        "                        title: 'Ajuste de la foto',\n"
    )
    size_start = (
        "                      const SizedBox(height: 24),\n"
        "                      const _SectionTitle(\n"
        "                        title: 'Tamaño de cada foto',\n"
    )
    adjustment = """                      const _SectionTitle(
                        title: 'Ajuste de la foto',
                        subtitle:
                            'Decide qué parte de la imagen entra y cómo se verá en el PDF.',
                      ),
                      const SizedBox(height: 10),
                      const _ControlLabel(
                        label: 'Rellenar o encajar',
                        topic: ConfigurationHelpTopic.fitMode,
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<ImageFitMode>(
                        key: const Key('fit-mode-selector'),
                        segments: const <ButtonSegment<ImageFitMode>>[
                          ButtonSegment<ImageFitMode>(
                            value: ImageFitMode.cropToFill,
                            icon: Icon(Icons.crop),
                            label: Text('Rellenar'),
                          ),
                          ButtonSegment<ImageFitMode>(
                            value: ImageFitMode.fitInside,
                            icon: Icon(Icons.fit_screen_outlined),
                            label: Text('Encajar'),
                          ),
                        ],
                        selected: <ImageFitMode>{state.configuration.fitMode},
                        onSelectionChanged: (Set<ImageFitMode> selection) {
                          _controller.changeFitMode(selection.single);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.configuration.fitMode == ImageFitMode.cropToFill
                            ? 'Rellena la medida exacta y recorta lo que sobre.'
                            : 'Muestra la foto completa sin deformarla; pueden quedar bordes blancos.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (state.configuration.fitMode ==
                          ImageFitMode.cropToFill) ...<Widget>[
                        const SizedBox(height: 14),
                        const _ControlLabel(
                          label: 'Encuadre',
                          topic: ConfigurationHelpTopic.framing,
                        ),
                        Text(
                          'Ajusta qué parte queda dentro. En el siguiente pase UX podrás mover la foto directamente.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Horizontal · Izquierda — Centro — Derecha',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Slider(
                          key: const Key('crop-focus-x'),
                          value: state.configuration.focus.x,
                          onChanged: _controller.changeFocusX,
                          divisions: 100,
                          label: _focusLabel(
                            state.configuration.focus.x,
                            start: 'Izquierda',
                            middle: 'Centro',
                            end: 'Derecha',
                          ),
                        ),
                        Text(
                          'Vertical · Arriba — Centro — Abajo',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Slider(
                          key: const Key('crop-focus-y'),
                          value: state.configuration.focus.y,
                          onChanged: _controller.changeFocusY,
                          divisions: 100,
                          label: _focusLabel(
                            state.configuration.focus.y,
                            start: 'Arriba',
                            middle: 'Centro',
                            end: 'Abajo',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const _ControlLabel(
                        label: 'Color',
                        topic: ConfigurationHelpTopic.colorMode,
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<ImageColorMode>(
                        key: const Key('color-mode-selector'),
                        segments: const <ButtonSegment<ImageColorMode>>[
                          ButtonSegment<ImageColorMode>(
                            value: ImageColorMode.color,
                            icon: Icon(Icons.palette_outlined),
                            label: Text('Color'),
                          ),
                          ButtonSegment<ImageColorMode>(
                            value: ImageColorMode.grayscale,
                            icon: Icon(Icons.tonality_outlined),
                            label: Text('Blanco y negro'),
                          ),
                        ],
                        selected: <ImageColorMode>{
                          state.configuration.colorMode,
                        },
                        onSelectionChanged: (Set<ImageColorMode> selection) {
                          _controller.changeColorMode(selection.single);
                        },
                      ),
"""
    screen = replace_range(
        screen,
        adjustment_start,
        size_start,
        adjustment,
        'adjustment section',
    )

    screen = replace_once(
        screen,
        "                      const SizedBox(height: 12),\n"
        "                      SegmentedButton<LengthUnit>(\n"
        "                        key: const Key('length-unit-selector'),\n",
        "                      const SizedBox(height: 10),\n"
        "                      const _ControlLabel(\n"
        "                        label: 'Unidad',\n"
        "                        topic: ConfigurationHelpTopic.unit,\n"
        "                      ),\n"
        "                      const SizedBox(height: 6),\n"
        "                      SegmentedButton<LengthUnit>(\n"
        "                        key: const Key('length-unit-selector'),\n",
        'unit label',
    )
    screen = replace_once(
        screen,
        "                                labelText: 'Ancho (${state.unit.shortLabel})',\n"
        "                                errorText: state.widthError,\n",
        "                                labelText: 'Ancho (${state.unit.shortLabel})',\n"
        "                                errorText: state.widthError,\n"
        "                                suffixIcon: const ConfigurationHelpButton(\n"
        "                                  topic: ConfigurationHelpTopic.width,\n"
        "                                ),\n",
        'width help',
    )
    screen = replace_once(
        screen,
        "                                labelText: 'Alto (${state.unit.shortLabel})',\n"
        "                                errorText: state.heightError,\n",
        "                                labelText: 'Alto (${state.unit.shortLabel})',\n"
        "                                errorText: state.heightError,\n"
        "                                suffixIcon: const ConfigurationHelpButton(\n"
        "                                  topic: ConfigurationHelpTopic.height,\n"
        "                                ),\n",
        'height help',
    )
    screen = replace_once(
        screen,
        "                        decoration: const InputDecoration(\n"
        "                          labelText: 'Tamaño del papel',\n"
        "                        ),\n",
        "                        decoration: const InputDecoration(\n"
        "                          labelText: 'Tamaño del papel',\n"
        "                          suffixIcon: ConfigurationHelpButton(\n"
        "                            topic: ConfigurationHelpTopic.paper,\n"
        "                          ),\n"
        "                        ),\n",
        'paper help',
    )
    screen = replace_once(
        screen,
        "                        decoration: InputDecoration(\n"
        "                          labelText: 'Número de copias',\n"
        "                          errorText: state.copyCountError,\n"
        "                        ),\n",
        "                        decoration: InputDecoration(\n"
        "                          labelText: 'Número de copias',\n"
        "                          errorText: state.copyCountError,\n"
        "                          suffixIcon: const ConfigurationHelpButton(\n"
        "                            topic: ConfigurationHelpTopic.copies,\n"
        "                          ),\n"
        "                        ),\n",
        'copies help',
    )

    advanced_start = (
        "                      const SizedBox(height: 24),\n"
        "                      const _SectionTitle(\n"
        "                        title: 'Separación y corte',\n"
    )
    guidance_marker = "                      ResolutionGuidance(configuration: state.configuration),\n"
    advanced = """                      const SizedBox(height: 20),
                      Card(
                        child: ExpansionTile(
                          key: const Key('advanced-options'),
                          initiallyExpanded: false,
                          title: const Text('Opciones avanzadas'),
                          subtitle: const Text(
                            'Margen, separación y marcas de corte',
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: <Widget>[
                            Text(
                              'Los valores por defecto funcionan para la mayoría de impresiones.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey<String>(
                                      'margin-${state.unit.name}',
                                    ),
                                    initialValue: state.marginInput,
                                    decoration: InputDecoration(
                                      labelText: 'Margen (${state.unit.shortLabel})',
                                      errorText: state.marginError,
                                      suffixIcon: const ConfigurationHelpButton(
                                        topic: ConfigurationHelpTopic.margin,
                                      ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,]'),
                                      ),
                                    ],
                                    onChanged: _controller.changeMargin,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey<String>('gap-${state.unit.name}'),
                                    initialValue: state.gapInput,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Separación (${state.unit.shortLabel})',
                                      errorText: state.gapError,
                                      suffixIcon: const ConfigurationHelpButton(
                                        topic: ConfigurationHelpTopic.gap,
                                      ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,]'),
                                      ),
                                    ],
                                    onChanged: _controller.changeGap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SwitchListTile.adaptive(
                              key: const Key('cut-marks'),
                              contentPadding: EdgeInsets.zero,
                              title: const Row(
                                children: <Widget>[
                                  Expanded(child: Text('Marcas de corte')),
                                  ConfigurationHelpButton(
                                    topic: ConfigurationHelpTopic.cutMarks,
                                  ),
                                ],
                              ),
                              subtitle: const Text(
                                'Añade guías finas alrededor de cada copia.',
                              ),
                              value: state.configuration.showCutMarks,
                              onChanged: _controller.changeCutMarks,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
"""
    screen = replace_range(
        screen,
        advanced_start,
        guidance_marker,
        advanced,
        'advanced options section',
    )

    control_label = """
final class _ControlLabel extends StatelessWidget {
  const _ControlLabel({required this.label, required this.topic});

  final String label;
  final ConfigurationHelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        ConfigurationHelpButton(topic: topic),
      ],
    );
  }
}

"""
    marker = "final class _SectionTitle extends StatelessWidget {\n"
    if control_label not in screen:
        if marker not in screen:
            raise SystemExit('Missing SectionTitle class marker')
        screen = screen.replace(marker, control_label + marker, 1)

    screen_path.write_text(screen, encoding='utf-8')

    barrel_path = Path('lib/features/print_job/print_job.dart')
    barrel = barrel_path.read_text(encoding='utf-8')
    export = "export 'configuration_help.dart';\n"
    if export not in barrel:
        barrel = export + barrel
    barrel_path.write_text(barrel, encoding='utf-8')

    test_path = Path('test/features/print_job/print_configuration_screen_test.dart')
    test = test_path.read_text(encoding='utf-8')
    old = """    expect(
      find.text(
        'Muestra la foto completa sin deformarla; pueden quedar bordes blancos.',
      ),
      findsOneWidget,
    );

"""
    new = """    final SegmentedButton<ImageFitMode> fitControl =
        tester.widget<SegmentedButton<ImageFitMode>>(fitSelector);
    expect(fitControl.selected, <ImageFitMode>{ImageFitMode.fitInside});

"""
    if old in test:
        test = test.replace(old, new, 1)
    test_path.write_text(test, encoding='utf-8')


if __name__ == '__main__':
    main()
