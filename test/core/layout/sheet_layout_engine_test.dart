import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/layout/layout.dart';
import 'package:photo_cut/core/units/units.dart';

void main() {
  const SheetLayoutEngine engine = SheetLayoutEngine();
  const double tolerance = 0.000001;

  SheetLayoutSpec passportSpec({int copyCount = 8}) {
    return SheetLayoutSpec(
      paperSize: PaperSize.a4,
      photoWidth: PhysicalLength.millimetres(35),
      photoHeight: PhysicalLength.millimetres(45),
      copyCount: copyCount,
      margin: PhysicalLength.millimetres(8),
      gap: PhysicalLength.millimetres(2),
    );
  }

  test('lays out eight 35 x 45 mm copies on one A4 page', () {
    final SheetPlan plan = engine.createPlan(passportSpec());

    expect(plan.pageOrientation, PageOrientation.portrait);
    expect(plan.photoRotated, isFalse);
    expect(plan.pageWidth.inMillimetres, closeTo(210, tolerance));
    expect(plan.pageHeight.inMillimetres, closeTo(297, tolerance));
    expect(plan.columns, 5);
    expect(plan.rows, 6);
    expect(plan.capacityPerPage, 30);
    expect(plan.pageCount, 1);
    expect(plan.placements, hasLength(8));

    final PlacedPhoto first = plan.placements[0];
    final PlacedPhoto second = plan.placements[1];
    final PlacedPhoto nextRow = plan.placements[5];

    expect(first.left.inMillimetres, closeTo(13.5, tolerance));
    expect(first.top.inMillimetres, closeTo(8.5, tolerance));
    expect(first.width.inMillimetres, closeTo(35, tolerance));
    expect(first.height.inMillimetres, closeTo(45, tolerance));
    expect(
      second.left.inMillimetres -
          first.left.inMillimetres -
          first.width.inMillimetres,
      closeTo(2, tolerance),
    );
    expect(
      nextRow.top.inMillimetres -
          first.top.inMillimetres -
          first.height.inMillimetres,
      closeTo(2, tolerance),
    );
  });

  test('chooses landscape paper before rotating the photo when capacity ties', () {
    final SheetPlan plan = engine.createPlan(
      SheetLayoutSpec(
        paperSize: PaperSize.a4,
        photoWidth: PhysicalLength.millimetres(80),
        photoHeight: PhysicalLength.millimetres(30),
        copyCount: 18,
        margin: PhysicalLength.millimetres(8),
        gap: PhysicalLength.millimetres(2),
      ),
    );

    expect(plan.capacityPerPage, 18);
    expect(plan.pageOrientation, PageOrientation.landscape);
    expect(plan.photoRotated, isFalse);
    expect(plan.columns, 3);
    expect(plan.rows, 6);
  });

  test('uses portrait paper as the deterministic final tie-breaker', () {
    final SheetPlan plan = engine.createPlan(
      SheetLayoutSpec(
        paperSize: PaperSize.a4,
        photoWidth: PhysicalLength.millimetres(50),
        photoHeight: PhysicalLength.millimetres(50),
        copyCount: 1,
        margin: PhysicalLength.millimetres(8),
        gap: PhysicalLength.millimetres(2),
      ),
    );

    expect(plan.capacityPerPage, 15);
    expect(plan.pageOrientation, PageOrientation.portrait);
    expect(plan.photoRotated, isFalse);
  });

  test('creates the minimum number of pages for copies beyond capacity', () {
    final SheetPlan plan = engine.createPlan(passportSpec(copyCount: 61));

    expect(plan.capacityPerPage, 30);
    expect(plan.pageCount, 3);
    expect(plan.placementsForPage(0), hasLength(30));
    expect(plan.placementsForPage(1), hasLength(30));
    expect(plan.placementsForPage(2), hasLength(1));
    expect(plan.placements.last.pageIndex, 2);
  });

  test('keeps every placement inside its page without overlaps', () {
    final List<SheetLayoutSpec> specs = <SheetLayoutSpec>[
      passportSpec(copyCount: 75),
      SheetLayoutSpec(
        paperSize: PaperSize.usLetter,
        photoWidth: PhysicalLength.millimetres(50),
        photoHeight: PhysicalLength.millimetres(50),
        copyCount: 24,
        margin: PhysicalLength.millimetres(10),
        gap: PhysicalLength.millimetres(3),
      ),
      SheetLayoutSpec(
        paperSize: PaperSize.photo10x15,
        photoWidth: PhysicalLength.millimetres(30),
        photoHeight: PhysicalLength.millimetres(40),
        copyCount: 12,
        margin: PhysicalLength.millimetres(5),
        gap: PhysicalLength.millimetres(2),
      ),
      SheetLayoutSpec(
        paperSize: PaperSize.a4,
        photoWidth: PhysicalLength.millimetres(80),
        photoHeight: PhysicalLength.millimetres(30),
        copyCount: 40,
        margin: PhysicalLength.millimetres(8),
        gap: PhysicalLength.millimetres(2),
      ),
    ];

    for (final SheetLayoutSpec spec in specs) {
      final SheetPlan plan = engine.createPlan(spec);
      _expectPlacementsAreValid(plan, spec.margin, tolerance);
    }
  });

  test('rejects a copy count that is not positive', () {
    expect(
      () => SheetLayoutSpec(
        paperSize: PaperSize.a4,
        photoWidth: PhysicalLength.millimetres(35),
        photoHeight: PhysicalLength.millimetres(45),
        copyCount: 0,
        margin: PhysicalLength.millimetres(8),
        gap: PhysicalLength.millimetres(2),
      ),
      throwsArgumentError,
    );
  });

  test('rejects a photo that cannot fit within the selected margin', () {
    final SheetLayoutSpec spec = SheetLayoutSpec(
      paperSize: PaperSize.photo10x15,
      photoWidth: PhysicalLength.millimetres(200),
      photoHeight: PhysicalLength.millimetres(200),
      copyCount: 1,
      margin: PhysicalLength.millimetres(8),
      gap: PhysicalLength.millimetres(2),
    );

    expect(() => engine.createPlan(spec), throwsStateError);
  });

  test('rejects page indexes outside the generated plan', () {
    final SheetPlan plan = engine.createPlan(passportSpec());

    expect(() => plan.placementsForPage(-1), throwsRangeError);
    expect(() => plan.placementsForPage(1), throwsRangeError);
  });
}

