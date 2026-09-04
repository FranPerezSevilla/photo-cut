final class NormalizedPoint {
  factory NormalizedPoint({required double x, required double y}) {
    _validateCoordinate(x, 'x');
    _validateCoordinate(y, 'y');
    return NormalizedPoint._(x: x, y: y);
  }

  const NormalizedPoint._({required this.x, required this.y});

  static const NormalizedPoint center = NormalizedPoint._(x: 0.5, y: 0.5);

  final double x;
  final double y;

  NormalizedPoint copyWith({double? x, double? y}) {
    return NormalizedPoint(x: x ?? this.x, y: y ?? this.y);
  }

  static void _validateCoordinate(double value, String name) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(
        value,
        name,
        'Normalized coordinates must be between 0 and 1',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return other is NormalizedPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
