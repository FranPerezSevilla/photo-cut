import 'package:flutter/material.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/features/print_job/print_job_document_factory.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';
import 'package:photo_cut/platform/print/print.dart';

typedef PrintReviewDocumentLoader = Future<PrintDocument> Function();
typedef PrintReviewPreviewBuilder = Widget Function(
  BuildContext context,
  PrintDocument document,
);

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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('reviewAndPrint'))),
      body: SafeArea(
        child: FutureBuilder<PrintDocument>(
          future: _documentFuture,
          builder: (BuildContext context, AsyncSnapshot<PrintDocument> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _PreparingDocument();
            }
            final PrintDocument? document = snapshot.data;
            if (snapshot.hasError || document == null) {
              return _DocumentError(onBack: _goBack, onRetry: _retryDocument);
            }
            final PrintReviewPreviewBuilder? previewBuilder = widget.previewBuilder;
            final Widget preview = previewBuilder == null
                ? PdfDocumentPreview(document: document)
                : previewBuilder(context, document);
            return Column(
              children: <Widget>[
                _ReviewSummary(configuration: widget.configuration, document: document),
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

  Future<PrintDocument> _loadDocument() => Future<PrintDocument>.sync(widget.documentLoader);

  void _retryDocument() {
    setState(() {
      _statusMessage = null;
      _documentFuture = _loadDocument();
    });
  }

  void _goBack() => Navigator.of(context).pop();

  Future<void> _share(PrintDocument document) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return _runAction(
      action: () => widget.printGateway.sharePdf(document),
      successMessage: l10n.text('pdfShareReady'),
      cancelledMessage: l10n.text('shareCancelled'),
      failureMessage: l10n.text('shareFailed'),
    );
  }

  Future<void> _print(PrintDocument document) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return _runAction(
      action: () => widget.printGateway.printPdf(document),
      successMessage: l10n.text('returnedFromPrint'),
      cancelledMessage: l10n.text('printCancelled'),
      failureMessage: l10n.text('printFailed'),
    );
  }

  Future<void> _runAction({
    required Future<bool> Function() action,
    required String successMessage,
    required String cancelledMessage,
    required String failureMessage,
  }) async {
    if (_actionInProgress) return;
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
    if (!mounted) return;
    setState(() {
      _actionInProgress = false;
      _statusMessage = message;
    });
  }
}

final class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.configuration, required this.document});
  final PrintJobConfiguration configuration;
  final PrintDocument document;

  @override
  Widget build(BuildContext context) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    final String fit = configuration.fitMode == ImageFitMode.cropToFill
        ? l10n.text('fill')
        : l10n.text('wholePhoto');
    final String colour = configuration.colorMode == ImageColorMode.grayscale
        ? l10n.text('grayscale')
        : l10n.text('color');
    final String marks = configuration.showCutMarks
        ? l10n.text('withCutMarks')
        : l10n.text('withoutCutMarks');
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.text('finalPdfStep'),
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatMillimetres(configuration.photoWidth.inMillimetres)} × '
              '${_formatMillimetres(configuration.photoHeight.inMillimetres)} mm '
              '· ${l10n.copyCount(configuration.copyCount)} · ${_paperLabel(context, configuration.paperSize.id)}',
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
              l10n.fileLabel(document.filename),
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
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
              label: Text(l10n.text('edit')),
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              key: const Key('share-final-pdf'),
              onPressed: actionInProgress ? null : onShare,
              icon: const Icon(Icons.share_outlined),
              label: Text(l10n.text('sharePdf')),
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
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(nativePrintLabel, textAlign: TextAlign.center),
              ),
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.text('preparingFinalPdf')),
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
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(l10n.text('cannotPrepareFinalPdf'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.text('retry'))),
            TextButton(onPressed: onBack, child: Text(l10n.text('edit'))),
          ],
        ),
      ),
    );
  }
}

String _nativePrintLabel(BuildContext context) {
  final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
  return switch (Theme.of(context).platform) {
    TargetPlatform.android => l10n.text('openAndroidPrint'),
    TargetPlatform.iOS => l10n.text('openIphonePrint'),
    _ => l10n.text('openSystemPrint'),
  };
}

String _paperLabel(BuildContext context, String paperId) {
  return switch (paperId) {
    'a4' => 'A4',
    'us-letter' => PhotoCutLocalizations.of(context).text('letter'),
    'photo-10x15' => '10 × 15 cm',
    _ => paperId,
  };
}

String _formatMillimetres(double value) {
  String text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  return text.replaceFirst(RegExp(r'\.$'), '');
}
