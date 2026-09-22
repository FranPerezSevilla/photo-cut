enum PurchaseUpdateStatus {
  pending,
  purchased,
  restored,
  cancelled,
  failed,
}

final class PurchaseProduct {
  const PurchaseProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.platformPayload,
  });

  final String id;
  final String title;
  final String description;
  final String price;

  /// Opaque store object. Features must never inspect, persist or log it.
  final Object platformPayload;
}

final class PurchaseUpdate {
  const PurchaseUpdate({
    required this.productId,
    required this.status,
    required this.needsCompletion,
    this.errorMessage,
    this.platformPayload,
  });

  final String productId;
  final PurchaseUpdateStatus status;
  final bool needsCompletion;
  final String? errorMessage;

  /// Opaque transaction object. Features must only pass it back to the gateway.
  final Object? platformPayload;
}

final class PurchaseProductResult {
  const PurchaseProductResult({
    required this.storeAvailable,
    this.product,
    this.errorMessage,
  });

  final bool storeAvailable;
  final PurchaseProduct? product;
  final String? errorMessage;
}

abstract interface class PurchaseGateway {
  Stream<PurchaseUpdate> get updates;

  Future<PurchaseProductResult> loadProduct(String productId);

  Future<void> buyNonConsumable(PurchaseProduct product);

  Future<void> restorePurchases();

  Future<void> completePurchase(PurchaseUpdate update);
}
