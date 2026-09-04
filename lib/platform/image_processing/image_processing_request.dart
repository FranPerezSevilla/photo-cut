import 'dart:typed_data';

import 'package:photo_cut/core/crop/crop.dart';

/// Fully resolved source-image transformation requested by Photo Cut.
final class ImageProcessingRequest {
  ImageProcessingRequest({
    required Uint8List sourceBytes,
    required this.fitMode,
    required this.colorMode,
    required this.cropRect,
  }) : _sourceBytes = _validatedCopy(sourceBytes);

  final ImageColorMode colorMode;
  final NormalizedCropRect cropRect;
  final ImageFitMode fitMode;
  final Uint8List _sourceBytes;

  Uint8List get sourceBytes => Uint8List.fromList(_sourceBytes);

  static Uint8List _validatedCopy(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(
        bytes,
        'sourceBytes',
        'Source image bytes must not be empty',
      );
    }
    return Uint8List.fromList(bytes);
  }
}
