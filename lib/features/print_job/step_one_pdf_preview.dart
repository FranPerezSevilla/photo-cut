import 'package:flutter/material.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/features/print_job/zoomable_pdf_document_preview.dart';
import 'package:photo_cut/platform/print/print.dart';

typedef StepOnePdfDocumentLoader = Future<PrintDocument> Function(
  PrintJobConfiguration configuration,
);

/// Persistent Step 1 preview pane. It lazily builds the actual PDF only when
/// the preview tab is visible and caches that document until settings change.
final class StepOnePdfPreview extends StatefulWidget {
  const StepOnePdfPreview({
    super.key,
    required this.active,
    required this.canGenerate,
    required this.configuration,
    required this.documentLoader,
    this.previewBuilder,
    this.transformationController,
  });

  final bool active;
  final bool canGenerate;
  final PrintJobConfiguration configuration;
  final StepOnePdfDocumentLoader documentLoader;
  final ZoomablePdfPreviewBuilder? previewBuilder;
  final TransformationController? transformationController;

  @override
  State<StepOnePdfPreview> createState() => _StepOnePdfPreviewState();
}

final class _StepOnePdfPreviewState extends State<StepOnePdfPreview> {
  Future<PrintDocument>? _documentFuture;
  PrintJobConfiguration? _loadedConfiguration;

  @override
  void initState() {
    super.initState();
    _ensureDocument();
  }

  @override
  void didUpdateWidget(covariant StepOnePdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureDocument();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const SizedBox.shrink();
    }
    if (!widget.canGenerate) {
      return const _PreviewUnavailable();
    }

    final Future<PrintDocument>? future = _documentFuture;
    if (future == null) {
      return const _PreviewLoading();
    }

    return FutureBuilder<PrintDocument>(
      future: future,
      builder: (
        BuildContext context,
        AsyncSnapshot<PrintDocument> snapshot,
      ) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PreviewLoading();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _PreviewError(onRetry: _retry);
        }

        final PrintDocument document = snapshot.requireData;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'PDF actual',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                document.filename,
                key: const Key('step-one-preview-filename'),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ZoomablePdfDocumentPreview(
                  document: document,
                  previewBuilder: widget.previewBuilder,
                  transformationController: widget.transformationController,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'El zoom solo cambia cómo lo ves. No modifica las medidas del PDF.',
                key: const Key('viewer-only-zoom-note'),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _ensureDocument() {
    if (!widget.active || !widget.canGenerate) {
      return;
    }
    if (_documentFuture != null &&
        identical(_loadedConfiguration, widget.configuration)) {
      return;
    }
    _loadedConfiguration = widget.configuration;
    _documentFuture = Future<PrintDocument>.sync(
      () => widget.documentLoader(widget.configuration),
    );
  }

  void _retry() {
    setState(() {
      _loadedConfiguration = widget.configuration;
      _documentFuture = Future<PrintDocument>.sync(
        () => widget.documentLoader(widget.configuration),
      );
    });
  }
}

final class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Generando el PDF con tus ajustes actuales…',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.tune,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Corrige los ajustes marcados para actualizar la vista previa.',
              key: Key('step-one-preview-unavailable'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes volver a Ajustes con un toque; no se ha cambiado ninguna medida.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 14),
            const Text(
              'No se pudo generar la vista previa del PDF.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('retry-step-one-preview'),
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
