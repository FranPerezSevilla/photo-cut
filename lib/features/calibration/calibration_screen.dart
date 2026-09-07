import 'package:flutter/material.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/pdf/pdf.dart';
import 'package:photo_cut/platform/print/print.dart';

typedef CalibrationDocumentLoader = Future<CalibrationPdfResult> Function(
  PaperSize paperSize,
);

typedef CalibrationPreviewBuilder = Widget Function(
  BuildContext context,
  PrintDocument document,
);

/// Free calibration flow used before relying on exact physical print sizes.
final class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({
    super.key,
    required this.documentLoader,
    required this.printGateway,
    this.previewBuilder,
  });

  factory CalibrationScreen.production({Key? key}) {
    const CalibrationPdfRenderer renderer = CalibrationPdfRenderer();
    return CalibrationScreen(
      key: key,
      documentLoader: renderer.render,
      printGateway: const PrintingPrintGateway(),
    );
  }

  final CalibrationDocumentLoader documentLoader;
  final CalibrationPreviewBuilder? previewBuilder;
  final PrintGateway printGateway;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

final class _CalibrationScreenState extends State<CalibrationScreen> {
  PaperSize _paperSize = PaperSize.a4;
  late Future<CalibrationPdfResult> _resultFuture;
  bool _actionInProgress = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _resultFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibrar impresión')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Comprueba que tu impresora respeta las medidas',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El PDF contiene un cuadrado de referencia de 50 × 50 mm.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La calibración está disponible sin compra y no depende de una foto.',
                    key: const Key('calibration-before-purchase'),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<PaperSize>(
                    key: const Key('calibration-paper-size'),
                    initialValue: _paperSize,
                    decoration: const InputDecoration(
                      labelText: 'Papel que vas a imprimir',
                    ),
                    items: PaperSize.presets
                        .map(
                          (PaperSize paper) => DropdownMenuItem<PaperSize>(
                            value: paper,
                            child: Text(_paperLabel(paper)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _actionInProgress
                        ? null
                        : (PaperSize? paper) {
                            if (paper == null || paper == _paperSize) {
                              return;
                            }
                            setState(() {
                              _paperSize = paper;
                              _statusMessage = null;
                              _resultFuture = _load();
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 360,
                    child: FutureBuilder<CalibrationPdfResult>(
                      future: _resultFuture,
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<CalibrationPdfResult> snapshot,
                      ) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final CalibrationPdfResult? result = snapshot.data;
                        if (snapshot.hasError || result == null) {
                          return _CalibrationError(onRetry: _retry);
                        }
                        final CalibrationPreviewBuilder? previewBuilder =
                            widget.previewBuilder;
                        return previewBuilder == null
                            ? PdfDocumentPreview(document: result.document)
                            : previewBuilder(context, result.document);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ActualSizeGuidance(),
                  if (_statusMessage != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _statusMessage!,
                        key: const Key('calibration-status'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FutureBuilder<CalibrationPdfResult>(
                    future: _resultFuture,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<CalibrationPdfResult> snapshot,
                    ) {
                      final PrintDocument? document = snapshot.data?.document;
                      final bool enabled =
                          document != null && !_actionInProgress;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          OutlinedButton.icon(
                            key: const Key('share-calibration-pdf'),
                            onPressed: enabled
                                ? () => _share(document)
                                : null,
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Compartir PDF de calibración'),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            key: const Key('print-calibration-pdf'),
                            onPressed: enabled
                                ? () => _print(document)
                                : null,
                            icon: _actionInProgress
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.print_outlined),
                            label: Text(_nativePrintLabel(context)),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<CalibrationPdfResult> _load() {
    return Future<CalibrationPdfResult>.sync(
      () => widget.documentLoader(_paperSize),
    );
  }

  void _retry() {
    setState(() {
      _statusMessage = null;
      _resultFuture = _load();
    });
  }

  Future<void> _share(PrintDocument document) {
    return _runAction(
      action: () => widget.printGateway.sharePdf(document),
      successMessage: 'PDF de calibración preparado para compartir.',
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

final class _ActualSizeGuidance extends StatelessWidget {
  const _ActualSizeGuidance();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Cómo hacer la prueba',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text('1. Usa en la impresora el mismo tamaño de papel que has elegido aquí.'),
            const SizedBox(height: 6),
            const Text(
              '2. Imprime a 100% / Tamaño real (Actual size).',
              key: Key('actual-size-guidance'),
            ),
            const SizedBox(height: 6),
            const Text(
              '3. No uses Ajustar a página / Fit to page.',
              key: Key('no-fit-to-page-guidance'),
            ),
            const SizedBox(height: 6),
            const Text('4. Mide con una regla el ancho y el alto del cuadrado: ambos deben ser 50 mm.'),
            const SizedBox(height: 12),
            const Text(
              'Photo Cut controla la geometría del PDF, pero el controlador de la impresora y el hardware pueden escalar el resultado.',
              key: Key('printer-scaling-caveat'),
            ),
            const SizedBox(height: 8),
            Text(
              'Si cualquiera de los lados se desvía más de 1 mm, revisa la escala de impresión antes de confiar en medidas exactas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

final class _CalibrationError extends StatelessWidget {
  const _CalibrationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 44),
          const SizedBox(height: 10),
          const Text('No se pudo generar el PDF de calibración.'),
          const SizedBox(height: 10),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
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

String _nativePrintLabel(BuildContext context) {
  return switch (Theme.of(context).platform) {
    TargetPlatform.android => 'Abrir impresión de Android',
    TargetPlatform.iOS => 'Abrir impresión de iPhone',
    _ => 'Abrir impresión del sistema',
  };
}
