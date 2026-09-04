import 'package:flutter/foundation.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

const Object _keepSourceSize = Object();

/// Immutable, widget-independent description of the document Photo Cut will
/// generate for one selected image.
@immutable
final class PrintJobConfiguration {
  const PrintJobConfiguration({
    required this.image,
    required this.photoWidth,
    required this.photoHeight,
    required this.paperSize,
    required this.copyCount,
    required this.margin,
    required this.gap,
    required this.showCutMarks,
    required this.fitMode,
    required this.colorMode,
    required this.focus,
    required this.cropRect,
    required this.sourceSize,
  });

  final ImageColorMode colorMode;
  final int copyCount;
  final NormalizedCropRect cropRect;
  final ImageFitMode fitMode;
  final NormalizedPoint focus;
  final PhysicalLength gap;
  final SelectedImage image;
  final PhysicalLength margin;
  final PaperSize paperSize;
  final PhysicalLength photoHeight;
  final PhysicalLength photoWidth;
  final bool showCutMarks;
  final SourceImageSize? sourceSize;

  double get photoAspectRatio {
    return photoWidth.inMillimetres / photoHeight.inMillimetres;
  }

  PrintJobConfiguration copyWith({
    PhysicalLength? photoWidth,
    PhysicalLength? photoHeight,
    PaperSize? paperSize,
    int? copyCount,
    PhysicalLength? margin,
    PhysicalLength? gap,
    bool? showCutMarks,
    ImageFitMode? fitMode,
    ImageColorMode? colorMode,
    NormalizedPoint? focus,
    NormalizedCropRect? cropRect,
    Object? sourceSize = _keepSourceSize,
  }) {
    return PrintJobConfiguration(
      image: image,
      photoWidth: photoWidth ?? this.photoWidth,
      photoHeight: photoHeight ?? this.photoHeight,
      paperSize: paperSize ?? this.paperSize,
      copyCount: copyCount ?? this.copyCount,
      margin: margin ?? this.margin,
      gap: gap ?? this.gap,
      showCutMarks: showCutMarks ?? this.showCutMarks,
      fitMode: fitMode ?? this.fitMode,
      colorMode: colorMode ?? this.colorMode,
      focus: focus ?? this.focus,
      cropRect: cropRect ?? this.cropRect,
      sourceSize: identical(sourceSize, _keepSourceSize)
          ? this.sourceSize
          : sourceSize as SourceImageSize?,
    );
  }
}
