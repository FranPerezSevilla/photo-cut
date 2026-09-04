import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  test('SelectedImage owns its bytes and discards path components', () {
    final Uint8List source = Uint8List.fromList(<int>[1, 2, 3]);
    final SelectedImage image = SelectedImage(
      bytes: source,
      displayName: r'C:\private\camera\portrait.png',
    );

    source[0] = 9;
    final Uint8List firstRead = image.bytes;
    firstRead[1] = 9;

    expect(image.displayName, 'portrait.png');
    expect(image.byteLength, 3);
    expect(image.bytes, <int>[1, 2, 3]);
  });

  test('SelectedImage rejects empty input and uses a safe fallback name', () {
    expect(
      () => SelectedImage(bytes: Uint8List(0), displayName: 'empty.png'),
      throwsArgumentError,
    );

    final SelectedImage image = SelectedImage(
      bytes: Uint8List.fromList(<int>[1]),
      displayName: '  ',
    );
    expect(image.displayName, 'foto');
  });
}
