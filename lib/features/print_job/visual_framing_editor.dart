import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/core/quality/resolution_advisor.dart';
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
    required this.onZoomChanged,
    this.mapper = const VisualFramingMapper(),
    this.maxHeight = 150,
  });

  final PrintJobConfiguration configuration;
  final VisualFramingMapper mapper;
  final ValueChanged<NormalizedPoint> onFocusChanged;
  final ValueChanged<double> onZoomChanged;
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
        if (cropToFill)
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
                            onZoomChanged: widget.onZoomChanged,
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
            label: Text(
              widget.configuration.framingZoom > 1.01
                  ? 'Ajustar encuadre · ${widget.configuration.framingZoom.toStringAsFixed(1)}×'
                  : 'Ajustar encuadre',
            ),
          )
        else
          Text(
            'La foto completa queda dentro del marco.',
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
    required this.onZoomChanged,
    required this.imageBytes,
  });

  final PrintJobConfiguration configuration;
  final VisualFramingMapper mapper;
  final ValueChanged<NormalizedPoint> onFocusChanged;
  final ValueChanged<double> onZoomChanged;
  final Uint8List imageBytes;

  @override
  State<_FramingFocusScreen> createState() => _FramingFocusScreenState();
}

final class _FramingFocusScreenState extends State<_FramingFocusScreen> {
  static const CropPlanner _cropPlanner = CropPlanner();
  static const ResolutionAdvisor _resolutionAdvisor = ResolutionAdvisor();

  late NormalizedPoint _focus;
  late double _zoom;
  late double _gestureStartZoom;
  Offset? _gestureLastFocalPoint;
  late final Uint8List _imageBytes;
  late final Object _imageSessionKey;

  @override
  void initState() {
    super.initState();
    _focus = widget.configuration.focus;
    _zoom = widget.configuration.framingZoom;
    _gestureStartZoom = _zoom;
    _imageBytes = Uint8List.fromList(widget.imageBytes);
    _imageSessionKey = Object();
  }

