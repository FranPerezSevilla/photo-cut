import 'dart:async';
import 'dart:math' as math;

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
    'Tamaño',
    'Encuadre',
    'Hoja',
    'Revisar',
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
    unawaited(_controller.inspectImage());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preparar foto')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final PrintConfigurationState state = _controller.state;
            final double previewHeight = math.min(
              220,
              MediaQuery.sizeOf(context).height * 0.27,
            );

            return Column(
              children: <Widget>[
                _WizardProgress(
                  step: _step,
                  stepCount: _stepTitles.length,
                  title: _stepTitles[_step],
                ),
                _PreviewPanel(height: previewHeight, state: state),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      key: const Key('wizard-step-scroll'),
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      child: _buildStep(context, state),
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
      2 => _SheetStep(state: state, controller: _controller),
      _ => _ReviewStep(state: state, controller: _controller),
    };
  }

  bool _canContinue(PrintConfigurationState state) {
    if (_step == 0) {
      return state.widthError == null &&
          state.heightError == null &&
          state.layoutError == null;
    }
    if (_step == 2) {
      return state.copyCountError == null &&
          state.marginError == null &&
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

final class _WizardProgress extends StatelessWidget {
  const _WizardProgress({
    required this.step,
    required this.stepCount,
    required this.title,
  });

  final int step;
  final int stepCount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Paso ${step + 1} de $stepCount · $title',
                  key: const Key('wizard-step-title'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '${step + 1}/$stepCount',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: (step + 1) / stepCount,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
          ),
        ],
      ),
    );
  }
}

final class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.height, required this.state});

  final double height;
  final PrintConfigurationState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.topCenter,
          child: PrintSheetPreview(
            key: const Key('wizard-live-preview'),
            plan: state.previewPlan,
            configuration: state.configuration,
            errorMessage: state.layoutError,
            maxPageHeight: height - 30,
          ),
        ),
      ),
    );
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
          '¿Qué tamaño quieres imprimir?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Elige un tamaño habitual o escribe el tuyo.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _SizePresetCard(
              key: const Key('size-preset-35x45'),
              label: '35 × 45 mm',
              caption: 'Carné y documentos',
              selected: _matchesMillimetres(state, 35, 45),
              onTap: () => _applyMillimetrePreset(controller, 35, 45),
            ),
            _SizePresetCard(
              key: const Key('size-preset-10x15'),
              label: '10 × 15 cm',
              caption: 'Foto clásica',
              selected: _matchesMillimetres(state, 100, 150),
              onTap: () => _applyMillimetrePreset(controller, 100, 150),
            ),
            _SizePresetCard(
              key: const Key('size-preset-13x18'),
              label: '13 × 18 cm',
              caption: 'Copia grande',
              selected: _matchesMillimetres(state, 130, 180),
              onTap: () => _applyMillimetrePreset(controller, 130, 180),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Tamaño personalizado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _UnitSelector(state: state, controller: controller),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _LengthField(
                key: ValueKey<String>(
                  'wizard-width-${state.unit.name}-${state.widthInput}',
                ),
                label: 'Ancho',
                suffix: state.unit.shortLabel,
                value: state.widthInput,
                error: state.widthError,
                onChanged: controller.changeWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LengthField(
                key: ValueKey<String>(
                  'wizard-height-${state.unit.name}-${state.heightInput}',
                ),
                label: 'Alto',
                suffix: state.unit.shortLabel,
                value: state.heightInput,
                error: state.heightError,
                onChanged: controller.changeHeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
    final bool fill = state.configuration.fitMode == ImageFitMode.cropToFill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Encuadre', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Decide si quieres llenar todo el marco o conservar la foto completa.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Row(
          key: const Key('wizard-fit-mode'),
          children: <Widget>[
            Expanded(
              child: _ChoiceCard(
                icon: Icons.crop_rounded,
                title: 'Rellenar',
                subtitle: 'Sin bordes blancos',
                selected: fill,
                onTap: () => controller.changeFitMode(ImageFitMode.cropToFill),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceCard(
                icon: Icons.fit_screen_rounded,
                title: 'Foto completa',
                subtitle: 'No recorta nada',
                selected: !fill,
                onTap: () => controller.changeFitMode(ImageFitMode.fitInside),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (fill) ...<Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.pan_tool_alt_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                'Arrastra la foto para encuadrar',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          VisualFramingEditor(
            configuration: state.configuration,
            onFocusChanged: controller.changeFocus,
          ),
        ] else
          const _CompletePhotoNotice(),
      ],
    );
  }
}

final class _CompletePhotoNotice extends StatelessWidget {
  const _CompletePhotoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('fit-inside-static-notice'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.check_circle_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Se conservará toda la foto centrada. Si la proporción no coincide, quedará espacio blanco alrededor; no hay nada que mover.',
            ),
          ),
        ],
      ),
    );
  }
}

