import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/features/print_job/guided_print_wizard.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 home with a selected photo', (WidgetTester tester) async {
    final _Fixture fixture = await _fixture();

    await _pump(
      tester,
      HomeScreen(
        imagePickerGateway: _StoreImagePicker(fixture.image),
        imageProcessor: fixture.processor,
        localeOverride: const Locale('en'),
        onLocaleChanged: (_) {},
      ),
    );
    await tester.tap(find.byKey(const Key('choose-photo')));
    await _pumpUi(tester);

    expect(find.text('Print photos at the exact size'), findsOneWidget);
    await _capture(binding, tester, '01-home-selected');
  });

  testWidgets('02 real size step with 10 x 15 preset', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 1 of 4'), findsOneWidget);
    expect(find.text('10 × 15 cm'), findsOneWidget);
    await _capture(binding, tester, '02-size-10x15');
  });

  testWidgets('03 real focused framing editor', (WidgetTester tester) async {
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('size-preset-10x15')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('open-framing-focus')));
    await _pumpUi(tester);

    expect(find.byKey(const Key('framing-focus-screen')), findsOneWidget);
    expect(find.text('Adjust framing'), findsOneWidget);
    await _capture(binding, tester, '03-framing-focus');
  });

  testWidgets('04 real A4 sheet step', (WidgetTester tester) async {
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 3 of 4'), findsOneWidget);
    expect(find.text('A4'), findsOneWidget);
    await _capture(binding, tester, '04-sheet-a4');
  });

  testWidgets('05 real 10 x 15 photo-paper sheet', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await _configureTenByFifteen(tester);

    expect(find.text('Photo 10 × 15 cm'), findsOneWidget);
    await _capture(binding, tester, '05-sheet-10x15');
  });

  testWidgets('06 real wizard review step', (WidgetTester tester) async {
    final _Fixture fixture = await _fixture();
    await _pump(
      tester,
      GuidedPrintWizard(
        image: fixture.image,
        imageProcessor: fixture.processor,
      ),
    );

    await _configureTenByFifteen(tester);
    await tester.tap(find.byKey(const Key('wizard-next')));
    await _pumpUi(tester);

    expect(find.textContaining('Step 4 of 4'), findsOneWidget);
    expect(find.textContaining('100 × 150 mm'), findsWidgets);
    await _capture(binding, tester, '06-review');
  });
}

Future<_Fixture> _fixture() async {
  final Uint8List photoBytes = await _buildDemoPhoto();
  final SelectedImage image = SelectedImage(
    bytes: photoBytes,
    displayName: 'mountain-lake.png',
  );
  return _Fixture(
    image: image,
    processor: _StoreImageProcessor(photoBytes: photoBytes),
  );
}

Future<Uint8List> _buildDemoPhoto() async {
  const int width = 1200;
  const int height = 800;
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  final ui.Rect bounds = ui.Rect.fromLTWH(
    0,
    0,
    width.toDouble(),
    height.toDouble(),
  );

  canvas.drawRect(
    bounds,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 0),
        const ui.Offset(0, 520),
        const <ui.Color>[
          ui.Color(0xFF5EC8FF),
          ui.Color(0xFFDDF5FF),
        ],
      ),
  );

  canvas.drawCircle(
    const ui.Offset(955, 145),
    72,
    ui.Paint()..color = const ui.Color(0xFFFFE4A0),
  );

  final ui.Path rearMountains = ui.Path()
    ..moveTo(0, 500)
    ..lineTo(180, 320)
    ..lineTo(330, 455)
    ..lineTo(545, 235)
    ..lineTo(735, 470)
    ..lineTo(980, 290)
    ..lineTo(1200, 485)
    ..lineTo(1200, 800)
    ..lineTo(0, 800)
    ..close();
  canvas.drawPath(
    rearMountains,
    ui.Paint()..color = const ui.Color(0xFF7693B6),
  );

  final ui.Path frontMountains = ui.Path()
    ..moveTo(0, 585)
    ..lineTo(250, 395)
    ..lineTo(455, 550)
    ..lineTo(710, 350)
    ..lineTo(965, 545)
    ..lineTo(1200, 430)
    ..lineTo(1200, 800)
    ..lineTo(0, 800)
    ..close();
  canvas.drawPath(
    frontMountains,
    ui.Paint()..color = const ui.Color(0xFF244D67),
  );

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 575, 1200, 225),
    ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 575),
        const ui.Offset(0, 800),
        const <ui.Color>[
          ui.Color(0xFF35C9D3),
          ui.Color(0xFF0A68A6),
        ],
      ),
  );

  final ui.Path reflection = ui.Path()
    ..moveTo(0, 640)
    ..quadraticBezierTo(300, 605, 610, 650)
    ..quadraticBezierTo(930, 700, 1200, 625)
    ..lineTo(1200, 800)
    ..lineTo(0, 800)
    ..close();
  canvas.drawPath(
    reflection,
    ui.Paint()..color = const ui.Color(0x44214455),
  );

  for (int x = 10; x < 1200; x += 82) {
    final double treeHeight = 52 + (x % 150) * 0.24;
    final ui.Path tree = ui.Path()
      ..moveTo(x.toDouble(), 612)
      ..lineTo(x + 22.0, 612 - treeHeight)
      ..lineTo(x + 44.0, 612)
      ..close();
    canvas.drawPath(
      tree,
      ui.Paint()..color = const ui.Color(0xFF174C3A),
    );
  }

  final ui.Image image = await recorder.endRecording().toImage(width, height);
  final ByteData? encoded = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  if (encoded == null) {
    throw StateError('Could not create the synthetic store photo');
  }
  return encoded.buffer.asUint8List();
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      scrollBehavior: const PhotoCutScrollBehavior(),
      locale: const Locale('en'),
      supportedLocales: PhotoCutLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        PhotoCutLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
  await _pumpUi(tester);
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<void> _configureTenByFifteen(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('size-preset-10x15')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-next')));
  await _pumpUi(tester);
  await tester.tap(find.byKey(const Key('wizard-paper-photo-10x15')));
  await _pumpUi(tester);

  for (int i = 0; i < 7; i += 1) {
    await tester.tap(find.byKey(const Key('copies-minus')));
    await tester.pump();
  }
  await _pumpUi(tester);
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await _pumpUi(tester);
  await binding.takeScreenshot(name);
}

final class _Fixture {
  const _Fixture({required this.image, required this.processor});

  final SelectedImage image;
  final _StoreImageProcessor processor;
}

final class _StoreImagePicker implements ImagePickerGateway {
  const _StoreImagePicker(this.image);

  final SelectedImage image;

  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    return ImageSelectionSuccess(image);
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    return const ImageSelectionCancelled();
  }
}

final class _StoreImageProcessor implements ImageProcessor {
  const _StoreImageProcessor({required this.photoBytes});

  final Uint8List photoBytes;

  static final SourceImageSize _size = SourceImageSize(
    widthPixels: 4000,
    heightPixels: 3000,
  );

  @override
  Future<SourceImageSize> inspect(Uint8List bytes) async => _size;

  @override
  Future<ProcessedImage> process(ImageProcessingRequest request) async {
    return ProcessedImage(bytes: photoBytes, size: _size);
  }
}
