import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/length_unit.dart';
import 'package:photo_cut/features/print_job/print_configuration_controller.dart';
import 'package:photo_cut/features/print_job/print_configuration_state.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/features/print_job/print_sheet_preview.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

typedef PrintJobReviewCallback = void Function(
  BuildContext context,
  PrintJobConfiguration configuration,
);

/// Step 1: every control here changes the document Photo Cut will generate.
final class PrintConfigurationScreen extends StatefulWidget {
  const PrintConfigurationScreen({
    super.key,
    required this.image,
    this.imageProcessor,
    this.onReview,
  });

  final SelectedImage image;
  final ImageProcessor? imageProcessor;
  final PrintJobReviewCallback? onReview;

  @override
  State<PrintConfigurationScreen> createState() =>
      _PrintConfigurationScreenState();
}

final class _PrintConfigurationScreenState
    extends State<PrintConfigurationScreen> {
  late final PrintConfigurationController _controller;

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
      appBar: AppBar(title: const Text('Preparar en Photo Cut')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final PrintConfigurationState state = _controller.state;
            return CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  sliver: SliverList.list(
                    children: <Widget>[
                      Text(
                        'Paso 1 de 2 · Configura el documento',
                        style: Theme.of(context).textTheme.labelLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      PrintSheetPreview(
                        plan: state.previewPlan,
                        configuration: state.configuration,
                        errorMessage: state.layoutError,
                      ),
                      const SizedBox(height: 12),
                      _ImageInspectionStatus(state: state),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Ajuste de la foto',
                        subtitle:
                            'El resultado se aplica dentro de Photo Cut antes de abrir la impresión del sistema.',
                      ),
                      const SizedBox(height: 12),
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
                        selected: <ImageFitMode>{
                          state.configuration.fitMode,
                        },
                        onSelectionChanged: (Set<ImageFitMode> selection) {
                          _controller.changeFitMode(selection.single);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.configuration.fitMode ==
                                ImageFitMode.cropToFill
                            ? 'Rellena la medida exacta y recorta lo que sobre.'
                            : 'Muestra la foto completa sin deformarla; pueden quedar bordes blancos.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (state.configuration.fitMode ==
                          ImageFitMode.cropToFill) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          'Encuadre horizontal',
                          style: Theme.of(context).textTheme.labelLarge,
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
                          'Encuadre vertical',
                          style: Theme.of(context).textTheme.labelLarge,
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Tamaño de cada foto',
                        subtitle:
                            'Estas son las medidas físicas finales, no píxeles.',
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<LengthUnit>(
                        key: const Key('length-unit-selector'),
                        segments: LengthUnit.values
                            .map(
                              (LengthUnit unit) =>
                                  ButtonSegment<LengthUnit>(
                                    value: unit,
                                    label: Text(unit.shortLabel),
                                    tooltip: unit.label,
                                  ),
                            )
                            .toList(growable: false),
                        selected: <LengthUnit>{state.unit},
                        onSelectionChanged: (Set<LengthUnit> selection) {
                          _controller.changeUnit(selection.single);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              key: ValueKey<String>(
                                'photo-width-${state.unit.name}',
                              ),
                              initialValue: state.widthInput,
                              decoration: InputDecoration(
                                labelText:
                                    'Ancho (${state.unit.shortLabel})',
                                errorText: state.widthError,
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
                              onChanged: _controller.changeWidth,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey<String>(
                                'photo-height-${state.unit.name}',
                              ),
                              initialValue: state.heightInput,
                              decoration: InputDecoration(
                                labelText:
                                    'Alto (${state.unit.shortLabel})',
                                errorText: state.heightError,
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
                              onChanged: _controller.changeHeight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Hoja y copias',
                        subtitle:
                            'Photo Cut distribuirá las copias y elegirá la orientación que aproveche mejor el papel.',
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PaperSize>(
                        key: ValueKey<String>(
                          'paper-${state.configuration.paperSize.id}',
                        ),
                        initialValue: state.configuration.paperSize,
                        decoration: const InputDecoration(
                          labelText: 'Tamaño del papel',
                        ),
                        items: PaperSize.presets
                            .map(
                              (PaperSize paper) =>
                                  DropdownMenuItem<PaperSize>(
                                    value: paper,
                                    child: Text(_paperLabel(paper)),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: (PaperSize? paper) {
                          if (paper != null) {
                            _controller.changePaperSize(paper);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('copy-count'),
                        initialValue: state.copyCountInput,
                        decoration: InputDecoration(
                          labelText: 'Número de copias',
                          errorText: state.copyCountError,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: _controller.changeCopyCount,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Separación y corte',
                        subtitle:
                            'Deja espacio suficiente para que la impresora no recorte los bordes.',
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
                                labelText:
                                    'Margen (${state.unit.shortLabel})',
                                errorText: state.marginError,
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
                              key: ValueKey<String>(
                                'gap-${state.unit.name}',
                              ),
                              initialValue: state.gapInput,
                              decoration: InputDecoration(
                                labelText:
                                    'Separación (${state.unit.shortLabel})',
                                errorText: state.gapError,
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
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        key: const Key('cut-marks'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Marcas de corte'),
                        subtitle: const Text(
                          'Añade guías finas alrededor de cada copia.',
                        ),
                        value: state.configuration.showCutMarks,
                        onChanged: _controller.changeCutMarks,
                      ),
                      if (state.layoutError != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _InlineError(message: state.layoutError!),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('review-print-job'),
                        onPressed: state.canReview
                            ? () => _review(
                                context,
                                state.configuration,
                              )
                            : null,
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('Revisar e imprimir'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'En el paso siguiente verás el PDF final antes de abrir la impresión de Android.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _review(
    BuildContext context,
    PrintJobConfiguration configuration,
  ) {
    final PrintJobReviewCallback? callback = widget.onReview;
    if (callback != null) {
      callback(context, configuration);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Configuración lista. La revisión se conecta en M2-T04.',
        ),
      ),
    );
  }
}

final class _ImageInspectionStatus extends StatelessWidget {
  const _ImageInspectionStatus({required this.state});

  final PrintConfigurationState state;

  @override
  Widget build(BuildContext context) {
    if (state.isInspectingImage) {
      return const Column(
        key: Key('image-inspection-progress'),
        children: <Widget>[
          LinearProgressIndicator(),
          SizedBox(height: 8),
          Text(
            'Leyendo tamaño y orientación de la foto…',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    if (state.imageError != null) {
      return _InlineError(message: state.imageError!);
    }

    final SourceImageSize? size = state.configuration.sourceSize;
    if (size == null) {
      return const SizedBox.shrink();
    }
    return Text(
      'Original orientado: ${size.widthPixels} × ${size.heightPixels} px',
      key: const Key('source-image-size'),
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

final class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

String _focusLabel(
  double value, {
  required String start,
  required String middle,
  required String end,
}) {
  if (value < 0.34) {
    return start;
  }
  if (value > 0.66) {
    return end;
  }
  return middle;
}

String _paperLabel(PaperSize paper) {
  return switch (paper.id) {
    'a4' => 'A4 · 210 × 297 mm',
    'us-letter' => 'Letter · 8,5 × 11 in',
    'photo-10x15' => 'Foto · 10 × 15 cm',
    _ => paper.id,
  };
}
