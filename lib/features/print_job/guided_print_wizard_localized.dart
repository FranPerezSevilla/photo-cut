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
import 'package:photo_cut/l10n/photo_cut_localizations.dart';
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
  late final PrintConfigurationController _controller;
  late Uint8List _livePreviewBytes;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _livePreviewBytes = Uint8List.fromList(widget.image.bytes);
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    final List<String> stepTitles = <String>[
      l10n.text('size'),
      l10n.text('framing'),
      l10n.text('sheet'),
      l10n.text('review'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('preparePhoto'))),
      bottomNavigationBar: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return _WizardNavigation(
            step: _step,
            stepCount: stepTitles.length,
            canContinue: _canContinue(_controller.state, stepTitles.length),
            onBack: _step == 0 ? null : () => setState(() => _step -= 1),
            onNext: () {
              if (_step < stepTitles.length - 1) {
                setState(() => _step += 1);
                return;
              }
              widget.onReview?.call(context, _controller.state.configuration);
            },
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final PrintConfigurationState state = _controller.state;
            final double previewHeight = math.min(
              142,
              MediaQuery.sizeOf(context).height * 0.175,
            );
            return Column(
              children: <Widget>[
                _WizardProgress(
                  step: _step,
                  stepCount: stepTitles.length,
                  title: stepTitles[_step],
                ),
                _PreviewPanel(
                  height: previewHeight,
                  state: state,
                  imageBytes: _livePreviewBytes,
                ),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: _StepViewport(
                      step: _step,
                      child: switch (_step) {
                        0 => _SizeStep(state: state, controller: _controller),
                        1 => _FramingStep(
                          state: state,
                          controller: _controller,
                          onEditingFinished: _refreshLivePreview,
                        ),
                        2 => _SheetStep(state: state, controller: _controller),
                        _ => _ReviewStep(state: state, controller: _controller),
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _refreshLivePreview() {
    if (!mounted) return;
    setState(() {
      _livePreviewBytes = Uint8List.fromList(widget.image.bytes);
    });
  }

  bool _canContinue(PrintConfigurationState state, int stepCount) {
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
    if (_step == stepCount - 1) {
      return state.canReview;
    }
    return state.imageError == null;
  }
}

final class _StepViewport extends StatelessWidget {
  const _StepViewport({required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool needsFallbackScroll =
        step == 3 ||
        media.size.height < 700 ||
        media.textScaler.scale(1) > 1.15;
    const EdgeInsets padding = EdgeInsets.fromLTRB(16, 14, 16, 12);
    if (needsFallbackScroll) {
      return SingleChildScrollView(
        key: const Key('wizard-step-scroll'),
        physics: const ClampingScrollPhysics(),
        padding: padding,
        child: child,
      );
    }
    return Padding(
      key: const Key('wizard-step-static'),
      padding: padding,
      child: Align(alignment: Alignment.topCenter, child: child),
    );
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 7),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.stepLabel(step + 1, stepCount, title),
                  key: const Key('wizard-step-title'),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Text(
                '${step + 1}/$stepCount',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 4,
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
  const _PreviewPanel({
    required this.height,
    required this.state,
    required this.imageBytes,
  });

  final double height;
  final PrintConfigurationState state;
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.topCenter,
          child: PrintSheetPreview(
            key: const Key('wizard-live-preview'),
            plan: state.previewPlan,
            configuration: state.configuration,
            previewImageBytes: imageBytes,
            errorMessage: _localizedValidation(context, state.layoutError),
            maxPageHeight: height - 12,
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.text('whatSize'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 3),
        Text(
          l10n.text('choosePresetOrCustom'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _SizePresetCard(
              key: const Key('size-preset-35x45'),
              label: '35 × 45 mm',
              caption: l10n.text('idPhoto'),
              selected: _matchesMillimetres(state, 35, 45),
              onTap: () => _applyMillimetrePreset(controller, 35, 45),
            ),
            _SizePresetCard(
              key: const Key('size-preset-10x15'),
              label: '10 × 15 cm',
              caption: l10n.text('classic'),
              selected: _matchesMillimetres(state, 100, 150),
              onTap: () => _applyMillimetrePreset(controller, 100, 150),
            ),
            _SizePresetCard(
              key: const Key('size-preset-13x18'),
              label: '13 × 18 cm',
              caption: l10n.text('large'),
              selected: _matchesMillimetres(state, 130, 180),
              onTap: () => _applyMillimetrePreset(controller, 130, 180),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.text('custom'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            _UnitSelector(state: state, controller: controller),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _LengthField(
                key: ValueKey<String>(
                  'wizard-width-${state.unit.name}-${state.widthInput}',
                ),
                label: l10n.text('width'),
                suffix: state.unit.shortLabel,
                value: state.widthInput,
                error: _localizedValidation(context, state.widthError),
                onChanged: controller.changeWidth,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LengthField(
                key: ValueKey<String>(
                  'wizard-height-${state.unit.name}-${state.heightInput}',
                ),
                label: l10n.text('height'),
                suffix: state.unit.shortLabel,
                value: state.heightInput,
                error: _localizedValidation(context, state.heightError),
                onChanged: controller.changeHeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ResolutionGuidance(configuration: state.configuration),
      ],
    );
  }
}

final class _FramingStep extends StatelessWidget {
  const _FramingStep({
    required this.state,
    required this.controller,
    required this.onEditingFinished,
  });

  final PrintConfigurationState state;
  final PrintConfigurationController controller;
  final VoidCallback onEditingFinished;

  @override
  Widget build(BuildContext context) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    final bool fill = state.configuration.fitMode == ImageFitMode.cropToFill;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.text('framingTitle'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 3),
        Text(
          l10n.text('framingSubtitle'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Row(
          key: const Key('wizard-fit-mode'),
          children: <Widget>[
            Expanded(
              child: _ChoiceCard(
                icon: Icons.crop_rounded,
                title: l10n.text('fill'),
                subtitle: l10n.text('noBorders'),
                selected: fill,
                onTap: () => controller.changeFitMode(ImageFitMode.cropToFill),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChoiceCard(
                icon: Icons.fit_screen_rounded,
                title: l10n.text('wholePhoto'),
                subtitle: l10n.text('noCrop'),
                selected: !fill,
                onTap: () => controller.changeFitMode(ImageFitMode.fitInside),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (fill)
          VisualFramingEditor(
            configuration: state.configuration,
            onFocusChanged: controller.changeFocus,
            onZoomChanged: controller.changeFramingZoom,
            onEditingFinished: onEditingFinished,
            maxHeight: 145,
          )
        else
          const _CompletePhotoNotice(),
      ],
    );
  }
}

final class _CompletePhotoNotice extends StatelessWidget {
  const _CompletePhotoNotice();

  @override
  Widget build(BuildContext context) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Container(
      key: const Key('fit-inside-static-notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.text('wholePhotoNotice'))),
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.text('sheet'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 3),
        Text(
          l10n.text('paperAndCopies'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.text('copies'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            SizedBox(
              width: 190,
              child: _CopyStepper(
                key: const Key('wizard-copy-count'),
                value: state.configuration.copyCount,
                error: _localizedValidation(context, state.copyCountError),
                onChanged: (int value) => controller.changeCopyCount('$value'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('wizard-advanced-options'),
          onPressed: () => _openSheetSettings(context, controller),
          icon: const Icon(Icons.tune_rounded),
          label: Text(l10n.text('sheetSettings')),
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    final PrintJobConfiguration configuration = state.configuration;
    final String framing = configuration.fitMode == ImageFitMode.cropToFill
        ? configuration.framingZoom > 1.01
              ? '${l10n.text('fill')} · ${configuration.framingZoom.toStringAsFixed(1)}×'
              : l10n.text('fill')
        : l10n.text('wholePhoto');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.text('ready'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _SummaryCard(
          rows: <_SummaryRow>[
            _SummaryRow(
              label: l10n.text('photo'),
              value:
                  '${_formatMillimetres(configuration.photoWidth)} × ${_formatMillimetres(configuration.photoHeight)} mm',
            ),
            _SummaryRow(label: l10n.text('framing'), value: framing),
            _SummaryRow(
              label: l10n.text('paper'),
              value: _paperLabel(context, configuration.paperSize),
            ),
            _SummaryRow(
              label: l10n.text('copies'),
              value: '${configuration.copyCount}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ResolutionGuidance(configuration: configuration),
        TextButton.icon(
          onPressed: () => _openSheetSettings(context, controller),
          icon: const Icon(Icons.tune_rounded),
          label: Text(l10n.text('editAdvanced')),
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
      width: 142,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? colors.primary : colors.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
              padding: const EdgeInsets.only(left: 3),
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
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? colors.primary : colors.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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
      width: 96,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: selected ? colors.primary : colors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _paperLabel(context, paper),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
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
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
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
                  style: Theme.of(context).textTheme.titleMedium,
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
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
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
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rows
            .map(
              (_SummaryRow row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(row.label)),
                    Flexible(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
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
        isDense: true,
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          key: const Key('wizard-fixed-navigation'),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 86,
                child: onBack == null
                    ? const SizedBox.shrink()
                    : TextButton(
                        key: const Key('wizard-back'),
                        onPressed: onBack,
                        child: Text(l10n.text('back')),
                      ),
              ),
              const Spacer(),
              SizedBox(
                width: 156,
                child: FilledButton(
                  key: const Key('wizard-next'),
                  onPressed: canContinue ? onNext : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      step == stepCount - 1
                          ? l10n.text('reviewPdf')
                          : l10n.text('next'),
                    ),
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
            final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
            final PrintConfigurationState state = controller.state;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                18 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    l10n.text('sheetSettings'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.palette_outlined,
                          title: l10n.text('color'),
                          subtitle: l10n.text('original'),
                          selected:
                              state.configuration.colorMode ==
                              ImageColorMode.color,
                          onTap: () =>
                              controller.changeColorMode(ImageColorMode.color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChoiceCard(
                          icon: Icons.monochrome_photos_outlined,
                          title: l10n.text('grayscale'),
                          subtitle: l10n.text('grays'),
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
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _LengthField(
                          key: ValueKey<String>(
                            'wizard-margin-${state.unit.name}-${state.marginInput}',
                          ),
                          label: l10n.text('margin'),
                          suffix: state.unit.shortLabel,
                          value: state.marginInput,
                          error: _localizedValidation(context, state.marginError),
                          onChanged: controller.changeMargin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LengthField(
                          key: ValueKey<String>(
                            'wizard-gap-${state.unit.name}-${state.gapInput}',
                          ),
                          label: l10n.text('spacing'),
                          suffix: state.unit.shortLabel,
                          value: state.gapInput,
                          error: _localizedValidation(context, state.gapError),
                          onChanged: controller.changeGap,
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    key: const Key('wizard-cut-marks'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.text('cutMarks')),
                    value: state.configuration.showCutMarks,
                    onChanged: controller.changeCutMarks,
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.text('done')),
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

String? _localizedValidation(BuildContext context, String? error) {
  if (error == null) {
    return null;
  }
  final String languageCode = Localizations.localeOf(context).languageCode;
  final bool invalidCopies = error.contains('1 y 999');
  final bool invalidLength = error.contains('mayor que 0');
  final bool layoutError = error.contains('no cabe en el papel');
  if (!invalidCopies && !invalidLength && !layoutError) {
    return error;
  }
  return switch (languageCode) {
    'es' => invalidCopies
        ? 'Introduce un número entre 1 y 999.'
        : invalidLength
              ? 'Introduce una medida mayor que 0.'
              : 'La foto no cabe en el papel con estas medidas y márgenes.',
    'fr' => invalidCopies
        ? 'Saisissez un nombre entre 1 et 999.'
        : invalidLength
              ? 'Saisissez une mesure supérieure à 0.'
              : 'La photo ne tient pas sur le papier avec ces dimensions et marges.',
    'pt' => invalidCopies
        ? 'Introduza um número entre 1 e 999.'
        : invalidLength
              ? 'Introduza uma medida superior a 0.'
              : 'A foto não cabe no papel com estas dimensões e margens.',
    'de' => invalidCopies
        ? 'Gib eine Zahl zwischen 1 und 999 ein.'
        : invalidLength
              ? 'Gib ein Maß größer als 0 ein.'
              : 'Das Foto passt mit diesen Maßen und Rändern nicht auf das Papier.',
    _ => invalidCopies
        ? 'Enter a number between 1 and 999.'
        : invalidLength
              ? 'Enter a measurement greater than 0.'
              : 'The photo does not fit on the paper with these dimensions and margins.',
  };
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

String _paperLabel(BuildContext context, PaperSize paper) {
  if (paper == PaperSize.a4) {
    return 'A4';
  }
  if (paper == PaperSize.usLetter) {
    return PhotoCutLocalizations.of(context).text('letter');
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
