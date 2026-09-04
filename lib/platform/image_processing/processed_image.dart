import 'dart:typed_data';

import 'package:photo_cut/core/crop/source_image_size.dart';

final class ProcessedImage {
  ProcessedImage({
    required Uint8List bytes,
    required this.size,
  }) : _bytes = _validatedCopy(bytes);

  final Uint8List _bytes;
  final SourceImageSize size;

  Uint8List get bytes => Uint8List.fromList(_bytes);

  static Uint8List _validatedCopy(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'Processed image bytes must not be empty',
      );
    }
    return Uint8List.fromList(bytes);
  }
}
