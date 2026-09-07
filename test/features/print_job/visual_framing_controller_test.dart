import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  test(
    'visual focus reuses crop state and survives fit-mode round trips',
    () async {
      final PrintConfigurationController controller =
          PrintConfigurationController(
            image: SelectedImage(
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              displayName: 'synthetic.jpg',
            ),
            imageProcessor: _FakeImageProcessor(),
          );
      await controller.inspectImage();

      final NormalizedPoint moved = NormalizedPoint(x: 0.18, y: 0.5);
      controller.changeFocus(moved);
      final NormalizedCropRect cropped =
          controller.state.configuration.cropRect;

      expect(controller.state.configuration.focus, moved);
      expect(cropped, isNot(NormalizedCropRect.full));

      controller.changeFitMode(ImageFitMode.fitInside);
      expect(controller.state.configuration.focus, moved);
      expect(controller.state.configuration.cropRect, NormalizedCropRect.full);

      controller.changeFitMode(ImageFitMode.cropToFill);
      expect(controller.state.configuration.focus, moved);
      expect(controller.state.configuration.cropRect, cropped);
    },
  );
}

final class _FakeImageProcessor implements ImageProcessor {
  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async {
    return SourceImageSize(widthPixels: 400, heightPixels: 200);
  }

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(
      bytes: request.sourceBytes,
      size: SourceImageSize(widthPixels: 400, heightPixels: 200),
    );
  }
}
