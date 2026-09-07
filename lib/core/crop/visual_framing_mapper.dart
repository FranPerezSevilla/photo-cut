import 'package:photo_cut/core/crop/normalized_point.dart';
import 'package:photo_cut/core/crop/source_image_size.dart';

enum VisualFramingAxis { none, horizontal, vertical }

/// Maps a direct image drag into the same normalized focus state used by the
/// crop planner. Positive drag means the image itself moves in that direction.
final class VisualFramingMapper {
  const VisualFramingMapper();

  VisualFramingAxis axisFor({
    required SourceImageSize sourceSize,
    required double targetAspectRatio,
  }) {
    _validatePositiveFinite(targetAspectRatio, 'targetAspectRatio');
    final double difference = sourceSize.aspectRatio - targetAspectRatio;
    if (difference.abs() <= 0.000000001) {
      return VisualFramingAxis.none;
    }
    return difference > 0
        ? VisualFramingAxis.horizontal
        : VisualFramingAxis.vertical;
  }

  NormalizedPoint applyDrag({
    required SourceImageSize sourceSize,
    required double targetAspectRatio,
    required double frameWidth,
    required double frameHeight,
    required NormalizedPoint currentFocus,
    required double dragDeltaX,
    required double dragDeltaY,
  }) {
    _validatePositiveFinite(targetAspectRatio, 'targetAspectRatio');
    _validatePositiveFinite(frameWidth, 'frameWidth');
    _validatePositiveFinite(frameHeight, 'frameHeight');
    _validateFinite(dragDeltaX, 'dragDeltaX');
    _validateFinite(dragDeltaY, 'dragDeltaY');

    final double sourceAspectRatio = sourceSize.aspectRatio;
    final VisualFramingAxis axis = axisFor(
      sourceSize: sourceSize,
      targetAspectRatio: targetAspectRatio,
    );

    switch (axis) {
      case VisualFramingAxis.none:
        return currentFocus;
      case VisualFramingAxis.horizontal:
        final double overflowPixels =
            frameWidth * (sourceAspectRatio / targetAspectRatio - 1);
        if (overflowPixels <= 0.000000001) {
          return currentFocus;
        }
        final double x = (currentFocus.x - dragDeltaX / overflowPixels)
            .clamp(0.0, 1.0)
            .toDouble();
        return NormalizedPoint(x: x, y: currentFocus.y);
      case VisualFramingAxis.vertical:
        final double overflowPixels =
            frameHeight * (targetAspectRatio / sourceAspectRatio - 1);
        if (overflowPixels <= 0.000000001) {
          return currentFocus;
        }
        final double y = (currentFocus.y - dragDeltaY / overflowPixels)
            .clamp(0.0, 1.0)
            .toDouble();
        return NormalizedPoint(x: currentFocus.x, y: y);
    }
  }

  static void _validatePositiveFinite(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, name, 'Value must be finite and positive');
    }
  }

  static void _validateFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Value must be finite');
    }
  }
}
