import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';

void main() {
  const VisualFramingMapper mapper = VisualFramingMapper();

  test('a wide source maps horizontal image drag into normalized focus', () {
    final SourceImageSize source = SourceImageSize(
      widthPixels: 400,
      heightPixels: 200,
    );

    final NormalizedPoint moved = mapper.applyDrag(
      sourceSize: source,
      targetAspectRatio: 1,
      frameWidth: 200,
      frameHeight: 200,
      currentFocus: NormalizedPoint.center,
      dragDeltaX: 100,
      dragDeltaY: 80,
    );

    expect(
      mapper.axisFor(sourceSize: source, targetAspectRatio: 1),
      VisualFramingAxis.horizontal,
    );
    expect(moved.x, closeTo(0, 0.000001));
    expect(moved.y, 0.5);
  });

  test('a tall source maps vertical image drag into normalized focus', () {
    final SourceImageSize source = SourceImageSize(
      widthPixels: 200,
      heightPixels: 400,
    );

    final NormalizedPoint moved = mapper.applyDrag(
      sourceSize: source,
      targetAspectRatio: 1,
      frameWidth: 200,
      frameHeight: 200,
      currentFocus: NormalizedPoint.center,
      dragDeltaX: 80,
      dragDeltaY: 100,
    );

    expect(
      mapper.axisFor(sourceSize: source, targetAspectRatio: 1),
      VisualFramingAxis.vertical,
    );
    expect(moved.x, 0.5);
    expect(moved.y, closeTo(0, 0.000001));
  });

  test('visual drag clamps normalized focus to source bounds', () {
    final SourceImageSize source = SourceImageSize(
      widthPixels: 400,
      heightPixels: 200,
    );

    final NormalizedPoint left = mapper.applyDrag(
      sourceSize: source,
      targetAspectRatio: 1,
      frameWidth: 200,
      frameHeight: 200,
      currentFocus: NormalizedPoint.center,
      dragDeltaX: 1000,
      dragDeltaY: 0,
    );
    final NormalizedPoint right = mapper.applyDrag(
      sourceSize: source,
      targetAspectRatio: 1,
      frameWidth: 200,
      frameHeight: 200,
      currentFocus: NormalizedPoint.center,
      dragDeltaX: -1000,
      dragDeltaY: 0,
    );

    expect(left.x, 0);
    expect(right.x, 1);
  });

  test('matching aspects do not invent movement or a second crop axis', () {
    final SourceImageSize source = SourceImageSize(
      widthPixels: 300,
      heightPixels: 400,
    );
    final NormalizedPoint original = NormalizedPoint(x: 0.2, y: 0.8);

    final NormalizedPoint moved = mapper.applyDrag(
      sourceSize: source,
      targetAspectRatio: 0.75,
      frameWidth: 225,
      frameHeight: 300,
      currentFocus: original,
      dragDeltaX: 100,
      dragDeltaY: 100,
    );

    expect(
      mapper.axisFor(sourceSize: source, targetAspectRatio: 0.75),
      VisualFramingAxis.none,
    );
    expect(moved, original);
  });

  test('rejects invalid frame geometry', () {
    expect(
      () => mapper.applyDrag(
        sourceSize: SourceImageSize(widthPixels: 400, heightPixels: 200),
        targetAspectRatio: 1,
        frameWidth: 0,
        frameHeight: 200,
        currentFocus: NormalizedPoint.center,
        dragDeltaX: 1,
        dragDeltaY: 1,
      ),
      throwsArgumentError,
    );
  });
}
