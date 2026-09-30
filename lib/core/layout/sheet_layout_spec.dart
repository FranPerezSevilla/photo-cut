import 'package:photo_cut/core/layout/page_orientation.dart';
import 'package:photo_cut/core/units/units.dart';

/// Inputs required to distribute repeated copies of one physical photo size.
final class SheetLayoutSpec {
  SheetLayoutSpec({
    required this.paperSize,
    required this.photoWidth,
    required this.photoHeight,
    required this.copyCount,
    required this.margin,
    required this.gap,
    this.allowPhotoRotation = true,
    this.pageOrientationPreference = PageOrientationPreference.automatic,
  }) {
    if (copyCount <= 0) {
      throw ArgumentError.value(
        copyCount,
        'copyCount',
        'Copy count must be greater than zero',
      );
    }
  }

  final bool allowPhotoRotation;
  final int copyCount;
  final PhysicalLength gap;
  final PhysicalLength margin;
  final PageOrientationPreference pageOrientationPreference;
  final PaperSize paperSize;
  final PhysicalLength photoHeight;
  final PhysicalLength photoWidth;
}
