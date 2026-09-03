import 'package:photo_cut/core/units/physical_length.dart';

/// One repeated photo rectangle positioned from the page's top-left corner.
final class PlacedPhoto {
  const PlacedPhoto({
    required this.copyIndex,
    required this.pageIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Zero-based copy number in the complete requested job.
  final int copyIndex;

  final PhysicalLength height;
  final PhysicalLength left;

  /// Zero-based PDF page number.
  final int pageIndex;

  final PhysicalLength top;
  final PhysicalLength width;
}
