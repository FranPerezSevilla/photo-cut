import 'dart:async';
import 'dart:typed_data';

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

/// Compact framing entry point. The inline preview and each focused editing
/// session own independent byte buffers so navigation cannot leave the image
/// provider in a stale/blank state.
final class VisualFramingEditor extends StatefulWidget {
  const VisualFramingEditor({
    super.key,
    required this.configuration,
    required this.onFocusChanged,
    this.mapper = const VisualFramingMapper(),
    this.maxHeight = 150,
  });

  final PrintJobConfiguration configuration;
  final VisualFramingMapper mapper;
  final ValueChanged<NormalizedPoint> onFocusChanged;
  final double maxHeight;

  @override
  State<VisualFramingEditor> createState() => _VisualFramingEditorState();
}

final class _VisualFramingEditorState extends State<VisualFramingEditor> {
  late Uint8List _previewBytes;
  late Object _previewSession;

  @override
  void initState() {
    super.initState();
    _resetPreviewSession();
  }

  @override
  void didUpdateWidget(covariant VisualFramingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool imageChanged =
        !identical(
          oldWidget.configuration.image.bytes,
          widget.configuration.image.bytes,
        ) ||
        oldWidget.configuration.image.displayName !=
            widget.configuration.image.displayName;
    if (imageChanged) {
      _resetPreviewSession();
    }
  }

  void _resetPreviewSession() {
    _previewBytes = Uint8List.fromList(widget.configuration.image.bytes);
    _previewSession = Object();
  }

