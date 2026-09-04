import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/length_unit.dart';
import 'package:photo_cut/features/print_job/print_configuration_controller.dart';
import 'package:photo_cut/features/print_job/print_configuration_state.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

typedef PrintJobReviewCallback = void Function(
  BuildContext context,
  PrintJobConfiguration configuration,
);

/// Step 1: every control here changes the document Photo Cut will generate.
final class PrintConfigurationScreen extends StatefulWidget {
  const PrintConfigurationScreen({
    super.key,
    required this.image,
    this.onReview,
  });

  final SelectedImage image;
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
    _controller = PrintConfigurationController(image: widget.image);
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
                      _SheetPreview(
                        plan: state.previewPlan,
                        image: state.configuration.image,
                        showCutMarks: state.configuration.showCutMarks,
                        errorMessage: state.layoutError,
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(
                        title: 'Tamaño de cada foto',
                        subtitle: 'Estas son las medidas físicas finales, no píxeles.',
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<LengthUnit>(
                        key: const Key('length-unit-selector'),
                        segments: LengthUnit.values
                            .map(
                              (LengthUnit unit) => ButtonSegment<LengthUnit>(
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
                                labelText: 'Ancho (${state.unit.shortLabel})',
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
                                labelText: 'Alto (${state.unit.shortLabel})',
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
                        ),
                        items: PaperSize.presets
                            .map(
                              (PaperSize paper) => DropdownMenuItem<PaperSize>(
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
                        subtitle: 'Deja espacio suficiente para que la impresora no recorte los bordes.',
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
                        _LayoutError(message: state.layoutError!),
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

final class _SheetPreview extends StatelessWidget {
  const _SheetPreview({
    required this.plan,
    required this.image,
    required this.showCutMarks,
    required this.errorMessage,
  });

  final String? errorMessage;
  final SelectedImage image;
  final SheetPlan? plan;
  final bool showCutMarks;

  @override
  Widget build(BuildContext context) {
    final SheetPlan? currentPlan = plan;
    if (currentPlan == null) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                errorMessage ?? 'No se puede crear la vista previa.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final Uint8List bytes = image.bytes;
    final double pageWidth = currentPlan.pageWidth.inMillimetres;
    final double pageHeight = currentPlan.pageHeight.inMillimetres;
    final List<PlacedPhoto> firstPage = currentPlan
        .placementsForPage(0)
        .toList(growable: false);

    return Column(
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: AspectRatio(
              aspectRatio: pageWidth / pageHeight,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(blurRadius: 12, color: Color(0x26000000)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: firstPage
                            .map(
                              (PlacedPhoto placement) => Positioned(
                                key: ValueKey<String>(
                                  'layout-photo-${placement.copyIndex}',
                                ),
                                left:
                                    placement.left.inMillimetres /
                                    pageWidth *
                                    constraints.maxWidth,
                                top:
                                    placement.top.inMillimetres /
                                    pageHeight *
                                    constraints.maxHeight,
                                width:
                                    placement.width.inMillimetres /
                                    pageWidth *
                                    constraints.maxWidth,
                                height:
                                    placement.height.inMillimetres /
                                    pageHeight *
                                    constraints.maxHeight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: showCutMarks
                                        ? Border.all(
                                            color: Colors.black54,
                                            width: 0.5,
                                          )
                                        : null,
                                  ),
                                  child: currentPlan.photoRotated
                                      ? RotatedBox(
                                          quarterTurns: 1,
                                          child: Image.memory(
                                            bytes,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                          ),
                                        )
                                      : Image.memory(
                                          bytes,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentPlan.pageCount == 1
              ? '${currentPlan.placements.length} copias · 1 página'
              : 'Página 1 de ${currentPlan.pageCount} · ${currentPlan.placements.length} copias',
          key: const Key('layout-page-summary'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
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

final class _LayoutError extends StatelessWidget {
  const _LayoutError({required this.message});

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