final class _SheetStep extends StatelessWidget {
  const _SheetStep({required this.state, required this.controller});

  final PrintConfigurationState state;
  final PrintConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Hoja', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Elige dónde imprimir y cuántas copias necesitas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Text('Papel', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PaperSize.presets
              .map(
                (PaperSize paper) => _PaperCard(
                  key: ValueKey<String>('wizard-paper-${paper.id}'),
                  paper: paper,
                  selected: paper == state.configuration.paperSize,
                  onTap: () => controller.changePaperSize(paper),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 22),
        Text('Copias', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _CopyStepper(
          key: const Key('wizard-copy-count'),
          value: state.configuration.copyCount,
          error: state.copyCountError,
          onChanged: (int value) => controller.changeCopyCount('$value'),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          key: const Key('wizard-advanced-options'),
          onPressed: () => _openSheetSettings(context, controller),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Ajustes de hoja e imagen'),
        ),
      ],
    );
  }
}

final class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state, required this.controller});

  final PrintConfigurationState state;
  final PrintConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    final PrintJobConfiguration configuration = state.configuration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Todo listo', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Comprueba los datos antes de generar el PDF final.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        _SummaryCard(
          rows: <_SummaryRow>[
            _SummaryRow(
              label: 'Foto',
              value:
                  '${_formatMillimetres(configuration.photoWidth)} × ${_formatMillimetres(configuration.photoHeight)} mm',
            ),
            _SummaryRow(
              label: 'Encuadre',
              value: configuration.fitMode == ImageFitMode.cropToFill
                  ? 'Rellenar'
                  : 'Foto completa',
            ),
            _SummaryRow(
              label: 'Papel',
              value: _paperLabel(configuration.paperSize),
            ),
            _SummaryRow(label: 'Copias', value: '${configuration.copyCount}'),
            _SummaryRow(
              label: 'Imagen',
              value: configuration.colorMode == ImageColorMode.color
                  ? 'Color'
                  : 'Blanco y negro',
            ),
          ],
        ),
        const SizedBox(height: 14),
        ResolutionGuidance(configuration: configuration),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _openSheetSettings(context, controller),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Revisar ajustes avanzados'),
        ),
      ],
    );
  }
}

