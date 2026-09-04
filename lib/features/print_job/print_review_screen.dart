import 'package:flutter/material.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/features/print_job/print_job_document_factory.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';
import 'package:photo_cut/platform/print/print.dart';

typedef PrintReviewDocumentLoader = Future<PrintDocument> Function();

typedef PrintReviewPreviewBuilder = Widget Function(
  BuildContext context,
  PrintDocument document,
);

/// Step 2: review one immutable PDF, then share it or hand it to the OS.
final class PrintReviewScreen extends StatefulWidget {
  const PrintReviewScreen({
    super.key,
    required this.configuration,
    required this.documentLoader,
    required this.printGateway,
    this.previewBuilder,
  });

  factory PrintReviewScreen.production({
    Key? key,
    required PrintJobConfiguration configuration,
    required ImageProcessor imageProcessor,
  }) {
    final PrintJobDocumentFactory factory = PrintJobDocumentFactory(
      imageProcessor: imageProcessor,
    );
    return PrintReviewScreen(
      key: key,
      configuration: configuration,
      documentLoader: () => factory.build(configuration),
      printGateway: const PrintingPrintGateway(),
    );
  }

  final PrintJobConfiguration configuration;
  final PrintReviewDocumentLoader documentLoader;
  final PrintReviewPreviewBuilder? previewBuilder;
  final PrintGateway printGateway;

  @override
  State<PrintReviewScreen> createState() => _PrintReviewScreenState();
}

final class _PrintReviewScreenState extends State<PrintReviewScreen> {
  late Future<PrintDocument> _documentFuture;
  bool _actionInProgress = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _documentFuture = _loadDocument();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar e imprimir')),
      body: SafeArea(
        child: FutureBuilder<PrintDocument>(
          future: _documentFuture,
          builder: (
            BuildContext context,
            AsyncSnapshot<PrintDocument> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _PreparingDocument();
            }
            final PrintDocument? document = snapshot.data;
            if (snapshot.hasError || document == null) {
              return _DocumentError(
                onBack: _goBack,
                onRetry: _retryDocument,
              );
            }

            final PrintReviewPreviewBuilder? previewBuilder =
                widget.previewBuilder;
            final Widget preview = previewBuilder == null
                ? PdfDocumentPreview(document: document)
                : previewBuilder(context, document);

            return Column(
              children: <Widget>[
                _ReviewSummary(
                  configuration: widget.configuration,
                  document: document,
                ),
                Expanded(child: preview),
                _ReviewActions(
                  actionInProgress: _actionInProgress,
                  nativePrintLabel: _nativePrintLabel(context),
                  onBack: _goBack,
                  onPrint: () => _print(document),
                  onShare: () => _share(document),
                  statusMessage: _statusMessage,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<PrintDocument> _loadDocument() {
    return Future<PrintDocument>.sync(widget.documentLoader);
  }

  void _retryDocument() {
    setState(() {
      _statusMessage = null;
      _documentFuture = _loadDocument();
    });
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  Future<void> _share(PrintDocument document) {
    return _runAction(
      action: () => widget.printGateway.sharePdf(document),
      successMessage: 'PDF preparado para compartir.',
      cancelledMessage: 'Compartir cancelado.',
      failureMessage: 'No se pudo abrir el menú para compartir.',
    );
  }

  Future<void> _print(PrintDocument document) {
    return _runAction(
      action: () => widget.printGateway.printPdf(document),
      successMessage: 'Has vuelto de la impresión del sistema.',
      cancelledMessage: 'Impresión cancelada.',
      failureMessage: 'No se pudo abrir la impresión del sistema.',
    );
  }

  Future<void> _runAction({
    required Future<bool> Function() action,
    required String successMessage,
    required String cancelledMessage,
    required String failureMessage,
  }) async {
    if (_actionInProgress) {
      return;
    }
    setState(() {
      _actionInProgress = true;
      _statusMessage = null;
    });

    String message;
    try {
      final bool completed = await action();
      message = completed ? successMessage : cancelledMessage;
    } on Object {
      message = failureMessage;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _actionInProgress = false;
      _statusMessage = message;
    });
  }
}

final class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.configuration,
    required this.document,
  });

  final PrintJobConfiguration configuration;
  final PrintDocument document;

  @override
  Widget build(BuildContext context) {
    final String copies = configuration.copyCount == 1
        ? '1 copia'
        : '${configuration.copyCount} copias';
    final String fit = configuration.fitMode == ImageFitMode.cropToFill
        ? 'Rellenar'
        : 'Encajar';
    final String colour = configuration.colorMode == ImageColorMode.grayscale
        ? 'Blanco y negro'
        : 'Color';
    final String marks = configuration.showCutMarks
        ? 'Con marcas de corte'
        : 'Sin marcas de corte';

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Paso 2 de 2 · Revisa el PDF final',
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatMillimetres(configuration.photoWidth.inMillimetres)} × '
              '${_formatMillimetres(configuration.photoHeight.inMillimetres)} mm '
              '· $copies · ${_paperLabel(configuration.paperSize.id)}',
              key: const Key('review-primary-summary'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$fit · $colour · $marks',
              key: const Key('review-secondary-summary'),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Archivo: ${document.filename}',
              key: const Key('review-filename'),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.actionInProgress,
    required this.nativePrintLabel,
    required this.onBack,
    required this.onPrint,
    required this.onShare,
    required this.statusMessage,
  });

  final bool actionInProgress;
  final String nativePrintLabel;
  final VoidCallback onBack;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (statusMessage != null) ...<Widget>[
              Semantics(
                liveRegion: true,
                child: Text(
                  statusMessage!,
                  key: const Key('review-status-message'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              key: const Key('edit-print-job'),
              onPressed: actionInProgress ? null : onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver y editar'),
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              key: const Key('share-final-pdf'),
              onPressed: actionInProgress ? null : onShare,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir PDF'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('open-native-print'),
              onPressed: actionInProgress ? null : onPrint,
              icon: actionInProgress
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined),
              label: Text(nativePrintLabel, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PreparingDocument extends StatelessWidget {
  const _PreparingDocument();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparando el PDF final…'),
          ],
        ),
      ),
    );
  }
}

final class _DocumentError extends StatelessWidget {
  const _DocumentError({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No se pudo preparar el PDF final.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            TextButton(onPressed: onBack, child: const Text('Volver y editar')),
          ],
        ),
      ),
    );
  }
}

String _nativePrintLabel(BuildContext context) {
  return switch (Theme.of(context).platform) {
    TargetPlatform.android => 'Abrir impresión de Android',
    TargetPlatform.iOS => 'Abrir impresión de iPhone',
    _ => 'Abrir impresión del sistema',
  };
}

String _paperLabel(String paperId) {
  return switch (paperId) {
    'a4' => 'A4',
    'us-letter' => 'Letter',
    'photo-10x15' => '10 × 15 cm',
    _ => paperId,
  };
}

String _formatMillimetres(double value) {
  String text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  return text.replaceFirst(RegExp(r'\.$'), '');
}
