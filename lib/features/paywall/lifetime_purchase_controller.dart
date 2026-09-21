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
    required PurchaseGateway gateway,
    required Future<void> Function(bool unlocked) setLifetimeUnlocked,
    this.productId = 'photo_cut_lifetime',
  }) : _gateway = gateway,
       _setLifetimeUnlocked = setLifetimeUnlocked;

  final PurchaseGateway _gateway;
  final Future<void> Function(bool unlocked) _setLifetimeUnlocked;
  final String productId;

  LifetimePurchaseState _state = const LifetimePurchaseState();
  StreamSubscription<PurchaseUpdate>? _subscription;
  bool _initialized = false;
  bool _disposed = false;

  LifetimePurchaseState get state => _state;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _subscription = _gateway.updates.listen(
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
    final PurchaseProductResult result = await _gateway.loadProduct(productId);
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
      await _gateway.buyNonConsumable(product);
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
      await _gateway.restorePurchases();
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
      case PurchaseUpdateStatus.cancelled:
        _setState(
          _state.copyWith(
            phase: LifetimePurchasePhase.cancelled,
            clearError: true,
          ),
        );
      case PurchaseUpdateStatus.failed:
        _setState(
          _state.copyWith(
            phase: LifetimePurchasePhase.error,
            errorCode: update.errorMessage ?? 'purchase_failed',
          ),
        );
      case PurchaseUpdateStatus.purchased:
      case PurchaseUpdateStatus.restored:
        try {
          await _setLifetimeUnlocked(true);
          await _gateway.completePurchase(update);
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
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
