import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_cut/features/pdf_spike/pdf_spike.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.imagePickerGateway,
    this.imageProcessor,
    this.pdfSpikeBuilder,
  });

  final ImagePickerGateway imagePickerGateway;
  final ImageProcessor? imageProcessor;
  final WidgetBuilder? pdfSpikeBuilder;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  late final PhotoSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PhotoSelectionController(gateway: widget.imagePickerGateway);
    unawaited(_controller.recoverLostSelection());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Cut')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final PhotoSelectionState state = _controller.state;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _PhotoHero(image: state.image),
                      const SizedBox(height: 32),
                      Text(
                        'Imprime fotos al tamaño exacto',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.image == null
                            ? 'Elige una foto, indica sus medidas y crea una hoja lista para imprimir.'
                            : 'Foto seleccionada. Ahora configura el documento dentro de Photo Cut.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (state.image != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          state.image!.displayName,
                          key: const Key('selected-image-name'),
                          style: Theme.of(context).textTheme.labelLarge,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (state.errorMessage != null) ...<Widget>[
                        const SizedBox(height: 20),
                        _SelectionError(
                          message: state.errorMessage!,
                          onDismiss: _controller.clearError,
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (state.image == null)
                        FilledButton.icon(
                          key: const Key('choose-photo'),
                          onPressed: state.isBusy
                              ? null
                              : _controller.selectFromGallery,
                          icon: state.isBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Elegir foto'),
                        )
                      else ...<Widget>[
                        FilledButton.icon(
                          key: const Key('configure-photo'),
                          onPressed: () => _openConfiguration(state.image!),
                          icon: const Icon(Icons.tune),
                          label: const Text('Configurar impresión'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('choose-photo'),
                          onPressed: state.isBusy
                              ? null
                              : _controller.selectFromGallery,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Elegir otra foto'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'La foto se procesa en este dispositivo y no se sube.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      if (kDebugMode) ...<Widget>[
                        const SizedBox(height: 20),
                        _DevelopmentNotice(
                          onOpenPdfSpike: () => _openPdfSpike(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openConfiguration(SelectedImage image) {
    final ImageProcessor imageProcessor =
        widget.imageProcessor ?? const DartImageProcessor();
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext routeContext) {
            return PrintConfigurationScreen(
              image: image,
              imageProcessor: imageProcessor,
              onReview: (
                BuildContext configurationContext,
                PrintJobConfiguration configuration,
              ) {
                unawaited(
                  Navigator.of(configurationContext).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext reviewContext) {
                        return PrintReviewScreen.production(
                          configuration: configuration,
                          imageProcessor: imageProcessor,
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openPdfSpike(BuildContext context) {
    final WidgetBuilder builder =
        widget.pdfSpikeBuilder ??
        (BuildContext routeContext) => PdfSpikeScreen.production();
    unawaited(
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: builder)),
    );
  }
}

final class _PhotoHero extends StatelessWidget {
  const _PhotoHero({required this.image});

  final SelectedImage? image;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final SelectedImage? selected = image;

    return Semantics(
      label: selected == null
          ? 'Hoja con varias copias de una fotografía'
          : 'Vista previa de la fotografía seleccionada',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: selected == null
              ? const Center(
                  child: Icon(
                    Icons.photo_size_select_large_outlined,
                    size: 104,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.memory(
                    selected.bytes,
                    key: const Key('selected-image-preview'),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder:
                        (
                          BuildContext errorContext,
                          Object error,
                          StackTrace? stack,
                        ) {
                          return const Center(
                            child: Text(
                              'No se pudo mostrar la foto.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                  ),
                ),
        ),
      ),
    );
  }
}

final class _SelectionError extends StatelessWidget {
  const _SelectionError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Cerrar aviso',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DevelopmentNotice extends StatelessWidget {
  const _DevelopmentNotice({required this.onOpenPdfSpike});

  final VoidCallback onOpenPdfSpike;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Build de desarrollo · M1 Vista previa PDF',
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenPdfSpike,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Probar PDF de ejemplo'),
            ),
          ],
        ),
      ),
    );
  }
}
