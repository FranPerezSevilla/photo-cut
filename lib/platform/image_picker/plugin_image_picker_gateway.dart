import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_picker/image_picker_gateway.dart';

/// `image_picker` implementation that immediately copies bytes into app-owned
/// memory and never retains or exposes the provider's local path.
final class PluginImagePickerGateway implements ImagePickerGateway {
  PluginImagePickerGateway({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (file == null) {
        return const ImageSelectionCancelled();
      }
      return await _read(file);
    } on PlatformException {
      return const ImageSelectionFailure(
        'No se pudo abrir la galería. Inténtalo de nuevo.',
      );
    } on Object {
      return const ImageSelectionFailure(
        'No se pudo seleccionar la foto. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return const ImageSelectionCancelled();
      }
      if (response.exception != null) {
        return const ImageSelectionFailure(
          'No se pudo recuperar la foto seleccionada.',
        );
      }

      final List<XFile>? files = response.files;
      final XFile? file = files != null && files.isNotEmpty
          ? files.first
          : response.file;
      if (file == null) {
        return const ImageSelectionCancelled();
      }
      return await _read(file);
    } on PlatformException {
      return const ImageSelectionFailure(
        'No se pudo recuperar la foto seleccionada.',
      );
    } on Object {
      return const ImageSelectionFailure(
        'No se pudo recuperar la foto seleccionada.',
      );
    }
  }

  Future<ImageSelectionResult> _read(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return ImageSelectionSuccess(
        SelectedImage(bytes: bytes, displayName: file.name),
      );
    } on Object {
      return const ImageSelectionFailure(
        'No se pudo leer la foto seleccionada.',
      );
    }
  }
}
