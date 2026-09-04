final class NormalizedCropRect {
  factory NormalizedCropRect({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    for (final MapEntry<String, double> value in <String, double>{
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    }.entries) {
      if (!value.value.isFinite) {
        throw ArgumentError.value(
          value.value,
          value.key,
          'Crop values must be finite',
        );
      }
    }
    if (left < 0 || top < 0 || width <= 0 || height <= 0) {
      throw ArgumentError(
        'Crop origin must be non-negative and dimensions must be positive',
      );
    }
    const double tolerance = 0.000000001;
    if (left + width > 1 + tolerance || top + height > 1 + tolerance) {
      throw ArgumentError('Crop rectangle must stay inside the source image');
    }
    return NormalizedCropRect._(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }

  const NormalizedCropRect._({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  static const NormalizedCropRect full = NormalizedCropRect._(
    left: 0,
    top: 0,
    width: 1,
    height: 1,
  );

  final double height;
  final double left;
  final double top;
  final double width;

  double get bottom => top + height;
  double get right => left + width;

  @override
  bool operator ==(Object other) {
    return other is NormalizedCropRect &&
        other.left == left &&
        other.top == top &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);
}
