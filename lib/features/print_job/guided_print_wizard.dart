import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/length_unit.dart';
import 'package:photo_cut/features/print_job/print_configuration_controller.dart';
import 'package:photo_cut/features/print_job/print_configuration_screen.dart';
import 'package:photo_cut/features/print_job/print_configuration_state.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/features/print_job/print_sheet_preview.dart';
import 'package:photo_cut/features/print_job/resolution_guidance.dart';
import 'package:photo_cut/features/print_job/visual_framing_editor.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

final class GuidedPrintWizard extends StatefulWidget {
  const GuidedPrintWizard({
    super.key,
    required this.image,
    this.imageProcessor,
    this.onReview,
  });

  final SelectedImage image;
  final ImageProcessor? imageProcessor;
  final PrintJobReviewCallback? onReview;

  @override
  State<GuidedPrintWizard> createState() => _GuidedPrintWizardState();
}

final class _GuidedPrintWizardState extends State<GuidedPrintWizard> {
  static const List<String> _stepTitles = <String>[
    'Tamaño final',
    'Encuadre',
    'Papel y copias',
    'Acabado',
    'Revisión',
  ];

  late final PrintConfigurationController _controller;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _controller = PrintConfigurationController(
      image: widget.image,
      imageProcessor: widget.imageProcessor ?? const DartImageProcessor(),
    );
    _controller.inspectImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar impresión')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final PrintConfigurationState state = _controller.state;
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Paso ${_step + 1} de ${_stepTitles.length} · ${_stepTitles[_step]}',
                              key: const Key('wizard-step-title'),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Text('${((_step + 1) / _stepTitles.length * 100).round()} %'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_step + 1) / _stepTitles.length,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Vista previa',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        PrintSheetPreview(
                          key: const Key('wizard-live-preview'),
                          plan: state.previewPlan,
                          configuration: state.configuration,
                          errorMessage: state.layoutError,
                        ),
                        const SizedBox(height: 20),
                        _buildStep(context, state),
                        if (state.layoutError != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            state.layoutError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _WizardNavigation(
                  step: _step,
                  stepCount: _stepTitles.length,
                  canContinue: _canContinue(state),
                  onBack: _step == 0 ? null : () => setState(() => _step -= 1),
                  onNext: () {
                    if (_step < _stepTitles.length - 1) {
                      setState(() => _step += 1);
                      return;
                    }
                    _review(context, state.configuration);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, PrintConfigurationState state) {
    return switch (_step) {
      0 => _SizeStep(state: state, controller: _controller),
      1 => _FramingStep(state: state, controller: _controller),
      2 => _PaperCopiesStep(state: state, controller: _controller),
      3 => _FinishStep(state: state, controller: _controller),
      _ => _ReviewStep(state: state),
    };
  }

  bool _canContinue(PrintConfigurationState state) {
    if (_step == 0) {
      return state.widthError == null && state.heightError == null;
    }
    if (_step == 2) {
      return state.copyCountError == null && state.layoutError == null;
    }
    if (_step == 3) {
      return state.marginError == null &&
          state.gapError == null &&
          state.layoutError == null;
    }
    if (_step == _stepTitles.length - 1) {
      return state.canReview;
    }
    return state.imageError == null;
  }

  void _review(BuildContext context, PrintJobConfiguration configuration) {
    final PrintJobReviewCallback? callback = widget.onReview;
    if (callback != null) {
      callback(context, configuration);
    }
  }
}

final class _SizeStep extends StatelessWidget {
  const _SizeStep({required this.state, required this.controller});

  final PrintConfigurationState state;
  final PrintConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '¿Qué tamaño quieres que tenga la foto en el papel?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text('Estas medidas son físicas; no son píxeles.'),
        const SizedBox(height: 16),
        SegmentedButton<LengthUnit>(
          key: const Key('wizard-length-unit'),
          segments: LengthUnit.values
              .map(
                (LengthUnit unit) => ButtonSegment<LengthUnit>(
                  value: unit,
                  label: Text(unit.shortLabel),
                ),
              )
              .toList(growable: false),
          selected: <LengthUnit>{state.unit},
          onSelectionChanged: (Set<LengthUnit> value) {
            controller.changeUnit(value.single);
          },
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _LengthField(
                key: ValueKey<String>('wizard-width-${state.unit.name}'),
                label: 'Ancho (${state.unit.shortLabel})',
                value: state.widthInput,
                error: state.widthError,
                onChanged: controller.changeWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LengthField(
                key: ValueKey<String>('wizard-height-${state.unit.name}'),
                label: 'Alto (${state.unit.shortLabel})',
                value: state.heightInput,
                error: state.heightError,
                onChanged: controller.changeHeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResolutionGuidance(configuration: state.configuration),
      ],
    );
  }
}

final class _FramingStep extends StatelessWidget {
  const _FramingStep({required this.state, required this.controller});

  final PrintConfigurationState state;
  final PrintConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '¿Cómo debe entrar la foto en esa medida?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<ImageFitMode>(
          key: const Key('wizard-fit-mode'),
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
          onSelectionChanged: (Set<ImageFitMode> value) {
            controller.changeFitMode(value.single);
          },
        ),
        const SizedBox(height: 10),
        Text(
          state.configuration.fitMode == ImageFitMode.cropToFill
              ? 'Rellenar ocupa toda la medida y puede recortar bordes. Mueve la foto para elegir el encuadre.'
              : 'Encajar conserva la foto completa y puede dejar espacio blanco.',
        ),
        const SizedBox(height: 14),
        VisualFramingEditor(
          configuration: state.configuration,
          onFocusChanged: controller.changeFocus,
        ),
      ],
    );
  }
}

