import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/core/theme/photo_cut_brand.dart';
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
      scrollBehavior: const PhotoCutScrollBehavior(),
      home: _SplashGate(
        child: HomeScreen(
          imagePickerGateway: imagePickerGateway,
          imageProcessor: imageProcessor,
          pdfSpikeBuilder: pdfSpikeBuilder,
        ),
      ),
    );
  }
}

final class _SplashGate extends StatefulWidget {
  const _SplashGate({required this.child});

  final Widget child;

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

final class _SplashGateState extends State<_SplashGate> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _ready ? widget.child : const _PhotoCutSplash(),
    );
  }
}

final class _PhotoCutSplash extends StatelessWidget {
  const _PhotoCutSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('photo-cut-splash'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PhotoCutBrand(light: true),
              SizedBox(height: 14),
              Text(
                'Tamaño exacto. Sin complicaciones.',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
