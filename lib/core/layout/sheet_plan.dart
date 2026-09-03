import 'package:photo_cut/core/layout/page_orientation.dart';
import 'package:photo_cut/core/layout/placed_photo.dart';
import 'package:photo_cut/core/units/units.dart';

/// Deterministic output of laying out equal photo rectangles on physical pages.
final class SheetPlan {
  SheetPlan({
    required this.paperSize,
    required this.pageOrientation,
    required this.pageWidth,
    required this.pageHeight,
    required this.photoRotated,
    required this.columns,
    required this.rows,
    required List<PlacedPhoto> placements,
  }) : placements = List<PlacedPhoto>.unmodifiable(placements) {
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError('A sheet plan must contain a positive grid');
    }
    if (this.placements.isEmpty) {
      throw ArgumentError('A sheet plan must contain at least one photo');
    }
  }

  final int columns;
  final PhysicalLength pageHeight;
  final PageOrientation pageOrientation;
  final PhysicalLength pageWidth;
  final PaperSize paperSize;
  final List<PlacedPhoto> placements;
  final bool photoRotated;
  final int rows;

  int get capacityPerPage => columns * rows;

  int get pageCount {
    return ((placements.length - 1) ~/ capacityPerPage) + 1;
  }

  Iterable<PlacedPhoto> placementsForPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageCount) {
      throw RangeError.range(pageIndex, 0, pageCount - 1, 'pageIndex');
    }

    return placements.where(
      (PlacedPhoto placement) => placement.pageIndex == pageIndex,
    );
  }
}
