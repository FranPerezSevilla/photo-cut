import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/app/photo_cut_app.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets('renders the product promise and primary action', (tester) async {
    await tester.pumpWidget(
      PhotoCutApp(imagePickerGateway: _FakeImagePickerGateway()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Photo Cut'), findsOneWidget);
    expect(find.text('Imprime fotos al tamaño exacto'), findsOneWidget);
    expect(find.text('Elegir foto'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.text('Probar PDF de ejemplo'), findsOneWidget);
  });

  testWidgets('primary action selects and previews one local image', (
    tester,
  ) async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
      pickResult: ImageSelectionSuccess(_selectedImage('portrait.png')),
    );
    await tester.pumpWidget(PhotoCutApp(imagePickerGateway: gateway));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choose-photo')));
    await tester.pumpAndSettle();

    expect(gateway.pickCalls, 1);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
    expect(find.text('portrait.png'), findsOneWidget);
    expect(find.text('Elegir otra foto'), findsOneWidget);
  });

  testWidgets('recovers a selection returned after Android restarts the app', (
    tester,
  ) async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
      recoveryResult: ImageSelectionSuccess(_selectedImage('recovered.png')),
    );
    await tester.pumpWidget(PhotoCutApp(imagePickerGateway: gateway));
    await tester.pumpAndSettle();

    expect(gateway.recoveryCalls, 1);
    expect(find.text('recovered.png'), findsOneWidget);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
  });

  testWidgets('cancelling gallery selection is silent', (tester) async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway();
    await tester.pumpWidget(PhotoCutApp(imagePickerGateway: gateway));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choose-photo')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.byKey(const Key('selected-image-preview')), findsNothing);
  });

  testWidgets('development control opens the injected PDF spike', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          imagePickerGateway: _FakeImagePickerGateway(),
          pdfSpikeBuilder: (BuildContext context) {
            return const Scaffold(body: Center(child: Text('PDF spike open')));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder spikeButton = find.text('Probar PDF de ejemplo');
    await tester.ensureVisible(spikeButton);
    await tester.tap(spikeButton);
    await tester.pumpAndSettle();

    expect(find.text('PDF spike open'), findsOneWidget);
  });
}

SelectedImage _selectedImage(String name) {
  return SelectedImage(
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    displayName: name,
  );
}

final class _FakeImagePickerGateway implements ImagePickerGateway {
  _FakeImagePickerGateway({
    this.pickResult = const ImageSelectionCancelled(),
    this.recoveryResult = const ImageSelectionCancelled(),
  });

  final ImageSelectionResult pickResult;
  final ImageSelectionResult recoveryResult;
  int pickCalls = 0;
  int recoveryCalls = 0;

  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    pickCalls += 1;
    return pickResult;
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    recoveryCalls += 1;
    return recoveryResult;
  }
}
