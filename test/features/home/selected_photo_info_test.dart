import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/home/selected_photo_info.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  testWidgets('shows pixels and print-size guidance without claiming one real size', (
    WidgetTester tester,
  ) async {
    final SelectedImage image = SelectedImage(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      displayName: 'foto.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectedPhotoInfo(
            image: image,
            imageProcessor: const _FakeImageProcessor(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4000 × 3000 px'), findsOneWidget);
    expect(find.textContaining('A 300 ppp'), findsOneWidget);
    expect(find.textContaining('33.9 × 25.4 cm'), findsOneWidget);
    expect(find.textContaining('A 600 ppp'), findsOneWidget);
    expect(find.textContaining('no tiene una medida física única'), findsOneWidget);
  });
}

final class _FakeImageProcessor implements ImageProcessor {
  const _FakeImageProcessor();

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async {
    return SourceImageSize(widthPixels: 4000, heightPixels: 3000);
  }

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) {
    throw UnimplementedError();
  }
}
