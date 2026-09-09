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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF071B4A),
              Color(0xFF0A3D9A),
              Color(0xFF0B63FF),
            ],
            stops: <double>[0, 0.62, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const Positioned(
              top: -160,
              left: -120,
              child: _SplashOrb(size: 360, opacity: 0.16),
            ),
            const Positioned(
              bottom: -220,
              right: -180,
              child: _SplashOrb(size: 460, opacity: 0.12),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: const PhotoCutBrand(light: true, hero: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SplashOrb extends StatelessWidget {
  const _SplashOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF24D7F4).withValues(alpha: opacity),
          width: 2.5,
        ),
        gradient: RadialGradient(
          colors: <Color>[
            const Color(0xFF24D7F4).withValues(alpha: opacity * 0.45),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
