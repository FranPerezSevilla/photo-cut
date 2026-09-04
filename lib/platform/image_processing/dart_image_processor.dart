import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/platform/image_processing/image_processing_request.dart';
import 'package:photo_cut/platform/image_processing/image_processor.dart';
import 'package:photo_cut/platform/image_processing/processed_image.dart';

/// Offline image processing backed by the pure-Dart `image` package.
final class DartImageProcessor implements ImageProcessor {
  const DartImageProcessor();

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) {
    final Uint8List ownedBytes = Uint8List.fromList(bytes);
    return Isolate.run<SourceImageSize>(() => _inspectBytes(ownedBytes));
  }

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) {
    final Uint8List ownedBytes = request.sourceBytes;
    final ImageFitMode fitMode = request.fitMode;
    final ImageColorMode colorMode = request.colorMode;
    final NormalizedCropRect cropRect = request.cropRect;

    return Isolate.run<ProcessedImage>(() {
      return _processBytes(
        sourceBytes: ownedBytes,
        fitMode: fitMode,
        colorMode: colorMode,
        cropRect: cropRect,
      );
    });
  }
}

SourceImageSize _inspectBytes(Uint8List bytes) {
  final img.Image image = _decodeAndOrient(bytes);
  return SourceImageSize(
    widthPixels: image.width,
    heightPixels: image.height,
  );
}

ProcessedImage _processBytes({
  required Uint8List sourceBytes,
  required ImageFitMode fitMode,
  required ImageColorMode colorMode,
  required NormalizedCropRect cropRect,
}) {
  img.Image prepared = _decodeAndOrient(sourceBytes);

  if (fitMode == ImageFitMode.cropToFill) {
    final _PixelCrop crop = _toPixelCrop(cropRect, prepared);
    prepared = img.copyCrop(
      prepared,
      x: crop.x,
      y: crop.y,
      width: crop.width,
      height: crop.height,
    );
  }

  final img.Image flattened = img.Image(
    width: prepared.width,
    height: prepared.height,
    numChannels: 3,
  );
  flattened.clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(flattened, prepared);

  if (colorMode == ImageColorMode.grayscale) {
    img.grayscale(flattened);
  }

  final Uint8List encoded = img.encodeJpg(flattened, quality: 94);
  return ProcessedImage(
    bytes: encoded,
    size: SourceImageSize(
      widthPixels: flattened.width,
      heightPixels: flattened.height,
    ),
  );
}

img.Image _decodeAndOrient(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Unsupported or invalid image data');
  }
  return img.bakeOrientation(decoded);
}

_PixelCrop _toPixelCrop(
  NormalizedCropRect normalized,
  img.Image source,
) {
  final int x = (normalized.left * source.width)
      .floor()
      .clamp(0, source.width - 1)
      .toInt();
  final int y = (normalized.top * source.height)
      .floor()
      .clamp(0, source.height - 1)
      .toInt();

  final int requestedRight = (normalized.right * source.width).round();
  final int requestedBottom = (normalized.bottom * source.height).round();
  final int right = requestedRight.clamp(x + 1, source.width).toInt();
  final int bottom = requestedBottom.clamp(y + 1, source.height).toInt();

  return _PixelCrop(
    x: x,
    y: y,
    width: right - x,
    height: bottom - y,
  );
}

final class _PixelCrop {
  const _PixelCrop({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int height;
  final int width;
  final int x;
  final int y;
}
