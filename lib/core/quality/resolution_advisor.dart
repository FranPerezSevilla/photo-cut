import 'dart:math' as math;

import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/units/units.dart';

enum ResolutionQuality {
  high,
  good,
  caution,
  low,
}

final class ResolutionAdvice {
  const ResolutionAdvice({
    required this.effectiveDpi,
    required this.horizontalDpi,
    required this.verticalDpi,
    required this.quality,
  });

  final double effectiveDpi;
  final double horizontalDpi;
  final ResolutionQuality quality;
  final double verticalDpi;

  bool get shouldWarn =>
      quality == ResolutionQuality.caution || quality == ResolutionQuality.low;
}

/// Estimates the pixel density of the image content that will actually be
/// printed inside one Photo Cut output rectangle.
///
/// Thresholds are product guidance rather than printer guarantees:
/// - 300 DPI or more: high reference quality.
/// - 200–299 DPI: good for the MVP without a warning.
/// - 150–199 DPI: caution.
/// - below 150 DPI: low-resolution warning.
final class ResolutionAdvisor {
  const ResolutionAdvisor();

  static const double highDpiThreshold = 300;
  static const double warningDpiThreshold = 200;
  static const double lowDpiThreshold = 150;

  ResolutionAdvice evaluate({
    required SourceImageSize sourceSize,
    required NormalizedCropRect cropRect,
    required ImageFitMode fitMode,
    required PhysicalLength outputWidth,
    required PhysicalLength outputHeight,
  }) {
    final double sourceWidthPixels = fitMode == ImageFitMode.cropToFill
        ? math.max(1, sourceSize.widthPixels * cropRect.width)
        : sourceSize.widthPixels.toDouble();
    final double sourceHeightPixels = fitMode == ImageFitMode.cropToFill
        ? math.max(1, sourceSize.heightPixels * cropRect.height)
        : sourceSize.heightPixels.toDouble();

    final _PhysicalImageSize physicalImageSize = _physicalImageSize(
      sourceWidthPixels: sourceWidthPixels,
      sourceHeightPixels: sourceHeightPixels,
      fitMode: fitMode,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
    );

    final double horizontalDpi =
        sourceWidthPixels / physicalImageSize.widthInches;
    final double verticalDpi =
        sourceHeightPixels / physicalImageSize.heightInches;
    final double effectiveDpi = math.min(horizontalDpi, verticalDpi);

    return ResolutionAdvice(
      effectiveDpi: effectiveDpi,
      horizontalDpi: horizontalDpi,
      verticalDpi: verticalDpi,
      quality: _qualityFor(effectiveDpi),
    );
  }

  static ResolutionQuality _qualityFor(double dpi) {
    if (dpi >= highDpiThreshold) {
      return ResolutionQuality.high;
    }
    if (dpi >= warningDpiThreshold) {
      return ResolutionQuality.good;
    }
    if (dpi >= lowDpiThreshold) {
      return ResolutionQuality.caution;
    }
    return ResolutionQuality.low;
  }

  static _PhysicalImageSize _physicalImageSize({
    required double sourceWidthPixels,
    required double sourceHeightPixels,
    required ImageFitMode fitMode,
    required PhysicalLength outputWidth,
    required PhysicalLength outputHeight,
  }) {
    if (fitMode == ImageFitMode.cropToFill) {
      return _PhysicalImageSize(
        widthInches: outputWidth.inInches,
        heightInches: outputHeight.inInches,
      );
    }

    final double sourceAspect = sourceWidthPixels / sourceHeightPixels;
    final double outputAspect = outputWidth.inInches / outputHeight.inInches;

    if (sourceAspect >= outputAspect) {
      final double widthInches = outputWidth.inInches;
      return _PhysicalImageSize(
        widthInches: widthInches,
        heightInches: widthInches / sourceAspect,
      );
    }

    final double heightInches = outputHeight.inInches;
    return _PhysicalImageSize(
      widthInches: heightInches * sourceAspect,
      heightInches: heightInches,
    );
  }
}

final class _PhysicalImageSize {
  const _PhysicalImageSize({
    required this.widthInches,
    required this.heightInches,
  });

  final double heightInches;
  final double widthInches;
}
