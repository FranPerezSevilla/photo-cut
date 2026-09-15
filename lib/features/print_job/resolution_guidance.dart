import 'package:flutter/material.dart';
import 'package:photo_cut/core/quality/quality.dart';
import 'package:photo_cut/features/print_job/print_job_configuration.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';

final class ResolutionGuidance extends StatelessWidget {
  const ResolutionGuidance({
    super.key,
    required this.configuration,
    this.advisor = const ResolutionAdvisor(),
  });

  final ResolutionAdvisor advisor;
  final PrintJobConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    final sourceSize = configuration.sourceSize;
    if (sourceSize == null) {
      return const SizedBox.shrink();
    }

    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    final ResolutionAdvice advice = advisor.evaluate(
      sourceSize: sourceSize,
      cropRect: configuration.cropRect,
      fitMode: configuration.fitMode,
      outputWidth: configuration.photoWidth,
      outputHeight: configuration.photoHeight,
    );
    final int roundedDpi = advice.effectiveDpi.round();

    if (!advice.shouldWarn) {
      return Text(
        l10n.dpiEstimated(roundedDpi),
        key: const Key('resolution-guidance-ok'),
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      );
    }

    final bool isLow = advice.quality == ResolutionQuality.low;
    return Card(
      key: const Key('resolution-warning'),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.text(isLow ? 'lowResolution' : 'fairResolution'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '≈ $roundedDpi ppp. '
                    '${l10n.text(isLow ? 'lowResolutionDetail' : 'fairResolutionDetail')} '
                    '${l10n.text('reducePhysicalSize')} '
                    '${l10n.text('resolutionGuidance')}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
