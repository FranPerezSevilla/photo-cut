import 'package:flutter/material.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/features/home/home_screen.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

class PhotoCutApp extends StatelessWidget {
  PhotoCutApp({
    super.key,
    ImagePickerGateway? imagePickerGateway,
    this.imageProcessor,
    this.pdfSpikeBuilder,
  }) : imagePickerGateway = imagePickerGateway ?? PluginImagePickerGateway();

  final ImagePickerGateway imagePickerGateway;
  final ImageProcessor? imageProcessor;
  final WidgetBuilder? pdfSpikeBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Cut',
      theme: AppTheme.light(),
      home: HomeScreen(
        imagePickerGateway: imagePickerGateway,
        imageProcessor: imageProcessor,
        pdfSpikeBuilder: pdfSpikeBuilder,
      ),
    );
  }
}
