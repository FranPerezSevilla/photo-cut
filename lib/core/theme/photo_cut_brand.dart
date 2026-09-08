import 'package:flutter/material.dart';

final class PhotoCutBrand extends StatelessWidget {
  const PhotoCutBrand({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final Color foreground = light ? Colors.white : const Color(0xFF172033);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 32 : 40,
          height: compact ? 32 : 40,
          decoration: BoxDecoration(
            color: light ? Colors.white : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(compact ? 10 : 13),
          ),
          child: Icon(
            Icons.crop_rounded,
            size: compact ? 19 : 24,
            color: light ? Theme.of(context).colorScheme.primary : Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Photo Cut',
          style:
              (compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
