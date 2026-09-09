import 'package:flutter/material.dart';

abstract final class PhotoCutBrandAssets {
  static const String icon = 'assets/branding/photo_cut_icon.png';
}

final class PhotoCutBrand extends StatelessWidget {
  const PhotoCutBrand({
    super.key,
    this.compact = false,
    this.light = false,
    this.hero = false,
  });

  final bool compact;
  final bool light;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final double markSize = hero ? 112 : (compact ? 32 : 40);
    final TextStyle? baseStyle = hero
        ? Theme.of(context).textTheme.headlineMedium
        : compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleLarge;
    final Color photoColor = light ? Colors.white : const Color(0xFF071B4A);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          PhotoCutBrandAssets.icon,
          key: const Key('photo-cut-brand-icon'),
          width: markSize,
          height: markSize,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(width: hero ? 18 : 10),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: 'Photo', style: TextStyle(color: photoColor)),
              const TextSpan(
                text: ' Cut',
                style: TextStyle(color: Color(0xFF19C6F2)),
              ),
            ],
          ),
          key: const Key('photo-cut-wordmark'),
          style: baseStyle?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: hero ? -1.1 : -0.4,
          ),
        ),
      ],
    );
  }
}
