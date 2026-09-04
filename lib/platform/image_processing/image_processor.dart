import 'dart:typed_data';

import 'package:photo_cut/core/crop/source_image_size.dart';
import 'package:photo_cut/platform/image_processing/image_processing_request.dart';
import 'package:photo_cut/platform/image_processing/processed_image.dart';

abstract interface class ImageProcessor {
  /// Returns dimensions after physically applying any EXIF orientation.
  Future<SourceImageSize> inspect(Uint8List bytes);

  /// Bakes orientation, applies crop/colour choices and returns encoded bytes.
  Future<ProcessedImage> process(ImageProcessingRequest request);
}
