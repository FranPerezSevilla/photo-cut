import 'package:flutter/material.dart';
import 'package:photo_cut/core/theme/app_theme.dart';
import 'package:photo_cut/features/home/home_screen.dart';

class PhotoCutApp extends StatelessWidget {
  const PhotoCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Photo Cut',
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
