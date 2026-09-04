import 'package:flutter/material.dart';
import 'package:photo_cut/features/pdf_spike/sample_pdf_factory.dart';
import 'package:photo_cut/platform/print/print.dart';

/// Loads the deterministic M1 document and proves the three platform paths.
typedef PrintDocumentLoader = Future<PrintDocument> Function();

typedef PdfPreviewBuilder = Widget Function(
  BuildContext context,
  PrintDocument document,
);

final class PdfSpikeScreen extends StatefulWidget {
  const PdfSpikeScreen({
    super.key,
    required this.documentLoader,
    required this.printGateway,
    this.previewBuilder,
  });

  factory PdfSpikeScreen.production({Key? key}) {
    final SamplePdfFactory factory = const SamplePdfFactory();
    return PdfSpikeScreen(
      key: key,
      documentLoader: factory.build,
      printGateway: const PrintingPrintGateway(),
    );
  }

  final PrintDocumentLoader documentLoader;
  final PrintGateway printGateway;
  final PdfPreviewBuilder? previewBuilder;

  @override
  State<PdfSpikeScreen> createState() => _PdfSpikeScreenState();
}

final class _PdfSpikeScreenState extends State<PdfSpikeScreen> {
  late Future<PrintDocument> _documentFuture;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _documentFuture = widget.documentLoader();
  }

  @override
  void didUpdateWidget(covariant PdfSpikeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentLoader != widget.documentLoader) {
      _documentFuture = widget.documentLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de PDF')),
      body: FutureBuilder<PrintDocument>(
        future: _documentFuture,
        builder: (BuildContext context, AsyncSnapshot<PrintDocument> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Semantics(
                label: 'Generando PDF de ejemplo',
                child: const CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _LoadError(onRetry: _reloadDocument);
          }

          final PrintDocument document = snapshot.requireData;
          final PdfPreviewBuilder? previewBuilder = widget.previewBuilder;
          final Widget preview = previewBuilder == null
              ? PdfDocumentPreview(document: document)
              : previewBuilder(context, document);

          return Column(
            children: <Widget>[
              const _SpikeExplanation(),
              Expanded(child: preview),
              _ActionBar(
                actionInProgress: _actionInProgress,
                onShare: () => _share(document),
                onPrint: () => _print(document),
              ),
            ],
          );
        },
      ),
    );
  }

  void _reloadDocument() {
    setState(() {
      _documentFuture = widget.documentLoader();
    });
  }

  Future<void> _share(PrintDocument document) {
    return _runAction(
      action: () => widget.printGateway.sharePdf(document),
      successMessage: 'Documento preparado para compartir.',
      cancelledMessage: 'Compartir cancelado.',
      failureMessage: 'No se pudo abrir el menú para compartir.',
    );
  }

  Future<void> _print(PrintDocument document) {
    return _runAction(
      action: () => widget.printGateway.printPdf(document),
      successMessage: 'Documento enviado al sistema de impresión.',
      cancelledMessage: 'Impresión cancelada.',
      failureMessage: 'No se pudo abrir el sistema de impresión.',
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
    });

    try {
      final bool completed = await action();
      if (!mounted) {
        return;
      }
      _showMessage(completed ? successMessage : cancelledMessage);
    } on Object {
      if (!mounted) {
        return;
      }
      _showMessage(failureMessage);
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _SpikeExplanation extends StatelessWidget {
  const _SpikeExplanation();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Text(
          'Ejemplo sintético: 8 copias de 35 × 45 mm. La vista previa no '
          'cambia las medidas del PDF.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.actionInProgress,
    required this.onShare,
    required this.onPrint,
  });

  final bool actionInProgress;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('pdf-spike-share'),
                onPressed: actionInProgress ? null : onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('pdf-spike-print'),
                onPressed: actionInProgress ? null : onPrint,
                icon: actionInProgress
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined),
                label: const Text('Imprimir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No se pudo generar el PDF de ejemplo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
