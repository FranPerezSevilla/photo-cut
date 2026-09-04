import 'dart:typed_data';

import 'package:photo_cut/core/crop/crop.dart';

/// Fully resolved source-image transformation requested by Photo Cut.
final class ImageProcessingRequest {
  ImageProcessingRequest({
    required Uint8List sourceBytes,
    required this.fitMode,
    required this.colorMode,
    required this.cropRect,
    this.quarterTurns = 0,
  }) : _sourceBytes = _validatedCopy(sourceBytes) {
    if (quarterTurns < 0 || quarterTurns > 3) {
      throw ArgumentError.value(
        quarterTurns,
        'quarterTurns',
        'Quarter turns must be between 0 and 3',
      );
    }
  }

  final ImageColorMode colorMode;
  final NormalizedCropRect cropRect;
  final ImageFitMode fitMode;
  final int quarterTurns;
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