void _expectPlacementsAreValid(
  SheetPlan plan,
  PhysicalLength minimumMargin,
  double tolerance,
) {
  for (final PlacedPhoto placement in plan.placements) {
    final double left = placement.left.inMillimetres;
    final double top = placement.top.inMillimetres;
    final double right = left + placement.width.inMillimetres;
    final double bottom = top + placement.height.inMillimetres;

    expect(left, greaterThanOrEqualTo(minimumMargin.inMillimetres - tolerance));
    expect(top, greaterThanOrEqualTo(minimumMargin.inMillimetres - tolerance));
    expect(
      right,
      lessThanOrEqualTo(
        plan.pageWidth.inMillimetres - minimumMargin.inMillimetres + tolerance,
      ),
    );
    expect(
      bottom,
      lessThanOrEqualTo(
        plan.pageHeight.inMillimetres - minimumMargin.inMillimetres + tolerance,
      ),
    );
  }

  for (int firstIndex = 0;
      firstIndex < plan.placements.length;
      firstIndex += 1) {
    final PlacedPhoto first = plan.placements[firstIndex];
    for (int secondIndex = firstIndex + 1;
        secondIndex < plan.placements.length;
        secondIndex += 1) {
      final PlacedPhoto second = plan.placements[secondIndex];
      if (first.pageIndex != second.pageIndex) {
        continue;
      }

      final double firstRight =
          first.left.inMillimetres + first.width.inMillimetres;
      final double firstBottom =
          first.top.inMillimetres + first.height.inMillimetres;
      final double secondRight =
          second.left.inMillimetres + second.width.inMillimetres;
      final double secondBottom =
          second.top.inMillimetres + second.height.inMillimetres;
      final bool separated =
          firstRight <= second.left.inMillimetres + tolerance ||
          secondRight <= first.left.inMillimetres + tolerance ||
          firstBottom <= second.top.inMillimetres + tolerance ||
          secondBottom <= first.top.inMillimetres + tolerance;

      expect(
        separated,
        isTrue,
        reason: 'Copies ${first.copyIndex} and ${second.copyIndex} overlap',
      );
    }
  }
}
