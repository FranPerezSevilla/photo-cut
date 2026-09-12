import 'package:photo_cut/core/crop/normalized_crop_rect.dart';
import 'package:photo_cut/core/crop/normalized_point.dart';
import 'package:photo_cut/core/crop/source_image_size.dart';

/// Calculates a deterministic source rectangle for crop-to-fill.
final class CropPlanner {
  const CropPlanner();

  static const double minimumZoom = 1;
  static const double maximumZoom = 4;

  NormalizedCropRect plan({
    required SourceImageSize sourceSize,
    required double targetAspectRatio,
    required NormalizedPoint focus,
    double zoom = minimumZoom,
  }) {
    if (!targetAspectRatio.isFinite || targetAspectRatio <= 0) {
      throw ArgumentError.value(
        targetAspectRatio,
        'targetAspectRatio',
        'Target aspect ratio must be finite and greater than zero',
      );
    }
    if (!zoom.isFinite || zoom < minimumZoom || zoom > maximumZoom) {
      throw ArgumentError.value(
        zoom,
        'zoom',
        'Zoom must be between $minimumZoom and $maximumZoom',
      );
    }

    final double sourceAspectRatio = sourceSize.aspectRatio;
    double width = 1;
    double height = 1;

    if (sourceAspectRatio > targetAspectRatio) {
      width = targetAspectRatio / sourceAspectRatio;
    } else if (sourceAspectRatio < targetAspectRatio) {
      height = sourceAspectRatio / targetAspectRatio;
    }

    width /= zoom;
    height /= zoom;

    final double maximumLeft = 1 - width;
    final double maximumTop = 1 - height;
    final double left = (maximumLeft * focus.x)
        .clamp(0.0, maximumLeft)
        .toDouble();
    final double top = (maximumTop * focus.y)
        .clamp(0.0, maximumTop)
        .toDouble();

    return NormalizedCropRect(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }
}
