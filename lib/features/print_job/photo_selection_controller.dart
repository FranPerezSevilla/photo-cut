import 'package:flutter/foundation.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

@immutable
final class PhotoSelectionState {
  const PhotoSelectionState({
    this.image,
    this.isBusy = false,
    this.errorMessage,
  });

  final SelectedImage? image;
  final bool isBusy;
  final String? errorMessage;
}

/// Short-lived controller for the first step of a print job.
final class PhotoSelectionController extends ChangeNotifier {
  PhotoSelectionController({required ImagePickerGateway imagePickerGateway})
    : _imagePickerGateway = imagePickerGateway;

  final ImagePickerGateway _imagePickerGateway;
  PhotoSelectionState _state = const PhotoSelectionState();
  bool _recoveryAttempted = false;

  PhotoSelectionState get state => _state;

  Future<void> recoverLostSelection() async {
    if (_recoveryAttempted) {
      return;
    }
    _recoveryAttempted = true;
    await _run(_imagePickerGateway.recoverLostSelection);
  }

  Future<void> selectFromGallery() {
    return _run(_imagePickerGateway.pickFromGallery);
  }

  Future<void> _run(Future<ImageSelectionResult> Function() operation) async {
    if (_state.isBusy) {
      return;
    }

    _setState(
      PhotoSelectionState(image: _state.image, isBusy: true),
    );

    try {
      final ImageSelectionResult result = await operation();
      switch (result) {
        case ImageSelectionSuccess():
          _setState(PhotoSelectionState(image: result.image));
        case ImageSelectionCancelled():
          _setState(PhotoSelectionState(image: _state.image));
        case ImageSelectionFailure():
          _setState(
            PhotoSelectionState(
              image: _state.image,
              errorMessage: result.userMessage,
            ),
          );
      }
    } on Object {
      _setState(
        PhotoSelectionState(
          image: _state.image,
          errorMessage: 'No se pudo seleccionar la foto. Inténtalo de nuevo.',
        ),
      );
    }
  }

  void clearError() {
    if (_state.errorMessage == null) {
      return;
    }
    _setState(PhotoSelectionState(image: _state.image));
  }

  void _setState(PhotoSelectionState value) {
    _state = value;
    notifyListeners();
  }
}
