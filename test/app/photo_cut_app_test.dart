import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/app/photo_cut_app.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  testWidgets('renders the product promise and primary action', (tester) async {
    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: _FakeImagePickerGateway(),
        imageProcessor: _FakeImageProcessor(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Photo Cut'), findsOneWidget);
    expect(find.text('Imprime fotos al tamaño exacto'), findsOneWidget);
    expect(find.text('Elegir foto'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.text('Probar PDF de ejemplo'), findsOneWidget);
  });

  testWidgets('primary action selects and previews one local image', (
    WidgetTester tester,
  ) async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
      pickResult: ImageSelectionSuccess(_selectedImage('portrait.png')),
    );
    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: gateway,
        imageProcessor: _FakeImageProcessor(),
      ),
    );
    await tester.pumpAndSettle();

    final Finder choosePhoto = find.byKey(const Key('choose-photo'));
    await tester.ensureVisible(choosePhoto);
    await tester.tap(choosePhoto);
    await tester.pumpAndSettle();

    expect(gateway.pickCalls, 1);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
    expect(find.text('portrait.png'), findsOneWidget);
    expect(find.text('Configurar impresión'), findsOneWidget);
    expect(find.text('Elegir otra foto'), findsOneWidget);
  });

  testWidgets('selected image opens the Photo Cut configuration step', (
    WidgetTester tester,
  ) async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
      pickResult: ImageSelectionSuccess(_selectedImage('portrait.png')),
    );
    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: gateway,
        imageProcessor: _FakeImageProcessor(),
      ),
    );
    await tester.pumpAndSettle();

    final Finder choosePhoto = find.byKey(const Key('choose-photo'));
    await tester.ensureVisible(choosePhoto);
    await tester.tap(choosePhoto);
    await tester.pumpAndSettle();

    final Finder configure = find.byKey(const Key('configure-photo'));
    await tester.ensureVisible(configure);
    await tester.tap(configure);
    await tester.pumpAndSettle();

    expect(find.text('Preparar en Photo Cut'), findsOneWidget);
    expect(find.text('Paso 1 de 2 · Configura el documento'), findsOneWidget);

    final Finder fitSelector = find.byKey(const Key('fit-mode-selector'));
    await tester.scrollUntilVisible(
      fitSelector,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(fitSelector, findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Blanco y negro'), findsOneWidget);
  });

  testWidgets('recovers a selection returned after Android restarts the app', (
    WidgetTester tester,
  ) async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway(
      recoveryResult: ImageSelectionSuccess(_selectedImage('recovered.png')),
    );
    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: gateway,
        imageProcessor: _FakeImageProcessor(),
      ),
    );
    await tester.pumpAndSettle();

    expect(gateway.recoveryCalls, 1);
    expect(find.text('recovered.png'), findsOneWidget);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
  });

  testWidgets('cancelling gallery selection is silent', (
    WidgetTester tester,
  ) async {
    final _FakeImagePickerGateway gateway = _FakeImagePickerGateway();
    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: gateway,
        imageProcessor: _FakeImageProcessor(),
      ),
    );
    await tester.pumpAndSettle();

    final Finder choosePhoto = find.byKey(const Key('choose-photo'));
    await tester.ensureVisible(choosePhoto);
    await tester.tap(choosePhoto);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.byKey(const Key('selected-image-preview')), findsNothing);
  });

  testWidgets('development control opens the injected PDF spike', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          imagePickerGateway: _FakeImagePickerGateway(),
          imageProcessor: _FakeImageProcessor(),
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
      'iVBORw0KGgoAAAANSUhEUgAAACMAAAAtCAIAAACrsUV+AAAARElEQVR42u3V'
      'sREAEBREwc+oQyXKEQkUqAwVaUFCtK+Bnbnk0m4tvpTjVyQSiUR6VRm9Wo9E'
      'IpFIl68Ra1qPRCKRSHcdIZ4DvGdT4rYAAAAASUVORK5CYII=',
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

final class _FakeImageProcessor implements ImageProcessor {
  _FakeImageProcessor()
    : size = SourceImageSize(widthPixels: 400, heightPixels: 200);

  final SourceImageSize size;

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async => size;

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(bytes: request.sourceBytes, size: size);
  }
}
