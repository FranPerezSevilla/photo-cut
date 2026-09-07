import 'package:flutter/material.dart';
import 'package:photo_cut/platform/print/print.dart';

typedef ZoomablePdfPreviewBuilder = Widget Function(
  BuildContext context,
  PrintDocument document,
);

/// Viewer-only zoom and pan around the exact PDF preview.
///
/// The transformation controller never enters print-job state, so changing
/// zoom cannot affect physical geometry or generated document bytes.
final class ZoomablePdfDocumentPreview extends StatefulWidget {
  const ZoomablePdfDocumentPreview({
    super.key,
    required this.document,
    this.previewBuilder,
    this.transformationController,
  });

  final PrintDocument document;
  final ZoomablePdfPreviewBuilder? previewBuilder;
  final TransformationController? transformationController;

  @override
  State<ZoomablePdfDocumentPreview> createState() =>
      _ZoomablePdfDocumentPreviewState();
}

final class _ZoomablePdfDocumentPreviewState
    extends State<ZoomablePdfDocumentPreview> {
  late final TransformationController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.transformationController == null;
    _controller = widget.transformationController ?? TransformationController();
  }

  @override
  void didUpdateWidget(covariant ZoomablePdfDocumentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.document, widget.document)) {
      _fitPage();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ZoomablePdfPreviewBuilder builder =
        widget.previewBuilder ??
        (BuildContext context, PrintDocument document) {
          return PdfDocumentPreview(document: document);
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return ClipRect(
                  child: InteractiveViewer(
                    key: const Key('zoomable-pdf-viewport'),
                    transformationController: _controller,
                    minScale: 1,
                    maxScale: 6,
                    panEnabled: true,
                    scaleEnabled: true,
                    boundaryMargin: const EdgeInsets.all(96),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: builder(context, widget.document),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: <Widget>[
            AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final int percentage =
                    (_controller.value.getMaxScaleOnAxis() * 100).round();
                return Text(
                  '$percentage%',
                  key: const Key('pdf-zoom-percentage'),
                  style: Theme.of(context).textTheme.labelMedium,
                );
              },
            ),
            TextButton.icon(
              key: const Key('fit-page-preview'),
              onPressed: _fitPage,
              icon: const Icon(Icons.fit_screen_outlined),
              label: const Text('Encajar página'),
            ),
          ],
        ),
        Text(
          'Pellizca para ampliar · arrastra para moverte',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _fitPage() {
    _controller.value = Matrix4.identity();
  }
}
