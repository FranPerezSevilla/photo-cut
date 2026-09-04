import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/units/units.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  test('defaults create a fast valid 35 x 45 mm A4 preview', () {
    final PrintConfigurationController controller =
        PrintConfigurationController(image: _image());
    final PrintConfigurationState state = controller.state;

    expect(state.configuration.photoWidth.inMillimetres, 35);
    expect(state.configuration.photoHeight.inMillimetres, 45);
    expect(state.configuration.paperSize, PaperSize.a4);
    expect(state.configuration.copyCount, 8);
    expect(state.configuration.margin.inMillimetres, 8);
    expect(state.configuration.gap.inMillimetres, 2);
    expect(state.configuration.showCutMarks, isTrue);
    expect(state.previewPlan?.placements.length, 8);
    expect(state.canReview, isTrue);
  });

  test('changing units preserves canonical physical sizes', () {
    final PrintConfigurationController controller =
        PrintConfigurationController(image: _image());
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
        PrintConfigurationController(image: _image());

    controller.changeWidth('0');
    controller.changeHeight('');
    controller.changeCopyCount('1000');

    expect(controller.state.widthError, isNotNull);
    expect(controller.state.heightError, isNotNull);
    expect(controller.state.copyCountError, isNotNull);
    expect(controller.state.canReview, isFalse);
  });

  test('all configurable values update immutable configuration', () {
    final PrintConfigurationController controller =
        PrintConfigurationController(image: _image());
    final PrintJobConfiguration before = controller.state.configuration;

    controller.changeWidth('30,5');
    controller.changeHeight('40');
    controller.changeCopyCount('12');
    controller.changeMargin('6');
    controller.changeGap('3');
    controller.changePaperSize(PaperSize.photo10x15);
    controller.changeCutMarks(false);

    final PrintJobConfiguration after = controller.state.configuration;
    expect(after, isNot(same(before)));
    expect(after.photoWidth.inMillimetres, 30.5);
    expect(after.photoHeight.inMillimetres, 40);
    expect(after.copyCount, 12);
    expect(after.margin.inMillimetres, 6);
    expect(after.gap.inMillimetres, 3);
    expect(after.paperSize, PaperSize.photo10x15);
    expect(after.showCutMarks, isFalse);
    expect(controller.state.canReview, isTrue);
  });

  test('a photo that cannot fit reports a layout error', () {
    final PrintConfigurationController controller =
        PrintConfigurationController(image: _image());

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
