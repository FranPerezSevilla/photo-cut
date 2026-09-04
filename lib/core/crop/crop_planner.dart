import 'package:photo_cut/core/crop/normalized_crop_rect.dart';
import 'package:photo_cut/core/crop/normalized_point.dart';
import 'package:photo_cut/core/crop/source_image_size.dart';

/// Calculates a deterministic source rectangle for crop-to-fill.
final class CropPlanner {
  const CropPlanner();

  NormalizedCropRect plan({
    required SourceImageSize sourceSize,
    required double targetAspectRatio,
    required NormalizedPoint focus,
  }) {
    if (!targetAspectRatio.isFinite || targetAspectRatio <= 0) {
      throw ArgumentError.value(
        targetAspectRatio,
        'targetAspectRatio',
        'Target aspect ratio must be finite and greater than zero',
      );
    }

    final double sourceAspectRatio = sourceSize.aspectRatio;
    if ((sourceAspectRatio - targetAspectRatio).abs() < 0.000000001) {
      return NormalizedCropRect.full;
    }

    if (sourceAspectRatio > targetAspectRatio) {
      final double width = targetAspectRatio / sourceAspectRatio;
      final double maximumLeft = 1 - width;
      final double left = (maximumLeft * focus.x)
          .clamp(0.0, maximumLeft)
          .toDouble();
      return NormalizedCropRect(left: left, top: 0, width: width, height: 1);
    }

    final double height = sourceAspectRatio / targetAspectRatio;
    final double maximumTop = 1 - height;
    final double top = (maximumTop * focus.y).clamp(0.0, maximumTop).toDouble();
    return NormalizedCropRect(left: 0, top: top, width: 1, height: height);
  }
}
