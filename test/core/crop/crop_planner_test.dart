import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';

void main() {
  const CropPlanner planner = CropPlanner();

  test('crops a landscape source horizontally to the requested aspect', () {
    final NormalizedCropRect crop = planner.plan(
      sourceSize: SourceImageSize(widthPixels: 400, heightPixels: 200),
      targetAspectRatio: 1,
      focus: NormalizedPoint.center,
    );

    expect(crop.left, closeTo(0.25, 0.000001));
    expect(crop.top, 0);
    expect(crop.width, closeTo(0.5, 0.000001));
    expect(crop.height, 1);
  });

  test('horizontal focus moves the crop without changing its size', () {
    final SourceImageSize source = SourceImageSize(
      widthPixels: 400,
      heightPixels: 200,
    );
    final NormalizedCropRect left = planner.plan(
      sourceSize: source,
      targetAspectRatio: 1,
      focus: NormalizedPoint(x: 0, y: 0.5),
    );
    final NormalizedCropRect right = planner.plan(
      sourceSize: source,
      targetAspectRatio: 1,
      focus: NormalizedPoint(x: 1, y: 0.5),
    );

    expect(left.left, 0);
    expect(right.right, closeTo(1, 0.000001));
    expect(left.width, right.width);
  });

  test('crops a portrait source vertically to the requested aspect', () {
    final NormalizedCropRect crop = planner.plan(
      sourceSize: SourceImageSize(widthPixels: 200, heightPixels: 400),
      targetAspectRatio: 1,
      focus: NormalizedPoint.center,
    );

    expect(crop.left, 0);
    expect(crop.top, closeTo(0.25, 0.000001));
    expect(crop.width, 1);
    expect(crop.height, closeTo(0.5, 0.000001));
  });

  test('matching source and target aspects keep the full image', () {
    final NormalizedCropRect crop = planner.plan(
      sourceSize: SourceImageSize(widthPixels: 350, heightPixels: 450),
      targetAspectRatio: 35 / 45,
      focus: NormalizedPoint(x: 0, y: 1),
    );

    expect(crop, NormalizedCropRect.full);
  });

  test('normalized value objects reject out-of-range data', () {
    expect(
      () => NormalizedPoint(x: -0.1, y: 0.5),
      throwsArgumentError,
    );
    expect(
      () => NormalizedCropRect(
        left: 0.8,
        top: 0,
        width: 0.3,
        height: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => planner.plan(
        sourceSize: SourceImageSize(widthPixels: 100, heightPixels: 100),
        targetAspectRatio: 0,
        focus: NormalizedPoint.center,
      ),
      throwsArgumentError,
    );
  });
}
