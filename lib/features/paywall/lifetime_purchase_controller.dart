import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:photo_cut/platform/purchase/purchase.dart';

enum LifetimePurchasePhase {
  idle,
  loading,
  ready,
  purchasing,
  restoring,
  cancelled,
  unavailable,
  error,
  unlocked,
}

@immutable
final class LifetimePurchaseState {
  const LifetimePurchaseState({
    this.phase = LifetimePurchasePhase.idle,
    this.product,
    this.errorCode,
  });

  final LifetimePurchasePhase phase;
  final PurchaseProduct? product;
  final String? errorCode;

  bool get isBusy =>
      phase == LifetimePurchasePhase.loading ||
      phase == LifetimePurchasePhase.purchasing ||
      phase == LifetimePurchasePhase.restoring;

  LifetimePurchaseState copyWith({
    LifetimePurchasePhase? phase,
    PurchaseProduct? product,
    String? errorCode,
    bool clearError = false,
  }) {
    return LifetimePurchaseState(
      phase: phase ?? this.phase,
      product: product ?? this.product,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}

final class LifetimePurchaseController extends ChangeNotifier {
  LifetimePurchaseController({
    required this.gateway,
    required this.entitlementWriter,
    this.productId = 'photo_cut_lifetime',
  });

  final PurchaseGateway gateway;
  final Future<void> Function(bool unlocked) entitlementWriter;
  final String productId;

  LifetimePurchaseState _state = const LifetimePurchaseState();
  late final StreamSubscription<PurchaseUpdate> _subscription;
  bool _initialized = false;
  bool _disposed = false;

  LifetimePurchaseState get state => _state;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _subscription = gateway.updates.listen(
      _handleUpdate,
      onError: (_) {
        _setState(
          _state.copyWith(
            phase: LifetimePurchasePhase.error,
            errorCode: 'purchase_stream_error',
          ),
        );
      },
    );

    _setState(_state.copyWith(phase: LifetimePurchasePhase.loading));
    final PurchaseProductResult result = await gateway.loadProduct(productId);
    if (_disposed) {
      return;
    }

    if (!result.storeAvailable) {
      _setState(
        _state.copyWith(
          phase: LifetimePurchasePhase.unavailable,
          errorCode: result.errorMessage ?? 'store_unavailable',
        ),
      );
      return;
    }

    if (result.product == null) {
      _setState(
        _state.copyWith(
          phase: LifetimePurchasePhase.unavailable,
          errorCode: result.errorMessage ?? 'product_unavailable',
        ),
      );
      return;
    }

    _setState(
      LifetimePurchaseState(
        phase: LifetimePurchasePhase.ready,
        product: result.product,
      ),
    );
  }

  Future<void> buy() async {
    final PurchaseProduct? product = _state.product;
    if (product == null || _state.isBusy) {
      return;
    }

    _setState(
      _state.copyWith(
        phase: LifetimePurchasePhase.purchasing,
        clearError: true,
      ),
    );

    try {
      await gateway.buyNonConsumable(product);
    } on Object {
      _setState(
        _state.copyWith(
          phase: LifetimePurchasePhase.error,
          errorCode: 'purchase_launch_failed',
        ),
      );
    }
  }

  Future<void> restore() async {
    if (_state.isBusy) {
      return;
    }

    _setState(
      _state.copyWith(
        phase: LifetimePurchasePhase.restoring,
        clearError: true,
      ),
    );

    try {
      await gateway.restorePurchases();
      if (_state.phase == LifetimePurchasePhase.restoring) {
        _setState(
          _state.copyWith(
            phase: _state.product == null
                ? LifetimePurchasePhase.unavailable
                : LifetimePurchasePhase.ready,
            errorCode: 'nothing_to_restore',
          ),
        );
      }
    } on Object {
      _setState(
        _state.copyWith(
          phase: LifetimePurchasePhase.error,
          errorCode: 'restore_failed',
        ),
      );
    }
  }

  Future<void> _handleUpdate(PurchaseUpdate update) async {
    if (update.productId != productId || _disposed) {
      return;
    }

    switch (update.status) {
      case PurchaseUpdateStatus.pending:
        _setState(
          _state.copyWith(
            phase: LifetimePurchasePhase.purchasing,
            clearError: true,
          ),
        );
        return;
      case PurchaseUpdateStatus.cancelled:
        _setState(
          _state.copyWith(
            phase: LifetimePurchasePhase.cancelled,
            clearError: true,
          ),
        );
        return;
      case PurchaseUpdateStatus.failed:
        _setState(
          _state.copyWith(
            phase: LifetimePurchasePhase.error,
            errorCode: update.errorMessage ?? 'purchase_failed',
          ),
        );
        return;
      case PurchaseUpdateStatus.purchased:
      case PurchaseUpdateStatus.restored:
        try {
          await entitlementWriter(true);
          try {
            await gateway.completePurchase(update);
          } on Object {
            await entitlementWriter(false);
            rethrow;
          }
          _setState(
            _state.copyWith(
              phase: LifetimePurchasePhase.unlocked,
              clearError: true,
            ),
          );
        } on Object {
          _setState(
            _state.copyWith(
              phase: LifetimePurchasePhase.error,
              errorCode: 'purchase_delivery_failed',
            ),
          );
        }
        return;
    }
  }

  void _setState(LifetimePurchaseState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_initialized) {
      unawaited(_subscription.cancel());
    }
    super.dispose();
  }
}