  @override
  Widget build(BuildContext context) {
    final SourceImageSize? sourceSize = widget.configuration.sourceSize;
    if (sourceSize == null) {
      return const Card(
        key: Key('visual-framing-loading'),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Flexible(child: Text('Preparando el encuadre…')),
            ],
          ),
        ),
      );
    }

    final bool cropToFill =
        widget.configuration.fitMode == ImageFitMode.cropToFill;
    final VisualFramingAxis axis = widget.mapper.axisFor(
      sourceSize: sourceSize,
      targetAspectRatio: widget.configuration.photoAspectRatio,
    );
    final bool canAdjust = cropToFill && axis != VisualFramingAxis.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: AspectRatio(
              aspectRatio: widget.configuration.photoAspectRatio,
              child: IgnorePointer(
                child: _FramingSurface(
                  key: const Key('visual-framing-preview'),
                  configuration: widget.configuration,
                  cropToFill: cropToFill,
                  imageBytes: _previewBytes,
                  imageKey: ObjectKey(_previewSession),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (canAdjust)
          FilledButton.tonalIcon(
            key: const Key('open-framing-focus'),
            onPressed: () {
              final Uint8List focusedBytes = Uint8List.fromList(_previewBytes);
              unawaited(
                Navigator.of(context)
                    .push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext routeContext) {
                          return _FramingFocusScreen(
                            configuration: widget.configuration,
                            mapper: widget.mapper,
                            onFocusChanged: widget.onFocusChanged,
                            imageBytes: focusedBytes,
                          );
                        },
                      ),
                    )
                    .then((_) {
                      if (!mounted) {
                        return;
                      }
                      setState(_resetPreviewSession);
                    }),
              );
            },
            icon: const Icon(Icons.center_focus_strong_rounded),
            label: const Text('Ajustar encuadre'),
          )
        else
          Text(
            cropToFill
                ? 'La foto ya tiene esta proporción: no hace falta ajustarla.'
                : 'La foto completa queda dentro del marco.',
            key: const Key('visual-framing-instruction'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

final class _FramingFocusScreen extends StatefulWidget {
  const _FramingFocusScreen({
    required this.configuration,
    required this.mapper,
    required this.onFocusChanged,
    required this.imageBytes,
  });

  final PrintJobConfiguration configuration;
  final VisualFramingMapper mapper;
  final ValueChanged<NormalizedPoint> onFocusChanged;
  final Uint8List imageBytes;

  @override
  State<_FramingFocusScreen> createState() => _FramingFocusScreenState();
}

final class _FramingFocusScreenState extends State<_FramingFocusScreen> {
  late NormalizedPoint _focus;
  late final Uint8List _imageBytes;
  late final Object _imageSessionKey;

  @override
  void initState() {
    super.initState();
    _focus = widget.configuration.focus;
    _imageBytes = Uint8List.fromList(widget.imageBytes);
    _imageSessionKey = Object();
  }

  @override
  Widget build(BuildContext context) {
    final PrintJobConfiguration configuration = widget.configuration.copyWith(
      focus: _focus,
    );
    final SourceImageSize sourceSize = configuration.sourceSize!;
    final VisualFramingAxis axis = widget.mapper.axisFor(
      sourceSize: sourceSize,
      targetAspectRatio: configuration.photoAspectRatio,
    );
    final bool canDrag = axis != VisualFramingAxis.none;

    return Scaffold(
      key: const Key('framing-focus-screen'),
      appBar: AppBar(
        title: const Text('Ajustar encuadre'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Elige qué parte queda dentro',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                canDrag
                    ? _dragInstruction(axis)
                    : 'La foto ya coincide con la proporción elegida.',
                key: const Key('visual-framing-instruction'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: configuration.photoAspectRatio,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            return GestureDetector(
                              key: const Key('visual-framing-editor'),
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: canDrag
                                  ? (DragUpdateDetails details) {
                                      final NormalizedPoint next = widget.mapper
                                          .applyDrag(
                                            sourceSize: sourceSize,
                                            targetAspectRatio:
                                                configuration.photoAspectRatio,
                                            frameWidth: constraints.maxWidth,
                                            frameHeight: constraints.maxHeight,
                                            currentFocus: _focus,
                                            dragDeltaX: details.delta.dx,
                                            dragDeltaY: details.delta.dy,
                                          );
                                      if (next != _focus) {
                                        setState(() => _focus = next);
                                        widget.onFocusChanged(next);
                                      }
                                    }
                                  : null,
                              onDoubleTap: canDrag
                                  ? () => _setFocus(NormalizedPoint.center)
                                  : null,
                              child: _FramingSurface(
                                configuration: configuration,
                                cropToFill: true,
                                imageBytes: _imageBytes,
                                imageKey: ObjectKey(_imageSessionKey),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('center-framing'),
                      onPressed: _focus == NormalizedPoint.center
                          ? null
                          : () => _setFocus(NormalizedPoint.center),
                      icon: const Icon(Icons.center_focus_weak_rounded),
                      label: const Text('Centrar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Guardar encuadre'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setFocus(NormalizedPoint next) {
    setState(() => _focus = next);
    widget.onFocusChanged(next);
  }
}

final class _FramingSurface extends StatelessWidget {
  const _FramingSurface({
    super.key,
    required this.configuration,
    required this.cropToFill,
    required this.imageBytes,
    this.imageKey,
  });

  final PrintJobConfiguration configuration;
  final bool cropToFill;
  final Uint8List imageBytes;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final Alignment alignment = Alignment(
      configuration.focus.x * 2 - 1,
      configuration.focus.y * 2 - 1,
    );

    Widget image = Image(
      image: MemoryImage(imageBytes),
      key: imageKey,
      fit: cropToFill ? BoxFit.cover : BoxFit.contain,
      alignment: alignment,
      gaplessPlayback: false,
      filterQuality: FilterQuality.medium,
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
              left: 8,
              top: 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Text(
                      cropToFill ? 'Rellenar' : 'Foto completa',
                      style: Theme.of(context).textTheme.labelSmall,
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
      'Desliza la foto a izquierda o derecha. Aquí solo ajustas el encuadre.',
    VisualFramingAxis.vertical =>
      'Desliza la foto arriba o abajo. Aquí solo ajustas el encuadre.',
    VisualFramingAxis.none =>
      'La foto ya tiene esta proporción: no hace falta moverla.',
  };
}