final class _SizePresetCard extends StatelessWidget {
  const _SizePresetCard({
    super.key,
    required this.label,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 156,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(caption, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _UnitSelector extends StatelessWidget {
  const _UnitSelector({required this.state, required this.controller});

  final PrintConfigurationState state;
  final PrintConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('wizard-length-unit'),
      mainAxisSize: MainAxisSize.min,
      children: LengthUnit.values
          .map(
            (LengthUnit unit) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text(unit.shortLabel),
                selected: unit == state.unit,
                onSelected: (_) => controller.changeUnit(unit),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

final class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? colors.primary : colors.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: selected ? colors.primary : colors.onSurface),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PaperCard extends StatelessWidget {
  const _PaperCard({
    super.key,
    required this.paper,
    required this.selected,
    required this.onTap,
  });

  final PaperSize paper;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.description_outlined,
                  color: selected ? colors.primary : colors.onSurface,
                ),
                const SizedBox(height: 8),
                Text(
                  _paperLabel(paper),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _CopyStepper extends StatelessWidget {
  const _CopyStepper({
    super.key,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final int value;
  final String? error;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              _StepperButton(
                key: const Key('copies-minus'),
                icon: Icons.remove_rounded,
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _StepperButton(
                key: const Key('copies-plus'),
                icon: Icons.add_rounded,
                onPressed: value < 999 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

final class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<_SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('wizard-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: rows
            .map(
              (_SummaryRow row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      row.value,
                      style: Theme.of(context).textTheme.labelLarge,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

final class _SummaryRow {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;
}

final class _LengthField extends StatelessWidget {
  const _LengthField({
    super.key,
    required this.label,
    required this.suffix,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final String value;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        errorText: error,
      ),
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
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: <Widget>[
              if (onBack != null)
                TextButton(
                  key: const Key('wizard-back'),
                  onPressed: onBack,
                  child: const Text('Atrás'),
                )
              else
                const SizedBox(width: 72),
              const Spacer(),
              SizedBox(
                width: 154,
                child: FilledButton(
                  key: const Key('wizard-next'),
                  onPressed: canContinue ? onNext : null,
                  child: Text(
                    step == stepCount - 1 ? 'Revisar PDF' : 'Siguiente',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openSheetSettings(
  BuildContext context,
  PrintConfigurationController controller,
) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            final PrintConfigurationState state = controller.state;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Ajustes de hoja e imagen',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Opciones que normalmente no necesitas tocar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Imagen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.palette_outlined,
                          title: 'Color',
                          subtitle: 'Original',
                          selected:
                              state.configuration.colorMode ==
                              ImageColorMode.color,
                          onTap: () =>
                              controller.changeColorMode(ImageColorMode.color),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.monochrome_photos_outlined,
                          title: 'B/N',
                          subtitle: 'Escala de grises',
                          selected:
                              state.configuration.colorMode ==
                              ImageColorMode.grayscale,
                          onTap: () => controller.changeColorMode(
                            ImageColorMode.grayscale,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Distribución',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _LengthField(
                          key: ValueKey<String>(
                            'wizard-margin-${state.unit.name}-${state.marginInput}',
                          ),
                          label: 'Margen',
                          suffix: state.unit.shortLabel,
                          value: state.marginInput,
                          error: state.marginError,
                          onChanged: controller.changeMargin,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LengthField(
                          key: ValueKey<String>(
                            'wizard-gap-${state.unit.name}-${state.gapInput}',
                          ),
                          label: 'Separación',
                          suffix: state.unit.shortLabel,
                          value: state.gapInput,
                          error: state.gapError,
                          onChanged: controller.changeGap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    key: const Key('wizard-cut-marks'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Marcas de corte'),
                    subtitle: const Text(
                      'Añade guías para recortar después de imprimir.',
                    ),
                    value: state.configuration.showCutMarks,
                    onChanged: controller.changeCutMarks,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

void _applyMillimetrePreset(
  PrintConfigurationController controller,
  double width,
  double height,
) {
  controller.changeUnit(LengthUnit.millimetres);
  controller.changeWidth(_compactNumber(width));
  controller.changeHeight(_compactNumber(height));
}

bool _matchesMillimetres(
  PrintConfigurationState state,
  double width,
  double height,
) {
  final PrintJobConfiguration configuration = state.configuration;
  return (configuration.photoWidth.inMillimetres - width).abs() < 0.001 &&
      (configuration.photoHeight.inMillimetres - height).abs() < 0.001;
}

String _compactNumber(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String _paperLabel(PaperSize paper) {
  if (paper == PaperSize.a4) {
    return 'A4';
  }
  if (paper == PaperSize.usLetter) {
    return 'Carta';
  }
  if (paper == PaperSize.photo10x15) {
    return '10 × 15';
  }
  return paper.id;
}

String _formatMillimetres(PhysicalLength length) {
  final double value = length.inMillimetres;
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
