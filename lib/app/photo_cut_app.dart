import 'package:flutter/material.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';

class PhotoCutApp extends StatelessWidget {
  PhotoCutApp({
    super.key,
    ImagePickerGateway? imagePickerGateway,
    this.pdfSpikeBuilder,
  }) : imagePickerGateway =
           imagePickerGateway ?? PluginImagePickerGateway();

  final ImagePickerGateway imagePickerGateway;
  final WidgetBuilder? pdfSpikeBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Cut',
      theme: AppTheme.light(),
      home: HomeScreen(
        imagePickerGateway: imagePickerGateway,
        pdfSpikeBuilder: pdfSpikeBuilder,
      ),
    );
  }
}
