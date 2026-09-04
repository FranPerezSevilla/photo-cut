import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  const DartImageProcessor processor = DartImageProcessor();

  test('rotates processed bytes when the sheet rotates each photo', () async {
    final img.Image source = img.Image(width: 40, height: 20);
    source.clear(img.ColorRgb8(20, 80, 180));

    final ProcessedImage result = await processor.process(
      ImageProcessingRequest(
        sourceBytes: img.encodePng(source),
        fitMode: ImageFitMode.fitInside,
        colorMode: ImageColorMode.color,
        cropRect: NormalizedCropRect.full,
        quarterTurns: 1,
      ),
    );

    expect(result.size.widthPixels, 20);
    expect(result.size.heightPixels, 40);
  });

  test('rejects unsupported rotation counts', () {
    expect(
      () => ImageProcessingRequest(
        sourceBytes: Uint8List.fromList(<int>[1]),
        fitMode: ImageFitMode.fitInside,
        colorMode: ImageColorMode.color,
        cropRect: NormalizedCropRect.full,
        quarterTurns: 4,
      ),
      throwsArgumentError,
    );
  });
}