  @override
  Widget build(BuildContext context) {
    final SourceImageSize sourceSize = widget.configuration.sourceSize!;
    final NormalizedCropRect cropRect = _cropPlanner.plan(
      sourceSize: sourceSize,
      targetAspectRatio: widget.configuration.photoAspectRatio,
      focus: _focus,
      zoom: _zoom,
    );
    final PrintJobConfiguration configuration = widget.configuration.copyWith(
      focus: _focus,
      framingZoom: _zoom,
      cropRect: cropRect,
    );
    final VisualFramingAxis axis = widget.mapper.axisFor(
      sourceSize: sourceSize,
      targetAspectRatio: configuration.photoAspectRatio,
    );
    final ResolutionAdvice advice = _resolutionAdvisor.evaluate(
      sourceSize: sourceSize,
      cropRect: cropRect,
      fitMode: ImageFitMode.cropToFill,
      outputWidth: configuration.photoWidth,
      outputHeight: configuration.photoHeight,
    );

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
                'Mueve y amplía la foto',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Arrastra para encuadrar y pellizca para hacer zoom. Doble toque para centrar.',
                key: const Key('visual-framing-instruction'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
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
                              onScaleStart: (ScaleStartDetails details) {
                                _gestureStartZoom = _zoom;
                                _gestureLastFocalPoint =
                                    details.localFocalPoint;
                              },
                              onScaleUpdate: (ScaleUpdateDetails details) {
                                final double nextZoom =
                                    (_gestureStartZoom * details.scale)
                                        .clamp(
                                          CropPlanner.minimumZoom,
                                          CropPlanner.maximumZoom,
                                        )
                                        .toDouble();
                                final Offset previous =
                                    _gestureLastFocalPoint ??
                                    details.localFocalPoint;
                                final Offset delta =
                                    details.localFocalPoint - previous;
                                _gestureLastFocalPoint = details.localFocalPoint;

                                NormalizedPoint nextFocus = _focus;
                                if (delta.distanceSquared > 0.01) {
                                  nextFocus = _focusAfterDrag(
                                    sourceSize: sourceSize,
                                    axis: axis,
                                    targetAspectRatio:
                                        configuration.photoAspectRatio,
                                    frameWidth: constraints.maxWidth,
                                    frameHeight: constraints.maxHeight,
                                    currentFocus: _focus,
                                    dragDelta: delta,
                                    zoom: nextZoom,
                                  );
                                }

                                final bool zoomChanged =
                                    (nextZoom - _zoom).abs() > 0.0001;
                                final bool focusChanged = nextFocus != _focus;
                                if (!zoomChanged && !focusChanged) {
                                  return;
                                }
                                setState(() {
                                  _zoom = nextZoom;
                                  _focus = nextFocus;
                                });
                                if (zoomChanged) {
                                  widget.onZoomChanged(nextZoom);
                                }
                                if (focusChanged) {
                                  widget.onFocusChanged(nextFocus);
                                }
                              },
                              onScaleEnd: (_) =>
                                  _gestureLastFocalPoint = null,
                              onDoubleTap: () =>
                                  _setFocus(NormalizedPoint.center),
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
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    'Zoom',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${_zoom.toStringAsFixed(1)}×',
                    key: const Key('framing-zoom-value'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              Slider(
                key: const Key('framing-zoom-slider'),
                min: CropPlanner.minimumZoom,
                max: CropPlanner.maximumZoom,
                divisions: 30,
                value: _zoom,
                onChanged: _setZoom,
              ),
              if (_zoom > 1.01) ...<Widget>[
                _ZoomQualityNotice(advice: advice),
                const SizedBox(height: 8),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('center-framing'),
                      onPressed:
                          _focus == NormalizedPoint.center && _zoom == 1
                          ? null
                          : _resetFraming,
                      icon: const Icon(Icons.center_focus_weak_rounded),
                      label: const Text('Restablecer'),
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

  NormalizedPoint _focusAfterDrag({
    required SourceImageSize sourceSize,
    required VisualFramingAxis axis,
    required double targetAspectRatio,
    required double frameWidth,
    required double frameHeight,
    required NormalizedPoint currentFocus,
    required Offset dragDelta,
    required double zoom,
  }) {
    if (zoom <= 1.0001) {
      return widget.mapper.applyDrag(
        sourceSize: sourceSize,
        targetAspectRatio: targetAspectRatio,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        currentFocus: currentFocus,
        dragDeltaX: dragDelta.dx,
        dragDeltaY: dragDelta.dy,
      );
    }

    final double x = (currentFocus.x - dragDelta.dx / frameWidth)
        .clamp(0.0, 1.0)
        .toDouble();
    final double y = (currentFocus.y - dragDelta.dy / frameHeight)
        .clamp(0.0, 1.0)
        .toDouble();
    return NormalizedPoint(x: x, y: y);
  }

  void _setZoom(double next) {
    final double clamped = next
        .clamp(CropPlanner.minimumZoom, CropPlanner.maximumZoom)
        .toDouble();
    if ((clamped - _zoom).abs() < 0.0001) {
      return;
    }
    setState(() => _zoom = clamped);
    widget.onZoomChanged(clamped);
  }

  void _setFocus(NormalizedPoint next) {
    if (next == _focus) {
      return;
    }
    setState(() => _focus = next);
    widget.onFocusChanged(next);
  }

  void _resetFraming() {
    final bool focusChanged = _focus != NormalizedPoint.center;
    final bool zoomChanged = (_zoom - 1).abs() > 0.0001;
    setState(() {
      _focus = NormalizedPoint.center;
      _zoom = 1;
    });
    if (zoomChanged) {
      widget.onZoomChanged(1);
    }
    if (focusChanged) {
      widget.onFocusChanged(NormalizedPoint.center);
    }
  }
}

final class _ZoomQualityNotice extends StatelessWidget {
  const _ZoomQualityNotice({required this.advice});

  final ResolutionAdvice advice;

  @override
  Widget build(BuildContext context) {
    final bool warning = advice.shouldWarn;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('framing-zoom-quality'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 19,
            color: warning ? colors.onErrorContainer : colors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning
                  ? 'Este zoom deja aprox. ${advice.effectiveDpi.round()} ppp y puede perder calidad al imprimir.'
                  : 'Al ampliar recortas más píxeles. Calidad estimada: ${advice.effectiveDpi.round()} ppp.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
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

    if (cropToFill && configuration.framingZoom > 1.0001) {
      image = Transform.scale(
        scale: configuration.framingZoom,
        alignment: alignment,
        child: image,
      );
    }

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
                      cropToFill
                          ? configuration.framingZoom > 1.01
                                ? 'Rellenar · ${configuration.framingZoom.toStringAsFixed(1)}×'
                                : 'Rellenar'
                          : 'Foto completa',
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
