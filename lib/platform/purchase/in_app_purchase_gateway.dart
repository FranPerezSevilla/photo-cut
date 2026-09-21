import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:photo_cut/platform/purchase/purchase_gateway.dart';

final class InAppPurchaseGateway implements PurchaseGateway {
  InAppPurchaseGateway({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  Stream<PurchaseUpdate> get updates {
    return _inAppPurchase.purchaseStream.expand<PurchaseUpdate>(
      (List<PurchaseDetails> purchases) => purchases.map(_mapPurchase),
    );
  }

  @override
  Future<PurchaseProductResult> loadProduct(String productId) async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        return const PurchaseProductResult(
          storeAvailable: false,
          errorMessage: 'store_unavailable',
        );
      }

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(<String>{productId});

      if (response.error != null) {
        return PurchaseProductResult(
          storeAvailable: true,
          errorMessage: response.error!.code,
        );
      }

      final ProductDetails? details = response.productDetails
          .where((ProductDetails item) => item.id == productId)
          .firstOrNull;

      if (details == null) {
        return PurchaseProductResult(
          storeAvailable: true,
          errorMessage: response.notFoundIDs.contains(productId)
              ? 'product_not_found'
              : 'product_unavailable',
        );
      }

      return PurchaseProductResult(
        storeAvailable: true,
        product: PurchaseProduct(
          id: details.id,
          title: details.title,
          description: details.description,
          price: details.price,
          platformPayload: details,
        ),
      );
    } on Object {
      return const PurchaseProductResult(
        storeAvailable: false,
        errorMessage: 'store_error',
      );
    }
  }

  @override
  Future<void> buyNonConsumable(PurchaseProduct product) async {
    final Object payload = product.platformPayload;
    if (payload is! ProductDetails) {
      throw StateError('Purchase product was not created by this gateway.');
    }

    await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: payload),
    );
  }

  @override
  Future<void> restorePurchases() => _inAppPurchase.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseUpdate update) async {
    if (!update.needsCompletion) {
      return;
    }

    final Object? payload = update.platformPayload;
    if (payload is! PurchaseDetails) {
      throw StateError('Purchase update was not created by this gateway.');
    }
    await _inAppPurchase.completePurchase(payload);
  }

  PurchaseUpdate _mapPurchase(PurchaseDetails details) {
    return PurchaseUpdate(
      productId: details.productID,
      status: switch (details.status) {
        PurchaseStatus.pending => PurchaseUpdateStatus.pending,
        PurchaseStatus.purchased => PurchaseUpdateStatus.purchased,
        PurchaseStatus.restored => PurchaseUpdateStatus.restored,
        PurchaseStatus.canceled => PurchaseUpdateStatus.cancelled,
        PurchaseStatus.error => PurchaseUpdateStatus.failed,
      },
      needsCompletion: details.pendingCompletePurchase,
      errorMessage: details.error?.code,
      platformPayload: details,
    );
  }
}
