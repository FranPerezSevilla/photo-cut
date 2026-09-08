import 'package:flutter/material.dart';
import 'package:photo_cut/core/crop/crop.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

final class SelectedPhotoInfo extends StatefulWidget {
  const SelectedPhotoInfo({
    super.key,
    required this.image,
    required this.imageProcessor,
  });

  final SelectedImage image;
  final ImageProcessor imageProcessor;

  @override
  State<SelectedPhotoInfo> createState() => _SelectedPhotoInfoState();
}

final class _SelectedPhotoInfoState extends State<SelectedPhotoInfo> {
  late Future<SourceImageSize> _inspection;

  @override
  void initState() {
    super.initState();
    _inspection = widget.imageProcessor.inspect(widget.image.bytes);
  }

  @override
  void didUpdateWidget(covariant SelectedPhotoInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.image, widget.image)) {
      _inspection = widget.imageProcessor.inspect(widget.image.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SourceImageSize>(
      future: _inspection,
      builder: (BuildContext context, AsyncSnapshot<SourceImageSize> snapshot) {
        if (snapshot.hasError) {
          return Text(
            'No se pudo leer la resolución de la foto.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final SourceImageSize size = snapshot.requireData;
        return Card(
          key: const Key('selected-photo-info'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${size.widthPixels} × ${size.heightPixels} px',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tamaño de impresión orientativo según resolución:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text('A 300 ppp · ${_physicalSizeLabel(size, 300)}'),
                Text('A 600 ppp · ${_physicalSizeLabel(size, 600)}'),
                const SizedBox(height: 6),
                Text(
                  'La foto digital no tiene una medida física única: tú eliges el tamaño final en el siguiente paso.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _physicalSizeLabel(SourceImageSize size, double dpi) {
    final double widthCm = size.widthPixels / dpi * 2.54;
    final double heightCm = size.heightPixels / dpi * 2.54;
    return '${_formatCm(widthCm)} × ${_formatCm(heightCm)} cm';
  }

  static String _formatCm(double value) {
    final String fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }
}
