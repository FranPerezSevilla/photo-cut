import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  test(
    'defaults become reviewable after orientation-aware inspection',
    () async {
      final PrintConfigurationController controller =
          PrintConfigurationController(
            image: _image(),
            imageProcessor: _FakeImageProcessor(
              size: SourceImageSize(widthPixels: 400, heightPixels: 200),
            ),
          );

      expect(controller.state.canReview, isFalse);
      await controller.inspectImage();

      final PrintConfigurationState state = controller.state;
      expect(state.configuration.photoWidth.inMillimetres, 35);
      expect(state.configuration.photoHeight.inMillimetres, 45);
      expect(state.configuration.paperSize, PaperSize.a4);
      expect(state.configuration.copyCount, 8);
      expect(state.configuration.margin.inMillimetres, 8);
      expect(state.configuration.gap.inMillimetres, 2);
      expect(state.configuration.showCutMarks, isTrue);
      expect(state.configuration.fitMode, ImageFitMode.cropToFill);
      expect(state.configuration.colorMode, ImageColorMode.color);
      expect(state.configuration.sourceSize?.widthPixels, 400);
      expect(state.configuration.cropRect.width, lessThan(1));
      expect(state.previewPlan?.placements.length, 8);
      expect(state.canReview, isTrue);
    },
  );

  test('changing units preserves canonical physical sizes', () {
    final PrintConfigurationController controller =
        PrintConfigurationController(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
        );
    final double originalWidth =
        controller.state.configuration.photoWidth.inMillimetres;

    controller.changeUnit(LengthUnit.centimetres);
    expect(controller.state.widthInput, '3.5');
    expect(
      controller.state.configuration.photoWidth.inMillimetres,
      originalWidth,
    );

    controller.changeUnit(LengthUnit.inches);
    expect(controller.state.widthInput, '1.378');
    expect(
      controller.state.configuration.photoWidth.inMillimetres,
      closeTo(originalWidth, 0.001),
    );
  });

  test('invalid dimensions and copy count expose errors and block review', () {
    final PrintConfigurationController controller =
        PrintConfigurationController(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
        );

    controller.changeWidth('0');
    controller.changeHeight('');
    controller.changeCopyCount('1000');

    expect(controller.state.widthError, isNotNull);
    expect(controller.state.heightError, isNotNull);
    expect(controller.state.copyCountError, isNotNull);
    expect(controller.state.canReview, isFalse);
  });

  test(
    'fit, colour and focus update immutable document configuration',
    () async {
      final PrintConfigurationController controller =
          PrintConfigurationController(
            image: _image(),
            imageProcessor: _FakeImageProcessor(
              size: SourceImageSize(widthPixels: 400, heightPixels: 200),
            ),
          );
      await controller.inspectImage();
      final PrintJobConfiguration before = controller.state.configuration;

      controller.changeFocusX(1);
      controller.changeFocusY(0);
      controller.changeColorMode(ImageColorMode.grayscale);
      final PrintJobConfiguration cropped = controller.state.configuration;

      expect(cropped, isNot(same(before)));
      expect(cropped.focus, NormalizedPoint(x: 1, y: 0));
      expect(cropped.colorMode, ImageColorMode.grayscale);
      expect(cropped.cropRect.right, closeTo(1, 0.000001));

      controller.changeFitMode(ImageFitMode.fitInside);
      final PrintJobConfiguration fitted = controller.state.configuration;
      expect(fitted.fitMode, ImageFitMode.fitInside);
      expect(fitted.cropRect, NormalizedCropRect.full);
    },
  );

  test(
    'target size changes recalculate the normalized crop rectangle',
    () async {
      final PrintConfigurationController controller =
          PrintConfigurationController(
            image: _image(),
            imageProcessor: _FakeImageProcessor(
              size: SourceImageSize(widthPixels: 400, heightPixels: 200),
            ),
          );
      await controller.inspectImage();
      final NormalizedCropRect original =
          controller.state.configuration.cropRect;

      controller.changeWidth('90');
      controller.changeHeight('30');

      final NormalizedCropRect changed =
          controller.state.configuration.cropRect;
      expect(changed, isNot(original));
      expect(
        400 * changed.width / (200 * changed.height),
        closeTo(3, 0.000001),
      );
    },
  );

  test('image inspection failure is readable and blocks review', () async {
    final PrintConfigurationController controller =
        PrintConfigurationController(
          image: _image(),
          imageProcessor: _FakeImageProcessor(failInspection: true),
        );

    await controller.inspectImage();

    expect(controller.state.imageError, isNotNull);
    expect(controller.state.isInspectingImage, isFalse);
    expect(controller.state.canReview, isFalse);
  });

  test('a photo that cannot fit reports a layout error', () {
    final PrintConfigurationController controller =
        PrintConfigurationController(
          image: _image(),
          imageProcessor: _FakeImageProcessor(),
        );

    controller.changeWidth('500');

    expect(controller.state.layoutError, isNotNull);
    expect(controller.state.previewPlan, isNull);
    expect(controller.state.canReview, isFalse);
  });
}

SelectedImage _image() {
  return SelectedImage(
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
    displayName: 'synthetic.png',
  );
}

final class _FakeImageProcessor implements ImageProcessor {
  _FakeImageProcessor({SourceImageSize? size, this.failInspection = false})
    : size = size ?? SourceImageSize(widthPixels: 350, heightPixels: 450);

  final bool failInspection;
  final SourceImageSize size;

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async {
    if (failInspection) {
      throw StateError('synthetic inspection failure');
    }
    return size;
  }

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(bytes: request.sourceBytes, size: size);
  }
}
