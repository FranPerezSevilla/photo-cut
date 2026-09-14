import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_cut/core/theme/photo_cut_brand.dart';
import 'package:photo_cut/features/home/selected_photo_info.dart';
import 'package:photo_cut/features/pdf_spike/pdf_spike.dart';
import 'package:photo_cut/features/print_job/print_job.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';
import 'package:photo_cut/platform/image_picker/image_picker.dart';
import 'package:photo_cut/platform/image_processing/image_processing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.imagePickerGateway,
    required this.localeOverride,
    required this.onLocaleChanged,
    this.imageProcessor,
    this.pdfSpikeBuilder,
  });

  final ImagePickerGateway imagePickerGateway;
  final ImageProcessor? imageProcessor;
  final WidgetBuilder? pdfSpikeBuilder;
  final Locale? localeOverride;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  late final PhotoSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PhotoSelectionController(gateway: widget.imagePickerGateway);
    unawaited(_controller.recoverLostSelection());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const PhotoCutBrand(compact: true),
        actions: <Widget>[
          PopupMenuButton<String>(
            key: const Key('more-actions'),
            tooltip: l10n.text('language'),
            icon: const Icon(Icons.language_rounded),
            initialValue: widget.localeOverride?.languageCode ?? 'system',
            onSelected: (String languageCode) {
              widget.onLocaleChanged(
                languageCode == 'system' ? null : Locale(languageCode),
              );
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'system',
                child: _LanguageOption(
                  label: l10n.text('system'),
                  selected: widget.localeOverride == null,
                ),
              ),
              _languageItem('es', 'Español'),
              _languageItem('en', 'English'),
              _languageItem('fr', 'Français'),
              _languageItem('pt', 'Português'),
              _languageItem('de', 'Deutsch'),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final PhotoSelectionState state = _controller.state;
            final ImageProcessor imageProcessor =
                widget.imageProcessor ?? const DartImageProcessor();
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _PhotoHero(image: state.image),
                      const SizedBox(height: 32),
                      Text(
                        l10n.text('printExactTitle'),
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.image == null
                            ? l10n.text('homeEmptyBody')
                            : l10n.text('homeSelectedBody'),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (state.image != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          state.image!.displayName,
                          key: const Key('selected-image-name'),
                          style: Theme.of(context).textTheme.labelLarge,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        SelectedPhotoInfo(
                          image: state.image!,
                          imageProcessor: imageProcessor,
                        ),
                      ],
                      if (state.errorMessage != null) ...<Widget>[
                        const SizedBox(height: 20),
                        _SelectionError(
                          message: state.errorMessage!,
                          onDismiss: _controller.clearError,
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (state.image == null)
                        FilledButton.icon(
                          key: const Key('choose-photo'),
                          onPressed: state.isBusy
                              ? null
                              : _controller.selectFromGallery,
                          icon: state.isBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(l10n.text('choosePhoto')),
                        )
                      else ...<Widget>[
                        FilledButton.icon(
                          key: const Key('configure-photo'),
                          onPressed: () =>
                              _openConfiguration(state.image!, imageProcessor),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(l10n.text('configurePhoto')),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('choose-photo'),
                          onPressed: state.isBusy
                              ? null
                              : _controller.selectFromGallery,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(l10n.text('chooseAnotherPhoto')),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        l10n.text('privacyLocal'),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      if (kDebugMode) ...<Widget>[
                        const SizedBox(height: 20),
                        _DevelopmentNotice(
                          onOpenPdfSpike: () => _openPdfSpike(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PopupMenuItem<String> _languageItem(String code, String label) {
    return PopupMenuItem<String>(
      value: code,
      child: _LanguageOption(
        label: label,
        selected: widget.localeOverride?.languageCode == code,
      ),
    );
  }

  void _openConfiguration(SelectedImage image, ImageProcessor imageProcessor) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext routeContext) {
            return GuidedPrintWizard(
              image: image,
              imageProcessor: imageProcessor,
              onReview:
                  (
                    BuildContext configurationContext,
                    PrintJobConfiguration configuration,
                  ) {
                    unawaited(
                      Navigator.of(configurationContext).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext reviewContext) {
                            return PrintReviewScreen.production(
                              configuration: configuration,
                              imageProcessor: imageProcessor,
                            );
                          },
                        ),
                      ),
                    );
                  },
            );
          },
        ),
      ),
    );
  }

  void _openPdfSpike(BuildContext context) {
    final WidgetBuilder builder =
        widget.pdfSpikeBuilder ??
        (BuildContext routeContext) => PdfSpikeScreen.production();
    unawaited(
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: builder)),
    );
  }
}

final class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 28,
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                )
              : const SizedBox.shrink(),
        ),
        Text(label),
      ],
    );
  }
}

final class _PhotoHero extends StatelessWidget {
  const _PhotoHero({required this.image});

  final SelectedImage? image;

  @override
  Widget build(BuildContext context) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final SelectedImage? selected = image;

    return Semantics(
      label: selected == null
          ? l10n.text('photoBrandSemantics')
          : l10n.text('photoPreviewSemantics'),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: selected == null
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF071B4A),
                      Color(0xFF0A3D9A),
                      Color(0xFF0B63FF),
                    ],
                  )
                : null,
            color: selected == null
                ? null
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: selected == null
              ? const Center(child: PhotoCutBrand(light: true, hero: true))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.memory(
                    selected.bytes,
                    key: const Key('selected-image-preview'),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder:
                        (
                          BuildContext errorContext,
                          Object error,
                          StackTrace? stack,
                        ) {
                          return Center(
                            child: Text(
                              PhotoCutLocalizations.of(
                                errorContext,
                              ).text('cannotShowPhoto'),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                  ),
                ),
        ),
      ),
    );
  }
}

final class _SelectionError extends StatelessWidget {
  const _SelectionError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            IconButton(
              onPressed: onDismiss,
              tooltip: l10n.text('closeNotice'),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DevelopmentNotice extends StatelessWidget {
  const _DevelopmentNotice({required this.onOpenPdfSpike});

  final VoidCallback onOpenPdfSpike;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Development build · PDF preview',
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenPdfSpike,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Open sample PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
