import 'package:photo_cut/core/layout/page_orientation.dart';
import 'package:photo_cut/core/layout/placed_photo.dart';
import 'package:photo_cut/core/layout/sheet_layout_spec.dart';
import 'package:photo_cut/core/layout/sheet_plan.dart';
import 'package:photo_cut/core/units/physical_length.dart';

/// Distributes repeated equal rectangles without using Flutter or PDF APIs.
final class SheetLayoutEngine {
  const SheetLayoutEngine();

  SheetPlan createPlan(SheetLayoutSpec spec) {
    final List<_LayoutCandidate> candidates = <_LayoutCandidate>[];

    void consider(PageOrientation pageOrientation, bool photoRotated) {
      final _LayoutCandidate? candidate = _createCandidate(
        spec: spec,
        pageOrientation: pageOrientation,
        photoRotated: photoRotated,
      );
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    consider(PageOrientation.portrait, false);
    consider(PageOrientation.landscape, false);

    final bool photoCanRotate =
        spec.allowPhotoRotation && spec.photoWidth != spec.photoHeight;
    if (photoCanRotate) {
      consider(PageOrientation.portrait, true);
      consider(PageOrientation.landscape, true);
    }

    if (candidates.isEmpty) {
      throw StateError(
        'The requested photo size does not fit inside the selected paper and margin',
      );
    }

    candidates.sort(_compareCandidates);
    final _LayoutCandidate selected = candidates.first;
    final List<PlacedPhoto> placements = <PlacedPhoto>[];

    for (int copyIndex = 0; copyIndex < spec.copyCount; copyIndex += 1) {
      final int pageIndex = copyIndex ~/ selected.capacity;
      final int indexOnPage = copyIndex % selected.capacity;
      final int row = indexOnPage ~/ selected.columns;
      final int column = indexOnPage % selected.columns;
      final double leftMillimetres =
          selected.originLeftMillimetres +
          column * (selected.photoWidthMillimetres + selected.gapMillimetres);
      final double topMillimetres =
          selected.originTopMillimetres +
          row * (selected.photoHeightMillimetres + selected.gapMillimetres);

      placements.add(
        PlacedPhoto(
          copyIndex: copyIndex,
          pageIndex: pageIndex,
          left: PhysicalLength.millimetres(leftMillimetres),
          top: PhysicalLength.millimetres(topMillimetres),
          width: PhysicalLength.millimetres(selected.photoWidthMillimetres),
          height: PhysicalLength.millimetres(selected.photoHeightMillimetres),
        ),
      );
    }

    return SheetPlan(
      paperSize: spec.paperSize,
      pageOrientation: selected.pageOrientation,
      pageWidth: PhysicalLength.millimetres(selected.pageWidthMillimetres),
      pageHeight: PhysicalLength.millimetres(selected.pageHeightMillimetres),
      photoRotated: selected.photoRotated,
      columns: selected.columns,
      rows: selected.rows,
      placements: placements,
    );
  }

  static int _compareCandidates(_LayoutCandidate left, _LayoutCandidate right) {
    final int capacityComparison = right.capacity.compareTo(left.capacity);
    if (capacityComparison != 0) {
      return capacityComparison;
    }

    if (left.photoRotated != right.photoRotated) {
      return left.photoRotated ? 1 : -1;
    }

    final int pageOrientationComparison = left.pageOrientation.index.compareTo(
      right.pageOrientation.index,
    );
    if (pageOrientationComparison != 0) {
      return pageOrientationComparison;
    }

    final int columnComparison = right.columns.compareTo(left.columns);
    if (columnComparison != 0) {
      return columnComparison;
    }

    return right.rows.compareTo(left.rows);
  }

  static _LayoutCandidate? _createCandidate({
    required SheetLayoutSpec spec,
    required PageOrientation pageOrientation,
    required bool photoRotated,
  }) {
    final bool pageIsLandscape = pageOrientation == PageOrientation.landscape;
    final double pageWidthMillimetres = pageIsLandscape
        ? spec.paperSize.height.inMillimetres
        : spec.paperSize.width.inMillimetres;
    final double pageHeightMillimetres = pageIsLandscape
        ? spec.paperSize.width.inMillimetres
        : spec.paperSize.height.inMillimetres;
    final double photoWidthMillimetres = photoRotated
        ? spec.photoHeight.inMillimetres
        : spec.photoWidth.inMillimetres;
    final double photoHeightMillimetres = photoRotated
        ? spec.photoWidth.inMillimetres
        : spec.photoHeight.inMillimetres;
    final double marginMillimetres = spec.margin.inMillimetres;
    final double gapMillimetres = spec.gap.inMillimetres;
    final double usableWidthMillimetres =
        pageWidthMillimetres - (marginMillimetres * 2);
    final double usableHeightMillimetres =
        pageHeightMillimetres - (marginMillimetres * 2);

    if (usableWidthMillimetres <= 0 || usableHeightMillimetres <= 0) {
      return null;
    }

    final int columns = _fitCount(
      availableMillimetres: usableWidthMillimetres,
      itemMillimetres: photoWidthMillimetres,
      gapMillimetres: gapMillimetres,
    );
    final int rows = _fitCount(
      availableMillimetres: usableHeightMillimetres,
      itemMillimetres: photoHeightMillimetres,
      gapMillimetres: gapMillimetres,
    );

    if (columns <= 0 || rows <= 0) {
      return null;
    }

    final double gridWidthMillimetres =
        (columns * photoWidthMillimetres) + ((columns - 1) * gapMillimetres);
    final double gridHeightMillimetres =
        (rows * photoHeightMillimetres) + ((rows - 1) * gapMillimetres);
    final double originLeftMillimetres =
        marginMillimetres +
        ((usableWidthMillimetres - gridWidthMillimetres) / 2);
    final double originTopMillimetres =
        marginMillimetres +
        ((usableHeightMillimetres - gridHeightMillimetres) / 2);

    return _LayoutCandidate(
      pageOrientation: pageOrientation,
      photoRotated: photoRotated,
      pageWidthMillimetres: pageWidthMillimetres,
      pageHeightMillimetres: pageHeightMillimetres,
      photoWidthMillimetres: photoWidthMillimetres,
      photoHeightMillimetres: photoHeightMillimetres,
      gapMillimetres: gapMillimetres,
      originLeftMillimetres: originLeftMillimetres,
      originTopMillimetres: originTopMillimetres,
      columns: columns,
      rows: rows,
    );
  }

  static int _fitCount({
    required double availableMillimetres,
    required double itemMillimetres,
    required double gapMillimetres,
  }) {
    const double boundaryTolerance = 0.000000001;
    final double count =
        (availableMillimetres + gapMillimetres) /
        (itemMillimetres + gapMillimetres);
    return (count + boundaryTolerance).floor();
  }
}

final class _LayoutCandidate {
  const _LayoutCandidate({
    required this.pageOrientation,
    required this.photoRotated,
    required this.pageWidthMillimetres,
    required this.pageHeightMillimetres,
    required this.photoWidthMillimetres,
    required this.photoHeightMillimetres,
    required this.gapMillimetres,
    required this.originLeftMillimetres,
    required this.originTopMillimetres,
    required this.columns,
    required this.rows,
  });

  final int columns;
  final double gapMillimetres;
  final double originLeftMillimetres;
  final double originTopMillimetres;
  final double pageHeightMillimetres;
  final PageOrientation pageOrientation;
  final double pageWidthMillimetres;
  final double photoHeightMillimetres;
  final bool photoRotated;
  final double photoWidthMillimetres;
  final int rows;

  int get capacity => columns * rows;
}
