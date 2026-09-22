import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_cut/features/paywall/lifetime_purchase_controller.dart';
import 'package:photo_cut/l10n/photo_cut_localizations.dart';

final class LifetimePaywall extends StatefulWidget {
  const LifetimePaywall({
    super.key,
    required this.controller,
    required this.onUnlocked,
    required this.onBack,
  });

  final LifetimePurchaseController controller;
  final VoidCallback onUnlocked;
  final VoidCallback onBack;

  @override
  State<LifetimePaywall> createState() => _LifetimePaywallState();
}

final class _LifetimePaywallState extends State<LifetimePaywall> {
  bool _unlockHandled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    unawaited(widget.controller.initialize());
  }

  @override
  void didUpdateWidget(LifetimePaywall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
    _unlockHandled = false;
    unawaited(widget.controller.initialize());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    final LifetimePurchaseState state = widget.controller.state;
    if (state.phase == LifetimePurchasePhase.unlocked && !_unlockHandled) {
      _unlockHandled = true;
      widget.onUnlocked();
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);
    final LifetimePurchaseState state = widget.controller.state;
    final String? price = state.product?.price;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.workspace_premium_outlined,
                    key: Key('lifetime-paywall'),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.text('lifetimePaywallTitle'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.text('lifetimePaywallBody'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.text('lifetimePaywallOneTime'),
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (state.phase == LifetimePurchasePhase.loading)
                    const CircularProgressIndicator()
                  else ...<Widget>[
                    FilledButton(
                      key: const Key('buy-lifetime'),
                      onPressed: state.product == null || state.isBusy
                          ? null
                          : widget.controller.buy,
                      child: state.phase == LifetimePurchasePhase.purchasing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              price == null
                                  ? l10n.text('unlockLifetime')
                                  : l10n.unlockLifetimeFor(price),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('restore-purchase'),
                      onPressed: state.isBusy
                          ? null
                          : widget.controller.restore,
                      child: state.phase == LifetimePurchasePhase.restoring
                          ? Text(l10n.text('restoringPurchase'))
                          : Text(l10n.text('restorePurchase')),
                    ),
                  ],
                  if (_messageFor(context, state) case final String message) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        key: const Key('paywall-status'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('paywall-back'),
                    onPressed: state.isBusy ? null : widget.onBack,
                    child: Text(l10n.text('edit')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _messageFor(
    BuildContext context,
    LifetimePurchaseState state,
  ) {
    final PhotoCutLocalizations l10n = PhotoCutLocalizations.of(context);

    return switch (state.phase) {
      LifetimePurchasePhase.cancelled =>
        l10n.text('purchaseCancelled'),
      LifetimePurchasePhase.unavailable =>
        l10n.text('purchaseUnavailable'),
      LifetimePurchasePhase.error =>
        l10n.text('purchaseFailedTryAgain'),
      _ when state.errorCode == 'nothing_to_restore' =>
        l10n.text('nothingToRestore'),
      _ => null,
    };
  }
}
