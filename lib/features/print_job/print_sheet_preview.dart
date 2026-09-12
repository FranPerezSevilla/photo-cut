import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';

const List<double> _grayscaleMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// Lightweight app-owned preview driven by the same physical layout plan as PDF.
final class PrintSheetPreview extends StatelessWidget {
  const PrintSheetPreview({
    super.key,
    required this.plan,
    required this.configuration,
    required this.errorMessage,
    this.maxPageHeight = 360,
  });

  static const double _summaryReserve = 13;
  static const double _compactPreviewThreshold = 180;

  final PrintJobConfiguration configuration;
  final String? errorMessage;
  final double maxPageHeight;
  final SheetPlan? plan;

  @override
  Widget build(BuildContext context) {
    final SheetPlan? currentPlan = plan;
    if (currentPlan == null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxPageHeight),
        child: AspectRatio(
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
        ),
      );
    }

    final Uint8List bytes = configuration.image.bytes;
    final double pageWidth = currentPlan.pageWidth.inMillimetres;
    final double pageHeight = currentPlan.pageHeight.inMillimetres;
    final List<PlacedPhoto> firstPage = currentPlan
        .placementsForPage(0)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints outerConstraints) {
        final double availableHeight = outerConstraints.maxHeight;
        final bool compactPreview =
            availableHeight.isFinite &&
            availableHeight < _compactPreviewThreshold;
        final double fittedPageHeight = compactPreview
            ? availableHeight
            : availableHeight.isFinite
            ? math.max(
                0,
                math.min(maxPageHeight, availableHeight - _summaryReserve),
              )
            : maxPageHeight;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: fittedPageHeight),
                child: AspectRatio(
                  aspectRatio: pageWidth / pageHeight,
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  blurRadius: 22,
                                  offset: Offset(0, 8),
                                  color: Color(0x1F14213D),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
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
                                        child: _PreviewPhoto(
                                          key: ValueKey<String>(
                                            'preview-photo-${placement.copyIndex}-'
                                            '${currentPlan.photoRotated}-'
                                            '${configuration.fitMode.name}-'
                                            '${configuration.paperSize.id}-'
                                            '${configuration.photoWidth.inMillimetres}-'
                                            '${configuration.photoHeight.inMillimetres}-'
                                            '${configuration.framingZoom}',
                                          ),
                                          bytes: bytes,
                                          copyIndex: placement.copyIndex,
                                          configuration: configuration,
                                          rotated: currentPlan.photoRotated,
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
            if (!compactPreview) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                currentPlan.pageCount == 1
                    ? '${currentPlan.placements.length} copias · 1 página'
                    : 'Página 1 de ${currentPlan.pageCount} · '
                          '${currentPlan.placements.length} copias',
                key: const Key('layout-page-summary'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  height: 1,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

final class _PreviewPhoto extends StatelessWidget {
  const _PreviewPhoto({
    super.key,
    required this.bytes,
    required this.copyIndex,
    required this.configuration,
    required this.rotated,
  });

  final Uint8List bytes;
  final PrintJobConfiguration configuration;
  final int copyIndex;
  final bool rotated;

  @override
  Widget build(BuildContext context) {
    final Alignment alignment = Alignment(
      configuration.focus.x * 2 - 1,
      configuration.focus.y * 2 - 1,
    );
    Widget image = Image.memory(
      bytes,
      key: ValueKey<String>(
        'preview-image-$copyIndex-${rotated ? 'rotated' : 'upright'}',
      ),
      width: double.infinity,
      height: double.infinity,
      fit: configuration.fitMode == ImageFitMode.cropToFill
          ? BoxFit.cover
          : BoxFit.contain,
      alignment: alignment,
      gaplessPlayback: false,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const Center(child: Icon(Icons.broken_image_outlined));
          },
    );

    if (configuration.fitMode == ImageFitMode.cropToFill &&
        configuration.framingZoom > 1.0001) {
      image = Transform.scale(
        scale: configuration.framingZoom,
        alignment: alignment,
        child: image,
      );
    }

    Widget photo = SizedBox.expand(child: image);

    if (configuration.colorMode == ImageColorMode.grayscale) {
      photo = ColorFiltered(
        key: ValueKey<String>('preview-grayscale-$copyIndex'),
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: photo,
      );
    }
    if (rotated) {
      photo = RotatedBox(quarterTurns: 1, child: SizedBox.expand(child: photo));
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: configuration.showCutMarks
            ? Border.all(color: Colors.black54, width: 0.5)
            : null,
      ),
      child: ClipRect(child: photo),
    );
  }
}
