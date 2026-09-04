final class SourceImageSize {
  SourceImageSize({required this.widthPixels, required this.heightPixels}) {
    if (widthPixels <= 0) {
      throw ArgumentError.value(
        widthPixels,
        'widthPixels',
        'Image width must be greater than zero',
      );
    }
    if (heightPixels <= 0) {
      throw ArgumentError.value(
        heightPixels,
        'heightPixels',
        'Image height must be greater than zero',
      );
    }
  }

  final int heightPixels;
  final int widthPixels;

  double get aspectRatio => widthPixels / heightPixels;

  @override
  bool operator ==(Object other) {
    return other is SourceImageSize &&
        other.widthPixels == widthPixels &&
        other.heightPixels == heightPixels;
  }

  @override
  int get hashCode => Object.hash(widthPixels, heightPixels);
}