final class _PaperCopiesStep extends StatelessWidget {
  const _PaperCopiesStep({required this.state, required this.controller});

  final PrintConfigurationState state;
  final PrintConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Elige papel y cuántas copias necesitas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<PaperSize>(
          key: ValueKey<String>('wizard-paper-${state.configuration.paperSize.id}'),
          initialValue: state.configuration.paperSize,
          decoration: const InputDecoration(labelText: 'Papel'),
          items: PaperSize.presets
              .map(
                (PaperSize paper) => DropdownMenuItem<PaperSize>(
                  value: paper,
                  child: Text(_paperLabel(paper)),
                ),
              )
              .toList(growable: false),
          onChanged: (PaperSize? value) {
            if (value != null) {
              controller.changePaperSize(value);
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('wizard-copy-count'),
          initialValue: state.copyCountInput,
          decoration: InputDecoration(
            labelText: 'Copias',
            errorText: state.copyCountError,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: controller.changeCopyCount,
        ),
        const SizedBox(height: 8),
        const Text('La vista previa te muestra inmediatamente cómo se distribuyen.'),
      ],
    );
  }
}

final class _FinishStep extends StatelessWidget {
  const _FinishStep({required this.state, required this.controller});

  final PrintConfigurationState state;
  final PrintConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Últimos detalles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        SegmentedButton<ImageColorMode>(
          key: const Key('wizard-color-mode'),
          segments: const <ButtonSegment<ImageColorMode>>[
            ButtonSegment<ImageColorMode>(
              value: ImageColorMode.color,
              label: Text('Color'),
            ),
            ButtonSegment<ImageColorMode>(
              value: ImageColorMode.grayscale,
              label: Text('Blanco y negro'),
            ),
          ],
          selected: <ImageColorMode>{state.configuration.colorMode},
          onSelectionChanged: (Set<ImageColorMode> value) {
            controller.changeColorMode(value.single);
          },
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          key: const Key('wizard-advanced-options'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Opciones avanzadas'),
          subtitle: const Text('Margen, separación y marcas de corte'),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _LengthField(
                    key: ValueKey<String>('wizard-margin-${state.unit.name}'),
                    label: 'Margen (${state.unit.shortLabel})',
                    value: state.marginInput,
                    error: state.marginError,
                    onChanged: controller.changeMargin,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LengthField(
                    key: ValueKey<String>('wizard-gap-${state.unit.name}'),
                    label: 'Separación (${state.unit.shortLabel})',
                    value: state.gapInput,
                    error: state.gapError,
                    onChanged: controller.changeGap,
                  ),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              key: const Key('wizard-cut-marks'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Marcas de corte'),
              value: state.configuration.showCutMarks,
              onChanged: controller.changeCutMarks,
            ),
          ],
        ),
      ],
    );
  }
}

final class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});

  final PrintConfigurationState state;

  @override
  Widget build(BuildContext context) {
    final PrintJobConfiguration configuration = state.configuration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Comprueba el resultado',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Text(
          '${_formatMillimetres(configuration.photoWidth)} × '
          '${_formatMillimetres(configuration.photoHeight)} mm · '
          '${configuration.copyCount} copias · ${_paperLabel(configuration.paperSize)}',
          key: const Key('wizard-summary'),
        ),
        const SizedBox(height: 12),
        ResolutionGuidance(configuration: configuration),
        const SizedBox(height: 8),
        const Text(
          'Al continuar verás el PDF final e inmutable antes de compartirlo o imprimirlo.',
        ),
      ],
    );
  }
}

final class _LengthField extends StatelessWidget {
  const _LengthField({
    super.key,
    required this.label,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, errorText: error),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: onChanged,
    );
  }
}

final class _WizardNavigation extends StatelessWidget {
  const _WizardNavigation({
    required this.step,
    required this.stepCount,
    required this.canContinue,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int stepCount;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: <Widget>[
              if (onBack != null)
                TextButton.icon(
                  key: const Key('wizard-back'),
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Atrás'),
                )
              else
                const Spacer(),
              if (onBack != null) const Spacer(),
              FilledButton.icon(
                key: const Key('wizard-next'),
                onPressed: canContinue ? onNext : null,
                icon: Icon(
                  step == stepCount - 1 ? Icons.check : Icons.arrow_forward,
                ),
                label: Text(
                  step == stepCount - 1 ? 'Revisar PDF' : 'Siguiente',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _paperLabel(PaperSize paper) {
  if (paper == PaperSize.a4) {
    return 'A4';
  }
  if (paper == PaperSize.usLetter) {
    return 'Carta';
  }
  if (paper == PaperSize.photo10x15) {
    return '10 × 15 cm';
  }
  return paper.id;
}

String _formatMillimetres(PhysicalLength length) {
  final double value = length.inMillimetres;
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
