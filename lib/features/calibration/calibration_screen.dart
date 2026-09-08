import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_cut/features/calibration/calibration_pdf_generator.dart';
import 'package:photo_cut/platform/print/print.dart';

typedef CalibrationPreviewBuilder = Widget Function(
  BuildContext context,
  PrintDocument document,
);

final class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({
    super.key,
    required this.generateDocument,
    required this.printGateway,
    this.previewBuilder,
  });

  factory CalibrationScreen.production() {
    const CalibrationPdfGenerator generator = CalibrationPdfGenerator();
    return CalibrationScreen(
      generateDocument: generator.generate,
      printGateway: const PrintingPrintGateway(),
    );
  }

  final Future<CalibrationPdfResult> Function() generateDocument;
  final PrintGateway printGateway;
  final CalibrationPreviewBuilder? previewBuilder;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

final class _CalibrationScreenState extends State<CalibrationScreen> {
  late final Future<CalibrationPdfResult> _result;
  bool _isPrinting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _result = widget.generateDocument();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibrar impresión')),
      body: SafeArea(
        child: FutureBuilder<CalibrationPdfResult>(
          future: _result,
          builder: (BuildContext context, AsyncSnapshot<CalibrationPdfResult> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudo generar la hoja de calibración.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final CalibrationPdfResult result = snapshot.requireData;
            final CalibrationPreviewBuilder previewBuilder =
                widget.previewBuilder ??
                (BuildContext context, PrintDocument document) =>
                    PdfDocumentPreview(document: document);
            return Column(
              children: <Widget>[
                Expanded(child: previewBuilder(context, result.document)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: const <BoxShadow>[
                      BoxShadow(blurRadius: 8, color: Color(0x22000000)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Comprueba un cuadrado de 50 × 50 mm',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Imprime al 100 % o “Tamaño real”.\n'
                        '2. No uses “Ajustar a página” ni opciones equivalentes.\n'
                        '3. Mide el cuadrado con una regla: debe medir 50 mm en ambos lados.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Photo Cut genera el PDF con medidas físicas exactas, pero no puede controlar el escalado que aplique la impresora, el sistema o su controlador.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_message != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(_message!, key: const Key('calibration-message')),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('print-calibration'),
                        onPressed: _isPrinting ? null : () => _print(result.document),
                        icon: _isPrinting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.print_outlined),
                        label: const Text('Imprimir calibración'),
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

  Future<void> _print(PrintDocument document) async {
    setState(() {
      _isPrinting = true;
      _message = null;
    });
    try {
      final bool completed = await widget.printGateway.printPdf(document);
      if (!mounted) {
        return;
      }
      setState(() {
        _message = completed
            ? 'Solicitud de impresión enviada.'
            : 'La impresión se canceló o no se completó.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'No se pudo abrir la impresión. Puedes volver a intentarlo.';
      });
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}
