import 'package:flutter/material.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';

const List<double> _grayscaleMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// A direct framing control: the user moves the image itself inside the exact
/// target aspect. It only changes normalized focus and never creates crop state
/// outside the existing print-job model.
final class VisualFramingEditor extends StatelessWidget {
  const VisualFramingEditor({
    super.key,
    required this.configuration,
    required this.onFocusChanged,
    this.mapper = const VisualFramingMapper(),
    this.maxHeight = 300,
  });

  final PrintJobConfiguration configuration;
  final VisualFramingMapper mapper;
  final ValueChanged<NormalizedPoint> onFocusChanged;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final SourceImageSize? sourceSize = configuration.sourceSize;
    if (sourceSize == null) {
      return const Card(
        key: Key('visual-framing-loading'),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Flexible(child: Text('Preparando el encuadre…')),
            ],
          ),
        ),
      );
    }

    final bool cropToFill = configuration.fitMode == ImageFitMode.cropToFill;
    final VisualFramingAxis axis = mapper.axisFor(
      sourceSize: sourceSize,
      targetAspectRatio: configuration.photoAspectRatio,
    );
    final bool canDrag = cropToFill && axis != VisualFramingAxis.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          cropToFill
              ? canDrag
                    ? _dragInstruction(axis)
                    : 'La foto ya tiene esta proporción: no hace falta moverla.'
              : 'Encajar muestra la foto completa y no recorta ninguna parte.',
          key: const Key('visual-framing-instruction'),
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Semantics(
          label: cropToFill
              ? 'Encuadre visual. Mueve la foto para elegir qué parte queda dentro.'
              : 'Vista de encaje. La foto completa queda dentro del marco.',
          hint: canDrag
              ? 'Arrastra la foto. Pulsa Centrar para volver al centro.'
              : null,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: AspectRatio(
                aspectRatio: configuration.photoAspectRatio,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return GestureDetector(
                      key: const Key('visual-framing-editor'),
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: canDrag
                          ? (DragUpdateDetails details) {
                              final NormalizedPoint next = mapper.applyDrag(
                                sourceSize: sourceSize,
                                targetAspectRatio:
                                    configuration.photoAspectRatio,
                                frameWidth: constraints.maxWidth,
                                frameHeight: constraints.maxHeight,
                                currentFocus: configuration.focus,
                                dragDeltaX: details.delta.dx,
                                dragDeltaY: details.delta.dy,
                              );
                              if (next != configuration.focus) {
                                onFocusChanged(next);
                              }
                            }
                          : null,
                      onDoubleTap: cropToFill
                          ? () => onFocusChanged(NormalizedPoint.center)
                          : null,
                      child: _FramingSurface(
                        configuration: configuration,
                        cropToFill: cropToFill,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 2,
          children: <Widget>[
            Icon(
              cropToFill ? Icons.crop_free : Icons.fit_screen_outlined,
              size: 18,
            ),
            Text(
              cropToFill
                  ? canDrag
                        ? 'Rellenar · recorte activo'
                        : 'Rellenar · sin recorte necesario'
                  : 'Encajar · foto completa',
              key: const Key('visual-framing-mode-label'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            if (cropToFill && configuration.focus != NormalizedPoint.center)
              TextButton(
                key: const Key('center-framing'),
                onPressed: () => onFocusChanged(NormalizedPoint.center),
                child: const Text('Centrar'),
              ),
          ],
        ),
      ],
    );
  }
}

final class _FramingSurface extends StatelessWidget {
  const _FramingSurface({
    required this.configuration,
    required this.cropToFill,
  });

  final PrintJobConfiguration configuration;
  final bool cropToFill;

  @override
  Widget build(BuildContext context) {
    final Alignment alignment = Alignment(
      configuration.focus.x * 2 - 1,
      configuration.focus.y * 2 - 1,
    );

    Widget image = Image.memory(
      configuration.image.bytes,
      fit: cropToFill ? BoxFit.cover : BoxFit.contain,
      alignment: alignment,
      gaplessPlayback: true,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return const Center(child: Icon(Icons.broken_image_outlined, size: 42));
      },
    );

    if (configuration.colorMode == ImageColorMode.grayscale) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: image,
      );
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: cropToFill ? colors.primary : colors.outline,
            width: cropToFill ? 2 : 1.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            image,
            Positioned(
              left: 10,
              top: 10,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      cropToFill ? 'Rellenar' : 'Foto completa',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dragInstruction(VisualFramingAxis axis) {
  return switch (axis) {
    VisualFramingAxis.horizontal =>
      'Desliza la foto a izquierda o derecha para elegir el encuadre.',
    VisualFramingAxis.vertical =>
      'Desliza la foto arriba o abajo para elegir el encuadre.',
    VisualFramingAxis.none =>
      'La foto ya tiene esta proporción: no hace falta moverla.',
  };
}
