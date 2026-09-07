import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/configuration_help.dart';
import 'package:photo_cut/features/print_job/length_unit.dart';
import 'package:photo_cut/features/print_job/print_configuration_controller.dart';
import 'package:photo_cut/features/print_job/print_configuration_state.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/features/print_job/print_job_document_factory.dart';
import 'package:photo_cut/features/print_job/print_sheet_preview.dart';
import 'package:photo_cut/features/print_job/resolution_guidance.dart';
import 'package:photo_cut/features/print_job/step_one_pdf_preview.dart';
import 'package:photo_cut/features/print_job/visual_framing_editor.dart';
import 'package:photo_cut/features/print_job/zoomable_pdf_document_preview.dart';
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
    this.previewDocumentLoader,
    this.previewBuilder,
    this.previewTransformationController,
  });

  final SelectedImage image;
  final ImageProcessor? imageProcessor;
  final PrintJobReviewCallback? onReview;
  final StepOnePdfDocumentLoader? previewDocumentLoader;
  final ZoomablePdfPreviewBuilder? previewBuilder;
  final TransformationController? previewTransformationController;

  @override
  State<PrintConfigurationScreen> createState() =>
      _PrintConfigurationScreenState();
}

enum _StepOneView { settings, preview }

final class _PrintConfigurationScreenState
    extends State<PrintConfigurationScreen> {
  late final PrintConfigurationController _controller;
  late final ImageProcessor _imageProcessor;
  late final StepOnePdfDocumentLoader _previewDocumentLoader;
  _StepOneView _selectedView = _StepOneView.settings;

  @override
  void initState() {
    super.initState();
    _imageProcessor = widget.imageProcessor ?? const DartImageProcessor();
    _controller = PrintConfigurationController(
      image: widget.image,
      imageProcessor: _imageProcessor,
    );
    final PrintJobDocumentFactory previewFactory = PrintJobDocumentFactory(
      imageProcessor: _imageProcessor,
    );
    _previewDocumentLoader =
        widget.previewDocumentLoader ?? previewFactory.build;
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
      appBar: AppBar(
        title: const Text('Preparar en Photo Cut'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<_StepOneView>(
              key: const Key('configuration-view-switcher'),
              segments: const <ButtonSegment<_StepOneView>>[
                ButtonSegment<_StepOneView>(
                  value: _StepOneView.settings,
                  icon: Icon(Icons.tune),
                  label: Text('Ajustes', key: Key('settings-view-tab')),
                ),
                ButtonSegment<_StepOneView>(
                  value: _StepOneView.preview,
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  label: Text('Vista previa', key: Key('preview-view-tab')),
                ),
              ],
              selected: <_StepOneView>{_selectedView},
              onSelectionChanged: (Set<_StepOneView> selection) {
                setState(() {
                  _selectedView = selection.single;
                });
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final PrintConfigurationState state = _controller.state;
            return IndexedStack(
              key: const Key('configuration-view-stack'),
              index: _selectedView.index,
              children: <Widget>[
                CustomScrollView(
                  key: const Key('configuration-settings-scroll'),
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
                            subtitle: 'Decide qué parte de la imagen entra y cómo se verá en el PDF.',
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
                          const SizedBox(height: 14),
                          const _ControlLabel(
                            label: 'Encuadre',
                            topic: ConfigurationHelpTopic.framing,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.configuration.fitMode ==
                                    ImageFitMode.cropToFill
                                ? 'Mueve la foto para elegir qué parte queda dentro.'
                                : 'La foto completa quedará dentro del marco, sin recorte.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          VisualFramingEditor(
                            configuration: state.configuration,
                            onFocusChanged: _controller.changeFocus,
                          ),
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
                            onSelectionChanged:
                                (Set<ImageColorMode> selection) {
                                  _controller.changeColorMode(selection.single);
                                },
                          ),
                          const SizedBox(height: 24),
                          const _SectionTitle(
                            title: 'Tamaño de cada foto',
                            subtitle: 'Estas son las medidas físicas finales, no píxeles.',
                          ),
                          const SizedBox(height: 10),
                          const _ControlLabel(
                            label: 'Unidad',
                            topic: ConfigurationHelpTopic.unit,
                          ),
                          const SizedBox(height: 6),
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
                                    suffixIcon: const ConfigurationHelpButton(
                                      topic: ConfigurationHelpTopic.width,
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
                                    suffixIcon: const ConfigurationHelpButton(
                                      topic: ConfigurationHelpTopic.height,
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
                                  onChanged: _controller.changeHeight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const _SectionTitle(
                            title: 'Hoja y copias',
                            subtitle: 'Photo Cut distribuirá las copias y elegirá la orientación que aproveche mejor el papel.',
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<PaperSize>(
                            key: ValueKey<String>(
                              'paper-${state.configuration.paperSize.id}',
                            ),
                            initialValue: state.configuration.paperSize,
                            decoration: const InputDecoration(
                              labelText: 'Tamaño del papel',
                              suffixIcon: ConfigurationHelpButton(
                                topic: ConfigurationHelpTopic.paper,
                              ),
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
                              suffixIcon: const ConfigurationHelpButton(
                                topic: ConfigurationHelpTopic.copies,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: _controller.changeCopyCount,
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: ExpansionTile(
                              key: const Key('advanced-options'),
                              initiallyExpanded: false,
                              title: const Text('Opciones avanzadas'),
                              subtitle: const Text(
                                'Margen, separación y marcas de corte',
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
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
                                          labelText:
                                              'Margen (${state.unit.shortLabel})',
                                          errorText: state.marginError,
                                          suffixIcon:
                                              const ConfigurationHelpButton(
                                                topic: ConfigurationHelpTopic
                                                    .margin,
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
                                        key: ValueKey<String>(
                                          'gap-${state.unit.name}',
                                        ),
                                        initialValue: state.gapInput,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Separación (${state.unit.shortLabel})',
                                          errorText: state.gapError,
                                          suffixIcon:
                                              const ConfigurationHelpButton(
                                                topic:
                                                    ConfigurationHelpTopic.gap,
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
                          ResolutionGuidance(
                            configuration: state.configuration,
                          ),
                          const SizedBox(height: 12),
                          if (state.layoutError != null) ...<Widget>[
                            const SizedBox(height: 12),
                            _InlineError(message: state.layoutError!),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const Key('review-print-job'),
                            onPressed: state.canReview
                                ? () => _review(context, state.configuration)
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
                ),
                StepOnePdfPreview(
                  key: const Key('step-one-pdf-preview'),
                  active: _selectedView == _StepOneView.preview,
                  canGenerate: state.canReview,
                  configuration: state.configuration,
                  documentLoader: _previewDocumentLoader,
                  previewBuilder: widget.previewBuilder,
                  transformationController:
                      widget.previewTransformationController,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _review(BuildContext context, PrintJobConfiguration configuration) {
    final PrintJobReviewCallback? callback = widget.onReview;
    if (callback != null) {
      callback(context, configuration);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración lista. La revisión se conecta en M2-T04.'),
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

String _paperLabel(PaperSize paper) {
  return switch (paper.id) {
    'a4' => 'A4 · 210 × 297 mm',
    'us-letter' => 'Letter · 8,5 × 11 in',
    'photo-10x15' => 'Foto · 10 × 15 cm',
    _ => paper.id,
  };
}
