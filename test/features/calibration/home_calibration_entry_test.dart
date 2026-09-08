import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

void main() {
  testWidgets('home exposes calibration before selecting a photo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          imagePickerGateway: _CancelledImagePickerGateway(),
          calibrationBuilder: (BuildContext context) {
            return const Scaffold(
              body: Center(child: Text('Calibration route open')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-calibration')), findsOneWidget);
    expect(find.text('Elegir foto'), findsOneWidget);

    final Finder calibration = find.byKey(const Key('open-calibration'));
    await tester.ensureVisible(calibration);
    await tester.tap(calibration);
    await tester.pumpAndSettle();

    expect(find.text('Calibration route open'), findsOneWidget);
  });
}

final class _CancelledImagePickerGateway implements ImagePickerGateway {
  @override
  Future<ImageSelectionResult> pickFromGallery() async {
    return const ImageSelectionCancelled();
  }

  @override
  Future<ImageSelectionResult> recoverLostSelection() async {
    return const ImageSelectionCancelled();
  }
}
