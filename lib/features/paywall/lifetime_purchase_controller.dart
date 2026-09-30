import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:photo_cut/platform/purchase/purchase.dart';

enum OwnedPurchaseCheckResult { restored, notFound, unavailable }

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
  Completer<bool>? _restoreObservation;
  bool _subscribed = false;
  bool _initialized = false;
  bool _disposed = false;

  LifetimePurchaseState get state => _state;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _ensureSubscribed();

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
        phase: LifetimePurchasePhase.loading,
        product: result.product,
      ),
    );

    final OwnedPurchaseCheckResult restoreResult = await _restoreOwnedPurchase(
      busyPhase: LifetimePurchasePhase.loading,
      reportNothing: false,
      reportFailure: false,
    );
    if (_disposed ||
        restoreResult == OwnedPurchaseCheckResult.restored ||
        _state.phase == LifetimePurchasePhase.unlocked) {
      return;
    }

    if (_state.phase == LifetimePurchasePhase.loading) {
      _setState(
        _state.copyWith(
          phase: LifetimePurchasePhase.ready,
          clearError: true,
        ),
      );
    }
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
      final OwnedPurchaseCheckResult restoreResult =
          await _restoreOwnedPurchase(
            busyPhase: LifetimePurchasePhase.restoring,
            reportNothing: false,
            reportFailure: false,
          );
      if (_disposed ||
          restoreResult == OwnedPurchaseCheckResult.restored ||
          _state.phase == LifetimePurchasePhase.unlocked) {
        return;
      }
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

    await _restoreOwnedPurchase(
      busyPhase: LifetimePurchasePhase.restoring,
      reportNothing: true,
      reportFailure: true,
    );
  }

  Future<OwnedPurchaseCheckResult> checkOwnedPurchase() async {
    if (_disposed) {
      return OwnedPurchaseCheckResult.unavailable;
    }
    _ensureSubscribed();
    return _restoreOwnedPurchase(
      busyPhase: LifetimePurchasePhase.loading,
      reportNothing: false,
      reportFailure: false,
    );
  }

  Future<OwnedPurchaseCheckResult> _restoreOwnedPurchase({
    required LifetimePurchasePhase busyPhase,
    required bool reportNothing,
    required bool reportFailure,
  }) async {
    final Completer<bool> observation = Completer<bool>();
    _restoreObservation = observation;
    _setState(
      _state.copyWith(
        phase: busyPhase,
        clearError: true,
      ),
    );

    try {
      await gateway.restorePurchases();
      if (!observation.isCompleted) {
        await Future<void>.delayed(Duration.zero);
      }

      final bool purchaseObserved =
          observation.isCompleted ? await observation.future : false;
      if (_disposed ||
          purchaseObserved ||
          _state.phase == LifetimePurchasePhase.unlocked) {
        return OwnedPurchaseCheckResult.restored;
      }

      if (_state.phase == busyPhase) {
        if (reportNothing) {
          _setState(
            _state.copyWith(
              phase: _state.product == null
                  ? LifetimePurchasePhase.unavailable
                  : LifetimePurchasePhase.ready,
              errorCode: 'nothing_to_restore',
            ),
          );
        } else {
          _setState(
            _state.copyWith(
              phase: _state.product == null
                  ? LifetimePurchasePhase.unavailable
                  : LifetimePurchasePhase.ready,
              clearError: true,
            ),
          );
        }
      }
      return OwnedPurchaseCheckResult.notFound;
    } on Object {
      if (!_disposed && _state.phase != LifetimePurchasePhase.unlocked) {
        if (reportFailure) {
          _setState(
            _state.copyWith(
              phase: LifetimePurchasePhase.error,
              errorCode: 'restore_failed',
            ),
          );
        } else if (_state.phase == busyPhase) {
          _setState(
            _state.copyWith(
              phase: _state.product == null
                  ? LifetimePurchasePhase.unavailable
                  : LifetimePurchasePhase.ready,
              clearError: true,
            ),
          );
        }
      }
      return OwnedPurchaseCheckResult.unavailable;
    } finally {
      if (identical(_restoreObservation, observation)) {
        _restoreObservation = null;
      }
    }
  }

  void _ensureSubscribed() {
    if (_subscribed || _disposed) {
      return;
    }
    _subscribed = true;
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
  }

  Future<void> _handleUpdate(PurchaseUpdate update) async {
    if (update.productId != productId || _disposed) {
      return;
    }

    if (update.status == PurchaseUpdateStatus.purchased ||
        update.status == PurchaseUpdateStatus.restored) {
      final Completer<bool>? observation = _restoreObservation;
      if (observation != null && !observation.isCompleted) {
        observation.complete(true);
      }
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
    if (_subscribed) {
      unawaited(_subscription.cancel());
    }
    super.dispose();
  }
}
