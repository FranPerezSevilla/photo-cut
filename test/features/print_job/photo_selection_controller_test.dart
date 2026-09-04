import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  test('recovers Android lost data once at startup', () async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
      recoveryResult: ImageSelectionSuccess(_image('recovered.png')),
    );
    final PhotoSelectionController controller = PhotoSelectionController(
      gateway: gateway,
    );

    await controller.recoverLostSelection();
    await controller.recoverLostSelection();

    expect(gateway.recoveryCalls, 1);
    expect(controller.state.image?.displayName, 'recovered.png');
    expect(controller.state.errorMessage, isNull);
  });

  test(
    'cancellation is not treated as an error and keeps prior image',
    () async {
      final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
        pickResults: <ImageSelectionResult>[
          ImageSelectionSuccess(_image('first.png')),
          const ImageSelectionCancelled(),
        ],
      );
      final PhotoSelectionController controller = PhotoSelectionController(
        gateway: gateway,
      );

      await controller.selectFromGallery();
      await controller.selectFromGallery();

      expect(controller.state.image?.displayName, 'first.png');
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.isBusy, isFalse);
    },
  );

  test('a readable failure keeps the previously selected image', () async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
      pickResults: <ImageSelectionResult>[
        ImageSelectionSuccess(_image('first.png')),
        const ImageSelectionFailure('No se pudo leer la foto seleccionada.'),
      ],
    );
    final PhotoSelectionController controller = PhotoSelectionController(
      gateway: gateway,
    );

    await controller.selectFromGallery();
    await controller.selectFromGallery();

    expect(controller.state.image?.displayName, 'first.png');
    expect(
      controller.state.errorMessage,
      'No se pudo leer la foto seleccionada.',
    );
  });
}

SelectedImage _image(String name) {
  return SelectedImage(
    bytes: Uint8List.fromList(<int>[1, 2, 3]),
    displayName: name,
  );
}

final class _FakeImagePickerGateway implements ImagePickerGateway {
  _FakeImagePickerGateway({
    this.recoveryResult = const ImageSelectionCancelled(),
    List<ImageSelectionResult>? pickResults,
  }) : _pickResults = pickResults ?? <ImageSelectionResult>[];

  final ImageSelectionResult recoveryResult;
  final List<ImageSelectionResult> _pickResults;
  int recoveryCalls = 0;
  int pickCalls = 0;

  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    final ImageSelectionResult result = _pickResults[pickCalls];
    pickCalls += 1;
    return result;
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    recoveryCalls += 1;
    return recoveryResult;
  }
}
