import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/quality/quality.dart';
import 'package:photo_cut/core/units/units.dart';

void main() {
  const ResolutionAdvisor advisor = ResolutionAdvisor();

  test('uses pixels remaining after crop against exact output inches', () {
    final ResolutionAdvice advice = advisor.evaluate(
      sourceSize: SourceImageSize(widthPixels: 600, heightPixels: 600),
      cropRect: NormalizedCropRect(
        left: 0.25,
        top: 0.25,
        width: 0.5,
        height: 0.5,
      ),
      fitMode: ImageFitMode.cropToFill,
      outputWidth: PhysicalLength.inches(1),
      outputHeight: PhysicalLength.inches(1),
    );

    expect(advice.horizontalDpi, closeTo(300, 0.001));
    expect(advice.verticalDpi, closeTo(300, 0.001));
    expect(advice.effectiveDpi, closeTo(300, 0.001));
    expect(advice.quality, ResolutionQuality.high);
    expect(advice.shouldWarn, isFalse);
  });

  test('fit-inside measures the physical image content, not letterboxing', () {
    final ResolutionAdvice advice = advisor.evaluate(
      sourceSize: SourceImageSize(widthPixels: 400, heightPixels: 200),
      cropRect: NormalizedCropRect.full,
      fitMode: ImageFitMode.fitInside,
      outputWidth: PhysicalLength.inches(1),
      outputHeight: PhysicalLength.inches(1),
    );

    expect(advice.horizontalDpi, closeTo(400, 0.001));
    expect(advice.verticalDpi, closeTo(400, 0.001));
    expect(advice.effectiveDpi, closeTo(400, 0.001));
  });

  test('300 DPI is high and 200 DPI remains good without warning', () {
    expect(_squareAdvice(300).quality, ResolutionQuality.high);
    expect(_squareAdvice(300).shouldWarn, isFalse);
    expect(_squareAdvice(200).quality, ResolutionQuality.good);
    expect(_squareAdvice(200).shouldWarn, isFalse);
  });

  test('150 to 199 DPI warns as caution', () {
    expect(_squareAdvice(199).quality, ResolutionQuality.caution);
    expect(_squareAdvice(199).shouldWarn, isTrue);
    expect(_squareAdvice(150).quality, ResolutionQuality.caution);
    expect(_squareAdvice(150).shouldWarn, isTrue);
  });

  test('below 150 DPI warns as low resolution', () {
    expect(_squareAdvice(149).quality, ResolutionQuality.low);
    expect(_squareAdvice(149).shouldWarn, isTrue);
  });

  test('advice does not mutate requested physical dimensions', () {
    final PhysicalLength width = PhysicalLength.millimetres(35);
    final PhysicalLength height = PhysicalLength.millimetres(45);

    advisor.evaluate(
      sourceSize: SourceImageSize(widthPixels: 200, heightPixels: 250),
      cropRect: NormalizedCropRect.full,
      fitMode: ImageFitMode.cropToFill,
      outputWidth: width,
      outputHeight: height,
    );

    expect(width.inMillimetres, 35);
    expect(height.inMillimetres, 45);
  });
}

ResolutionAdvice _squareAdvice(int pixels) {
  return const ResolutionAdvisor().evaluate(
    sourceSize: SourceImageSize(widthPixels: pixels, heightPixels: pixels),
    cropRect: NormalizedCropRect.full,
    fitMode: ImageFitMode.cropToFill,
    outputWidth: PhysicalLength.inches(1),
    outputHeight: PhysicalLength.inches(1),
  );
}
