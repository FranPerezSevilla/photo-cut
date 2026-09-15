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
  testWidgets('shows language-neutral branded splash before the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: _FakeImagePickerGateway(),
        imageProcessor: _FakeImageProcessor(),
      ),
    );

    expect(find.byKey(const Key('photo-cut-splash')), findsOneWidget);
    expect(find.byKey(const Key('photo-cut-brand-icon')), findsOneWidget);
    expect(find.byKey(const Key('photo-cut-wordmark')), findsOneWidget);
    expect(find.text('Tamaño exacto. Sin complicaciones.'), findsNothing);

    await _settleSplash(tester);
    expect(find.byKey(const Key('photo-cut-splash')), findsNothing);
    expect(find.text('Print photos at the exact size'), findsOneWidget);
  });

  testWidgets('uses system locale by default and allows a manual override', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: _FakeImagePickerGateway(),
        imageProcessor: _FakeImageProcessor(),
      ),
    );
    await _settleSplash(tester);

    expect(find.text('Imprimez vos photos à la taille exacte'), findsOneWidget);

    await tester.tap(find.byKey(const Key('more-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(find.text('Imprime fotos al tamaño exacto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('more-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sistema'));
    await tester.pumpAndSettle();
    expect(find.text('Imprimez vos photos à la taille exacte'), findsOneWidget);
  });

  testWidgets('renders the product promise and primary action', (tester) async {
    await tester.pumpWidget(
      PhotoCutApp(
        imagePickerGateway: _FakeImagePickerGateway(),
        imageProcessor: _FakeImageProcessor(),
      ),
    );
    await _settleSplash(tester);

    expect(find.byKey(const Key('photo-cut-wordmark')), findsNWidgets(2));
    expect(find.byKey(const Key('photo-cut-brand-icon')), findsNWidgets(2));
    expect(find.text('Print photos at the exact size'), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.text('Try sample PDF'), findsOneWidget);
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
    await _settleSplash(tester);

    final Finder choosePhoto = find.byKey(const Key('choose-photo'));
    await tester.ensureVisible(choosePhoto);
    await tester.tap(choosePhoto);
    await tester.pumpAndSettle();

    expect(gateway.pickCalls, 1);
    expect(find.byKey(const Key('selected-image-preview')), findsOneWidget);
    expect(find.text('portrait.png'), findsOneWidget);
    expect(find.text('400 × 200 px'), findsOneWidget);
    expect(find.text('Choose size and configure'), findsOneWidget);
    expect(find.text('Choose another photo'), findsOneWidget);
  });

  testWidgets('selected image opens the polished four-step wizard', (
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
    await _settleSplash(tester);

    final Finder choosePhoto = find.byKey(const Key('choose-photo'));
    await tester.ensureVisible(choosePhoto);
    await tester.tap(choosePhoto);
    await tester.pumpAndSettle();

    final Finder configure = find.byKey(const Key('configure-photo'));
    await tester.ensureVisible(configure);
    await tester.tap(configure);
    await tester.pumpAndSettle();

    expect(find.text('Prepare photo'), findsOneWidget);
    expect(find.textContaining('Step 1 of 4 · Size'), findsOneWidget);
    expect(find.byKey(const Key('wizard-live-preview')), findsOneWidget);
    expect(find.text('What size do you want to print?'), findsOneWidget);
    expect(find.byKey(const Key('size-preset-35x45')), findsOneWidget);

    await tester.tap(find.byKey(const Key('wizard-next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Step 2 of 4 · Framing'), findsOneWidget);
    expect(find.byKey(const Key('wizard-fit-mode')), findsOneWidget);
    expect(find.byKey(const Key('visual-framing-editor')), findsNothing);
    expect(find.byKey(const Key('open-framing-focus')), findsOneWidget);
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
    await _settleSplash(tester);

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
    await _settleSplash(tester);

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
          localeOverride: null,
          onLocaleChanged: (_) {},
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

Future<void> _settleSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 850));
  await tester.pumpAndSettle();
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
