import 'dart:typed_data';

/// App-owned boundary for selecting one source image.
abstract interface class ImagePickerGateway {
  Future<ImageSelectionResult> pickFromGallery();

  /// Recovers a selection whose Android activity was destroyed while the
  /// system picker was open. Other platforms may return cancellation.
  Future<ImageSelectionResult> recoverLostSelection();
}

sealed class ImageSelectionResult {
  const ImageSelectionResult();
}

final class ImageSelectionSuccess extends ImageSelectionResult {
  const ImageSelectionSuccess(this.image);

  final SelectedImage image;
}

final class ImageSelectionCancelled extends ImageSelectionResult {
  const ImageSelectionCancelled();
}

final class ImageSelectionFailure extends ImageSelectionResult {
  const ImageSelectionFailure(this.userMessage);

  final String userMessage;
}

/// Private image bytes plus a display-only filename.
///
/// Platform paths are deliberately discarded. Both constructor input and
/// getter output are copied so feature state cannot mutate the stored bytes.
final class SelectedImage {
  SelectedImage({required Uint8List bytes, required String displayName})
    : _bytes = _validatedCopy(bytes),
      displayName = _safeDisplayName(displayName);

  final Uint8List _bytes;
  final String displayName;

  int get byteLength => _bytes.length;

  Uint8List get bytes => Uint8List.fromList(_bytes);

  static Uint8List _validatedCopy(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'Image bytes must not be empty',
      );
    }
    return Uint8List.fromList(bytes);
  }

  static String _safeDisplayName(String value) {
    final String basename = value.replaceAll('\\', '/').split('/').last.trim();
    return basename.isEmpty ? 'foto' : basename;
  }
}
