import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_cut/features/pdf_spike/pdf_spike.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.pdfSpikeBuilder});

  final WidgetBuilder? pdfSpikeBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Cut')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _ProductIllustration(),
                  const SizedBox(height: 32),
                  Text(
                    'Imprime fotos al tamaño exacto',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Elige una foto, indica sus medidas y crea una hoja lista '
                    'para imprimir.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => _showFoundationMessage(context),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Elegir foto'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin cuenta · Sin nube · Sin suscripción',
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
        ),
      ),
    );
  }

  void _showFoundationMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Base técnica lista. El selector de fotos llega en M2.'),
      ),
    );
  }

  void _openPdfSpike(BuildContext context) {
    final WidgetBuilder builder =
        pdfSpikeBuilder ?? (BuildContext context) => PdfSpikeScreen.production();
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: builder),
      ),
    );
  }
}

final class _ProductIllustration extends StatelessWidget {
  const _ProductIllustration();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Hoja con varias copias de una fotografía',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Center(
            child: Icon(Icons.photo_size_select_large_outlined, size: 104),
          ),
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
