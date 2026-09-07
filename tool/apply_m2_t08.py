#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'Expected text not found in {path}: {old[:140]!r}')
    if text.count(old) != 1:
        raise SystemExit(f'Expected exactly one match in {path}, found {text.count(old)}')
    path.write_text(text.replace(old, new), encoding='utf-8')


barrel = ROOT / 'lib/features/print_job/print_job.dart'
replace_once(
    barrel,
    "export 'resolution_guidance.dart';\n",
    "export 'resolution_guidance.dart';\nexport 'step_one_pdf_preview.dart';\n",
)
replace_once(
    barrel,
    "export 'visual_framing_editor.dart';\n",
    "export 'visual_framing_editor.dart';\nexport 'zoomable_pdf_document_preview.dart';\n",
)

screen = ROOT / 'lib/features/print_job/print_configuration_screen.dart'
text = screen.read_text(encoding='utf-8')

import_marker = "import 'package:photo_cut/features/print_job/resolution_guidance.dart';\n"
if 'step_one_pdf_preview.dart' not in text:
    text = text.replace(
        import_marker,
        import_marker
        + "import 'package:photo_cut/features/print_job/step_one_pdf_preview.dart';\n",
    )
if 'print_job_document_factory.dart' not in text:
    marker = "import 'package:photo_cut/features/print_job/print_job_configuration.dart';\n"
    text = text.replace(
        marker,
        marker
        + "import 'package:photo_cut/features/print_job/print_job_document_factory.dart';\n",
    )
if "zoomable_pdf_document_preview.dart" not in text:
    marker = "import 'package:photo_cut/features/print_job/visual_framing_editor.dart';\n"
    text = text.replace(
        marker,
        marker
        + "import 'package:photo_cut/features/print_job/zoomable_pdf_document_preview.dart';\n",
    )

replace_once(
    screen,
    'PLACEHOLDER_NEVER_USED',
    'PLACEHOLDER_NEVER_USED',
) if False else None

old_constructor = """    required this.image,
    this.imageProcessor,
    this.onReview,
  });

  final SelectedImage image;
  final ImageProcessor? imageProcessor;
  final PrintJobReviewCallback? onReview;
"""
new_constructor = """    required this.image,
    this.imageProcessor,
    this.onReview,
    this.previewDocumentLoader,
    this.previewBuilder,
    this.previewTransformationController,
  });

  final SelectedImage image;
  final ImageProcessor? imageProcessor;
  final PrintJobReviewCallback? onReview;
  final StepOnePdfDocumentLoader? previewDocumentLoader;
  final ZoomablePdfPreviewBuilder? previewBuilder;
  final TransformationController? previewTransformationController;
"""
if old_constructor not in text:
    raise SystemExit('Could not locate PrintConfigurationScreen constructor')
text = text.replace(old_constructor, new_constructor, 1)

old_state_fields = """final class _PrintConfigurationScreenState
    extends State<PrintConfigurationScreen> {
  late final PrintConfigurationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrintConfigurationController(
      image: widget.image,
      imageProcessor: widget.imageProcessor ?? const DartImageProcessor(),
    );
    unawaited(_controller.inspectImage());
  }
"""
new_state_fields = """enum _StepOneView { settings, preview }

final class _PrintConfigurationScreenState
    extends State<PrintConfigurationScreen> {
  late final PrintConfigurationController _controller;
  late final ImageProcessor _imageProcessor;
  late final StepOnePdfDocumentLoader _previewDocumentLoader;
  _StepOneView _selectedView = _StepOneView.settings;

  @override
  void initState() {
    super.initState();
    _imageProcessor = widget.imageProcessor ?? const DartImageProcessor();
    _controller = PrintConfigurationController(
      image: widget.image,
      imageProcessor: _imageProcessor,
    );
    final PrintJobDocumentFactory previewFactory = PrintJobDocumentFactory(
      imageProcessor: _imageProcessor,
    );
    _previewDocumentLoader =
        widget.previewDocumentLoader ?? previewFactory.build;
    unawaited(_controller.inspectImage());
  }
"""
if old_state_fields not in text:
    raise SystemExit('Could not locate configuration state/init block')
text = text.replace(old_state_fields, new_state_fields, 1)

old_appbar = "      appBar: AppBar(title: const Text('Preparar en Photo Cut')),\n"
new_appbar = """      appBar: AppBar(
        title: const Text('Preparar en Photo Cut'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<_StepOneView>(
              key: const Key('configuration-view-switcher'),
              segments: const <ButtonSegment<_StepOneView>>[
                ButtonSegment<_StepOneView>(
                  value: _StepOneView.settings,
                  icon: Icon(Icons.tune),
                  label: Text('Ajustes', key: Key('settings-view-tab')),
                ),
                ButtonSegment<_StepOneView>(
                  value: _StepOneView.preview,
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  label: Text('Vista previa', key: Key('preview-view-tab')),
                ),
              ],
              selected: <_StepOneView>{_selectedView},
              onSelectionChanged: (Set<_StepOneView> selection) {
                setState(() {
                  _selectedView = selection.single;
                });
              },
            ),
          ),
        ),
      ),
"""
if old_appbar not in text:
    raise SystemExit('Could not locate app bar')
text = text.replace(old_appbar, new_appbar, 1)

old_return = """            final PrintConfigurationState state = _controller.state;
            return CustomScrollView(
              slivers: <Widget>[
"""
new_return = """            final PrintConfigurationState state = _controller.state;
            return IndexedStack(
              key: const Key('configuration-view-stack'),
              index: _selectedView.index,
              children: <Widget>[
                CustomScrollView(
                  key: const PageStorageKey<String>('configuration-settings-scroll'),
                  slivers: <Widget>[
"""
if old_return not in text:
    raise SystemExit('Could not locate settings CustomScrollView')
text = text.replace(old_return, new_return, 1)

old_close = """                    ],
                  ),
                ),
              ],
            );
          },
"""
new_close = """                    ],
                  ),
                ),
                  ],
                ),
                StepOnePdfPreview(
                  key: const Key('step-one-pdf-preview'),
                  active: _selectedView == _StepOneView.preview,
                  canGenerate: state.canReview,
                  configuration: state.configuration,
                  documentLoader: _previewDocumentLoader,
                  previewBuilder: widget.previewBuilder,
                  transformationController:
                      widget.previewTransformationController,
                ),
              ],
            );
          },
"""
if old_close not in text:
    raise SystemExit('Could not locate settings scroll closing block')
text = text.replace(old_close, new_close, 1)

screen.write_text(text, encoding='utf-8')
print('Applied M2-T08 persistent preview patch.')
