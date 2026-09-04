import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  const DartImageProcessor processor = DartImageProcessor();

  test(
    'inspection bakes EXIF orientation before reporting dimensions',
    () async {
      final Uint8List bytes = base64Decode(
        File('test_resources/exif-orientation-6.jpg.base64')
            .readAsStringSync()
            .trim(),
      );

      final SourceImageSize size = await processor.inspect(bytes);

      expect(size.widthPixels, 2);
      expect(size.heightPixels, 3);
    },
  );

  test('crop-to-fill produces the planned target aspect ratio', () async {
    final Uint8List source = _solidPng(
      width: 400,
      height: 200,
      red: 220,
      green: 40,
      blue: 20,
    );
    final NormalizedCropRect crop = const CropPlanner().plan(
      sourceSize: SourceImageSize(widthPixels: 400, heightPixels: 200),
      targetAspectRatio: 1,
      focus: NormalizedPoint.center,
    );

    final ProcessedImage result = await processor.process(
      ImageProcessingRequest(
        sourceBytes: source,
        fitMode: ImageFitMode.cropToFill,
        colorMode: ImageColorMode.color,
        cropRect: crop,
      ),
    );

    expect(result.size.widthPixels, 200);
    expect(result.size.heightPixels, 200);
    expect(result.size.aspectRatio, closeTo(1, 0.000001));
  });

  test(
    'fit-inside preserves the oriented source aspect without distortion',
    () async {
      final Uint8List source = _solidPng(
        width: 400,
        height: 200,
        red: 30,
        green: 120,
        blue: 220,
      );

      final ProcessedImage result = await processor.process(
        ImageProcessingRequest(
          sourceBytes: source,
          fitMode: ImageFitMode.fitInside,
          colorMode: ImageColorMode.color,
          cropRect: NormalizedCropRect.full,
        ),
      );

      expect(result.size.widthPixels, 400);
      expect(result.size.heightPixels, 200);
      expect(result.size.aspectRatio, 2);
    },
  );

  test(
    'grayscale is applied to exported image bytes inside Photo Cut',
    () async {
      final Uint8List source = _solidPng(
        width: 20,
        height: 20,
        red: 240,
        green: 40,
        blue: 10,
      );

      final ProcessedImage result = await processor.process(
        ImageProcessingRequest(
          sourceBytes: source,
          fitMode: ImageFitMode.fitInside,
          colorMode: ImageColorMode.grayscale,
          cropRect: NormalizedCropRect.full,
        ),
      );
      final img.Image? decoded = img.decodeImage(result.bytes);
      expect(decoded, isNotNull);
      final img.Pixel pixel = decoded!.getPixel(10, 10);

      expect((pixel.r - pixel.g).abs(), lessThanOrEqualTo(2));
      expect((pixel.g - pixel.b).abs(), lessThanOrEqualTo(2));
    },
  );

  test('invalid source bytes fail without producing output', () async {
    await expectLater(
      processor.inspect(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(isA<StateError>()),
    );
  });
}

Uint8List _solidPng({
  required int width,
  required int height,
  required int red,
  required int green,
  required int blue,
}) {
  final img.Image image = img.Image(width: width, height: height);
  image.clear(img.ColorRgb8(red, green, blue));
  return img.encodePng(image);
}
