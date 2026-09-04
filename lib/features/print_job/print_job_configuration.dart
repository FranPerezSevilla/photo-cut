import 'package:flutter/foundation.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

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
  });

  final int copyCount;
  final PhysicalLength gap;
  final SelectedImage image;
  final PhysicalLength margin;
  final PaperSize paperSize;
  final PhysicalLength photoHeight;
  final PhysicalLength photoWidth;
  final bool showCutMarks;

  PrintJobConfiguration copyWith({
    PhysicalLength? photoWidth,
    PhysicalLength? photoHeight,
    PaperSize? paperSize,
    int? copyCount,
    PhysicalLength? margin,
    PhysicalLength? gap,
    bool? showCutMarks,
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
    );
  }
}
