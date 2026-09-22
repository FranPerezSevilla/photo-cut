import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:photo_cut/platform/purchase/purchase.dart';

void main() {
  test('reports an unavailable store without querying products', () async {
    final _FakeInAppPurchaseClient client = _FakeInAppPurchaseClient(
      available: false,
    );
    final InAppPurchaseGateway gateway = InAppPurchaseGateway(client: client);

    final PurchaseProductResult result = await gateway.loadProduct(
      'photo_cut_lifetime',
    );

    expect(result.storeAvailable, isFalse);
    expect(result.product, isNull);
    expect(client.queriedIds, isNull);
  });

  test('loads the lifetime product with the store-localized price', () async {
    final _FakeInAppPurchaseClient client = _FakeInAppPurchaseClient(
      productResponse: ProductDetailsResponse(
        productDetails: <ProductDetails>[
          _product(price: '3,99 €'),
        ],
        notFoundIDs: <String>[],
      ),
    );
    final InAppPurchaseGateway gateway = InAppPurchaseGateway(client: client);

    final PurchaseProductResult result = await gateway.loadProduct(
      'photo_cut_lifetime',
    );

    expect(result.storeAvailable, isTrue);
    expect(result.product?.id, 'photo_cut_lifetime');
    expect(result.product?.price, '3,99 €');
    expect(client.queriedIds, <String>{'photo_cut_lifetime'});
  });

  test('buys the product as a non-consumable', () async {
    final ProductDetails details = _product();
    final _FakeInAppPurchaseClient client = _FakeInAppPurchaseClient();
    final InAppPurchaseGateway gateway = InAppPurchaseGateway(client: client);

    await gateway.buyNonConsumable(
      PurchaseProduct(
        id: details.id,
        title: details.title,
        description: details.description,
        price: details.price,
        platformPayload: details,
      ),
    );

    expect(client.buyCalls, 1);
    expect(client.lastPurchaseParam?.productDetails, same(details));
  });

  test('maps pending, purchased, restored, cancelled and failed states', () async {
    final _FakeInAppPurchaseClient client = _FakeInAppPurchaseClient();
    final InAppPurchaseGateway gateway = InAppPurchaseGateway(client: client);

    final List<(PurchaseStatus, PurchaseUpdateStatus)> cases =
        <(PurchaseStatus, PurchaseUpdateStatus)>[
          (PurchaseStatus.pending, PurchaseUpdateStatus.pending),
          (PurchaseStatus.purchased, PurchaseUpdateStatus.purchased),
          (PurchaseStatus.restored, PurchaseUpdateStatus.restored),
          (PurchaseStatus.canceled, PurchaseUpdateStatus.cancelled),
          (PurchaseStatus.error, PurchaseUpdateStatus.failed),
        ];

    for (final (PurchaseStatus source, PurchaseUpdateStatus expected) in cases) {
      final Future<PurchaseUpdate> next = gateway.updates.first;
      final PurchaseDetails details = _purchase(source);
      if (source == PurchaseStatus.error) {
        details.error = IAPError(
          source: 'test',
          code: 'synthetic_error',
          message: 'Synthetic failure',
        );
      }
      client.emit(<PurchaseDetails>[details]);

      final PurchaseUpdate update = await next;
      expect(update.status, expected);
      if (source == PurchaseStatus.error) {
        expect(update.errorMessage, 'synthetic_error');
      }
    }
  });

  test('completes only the opaque purchase supplied by the store', () async {
    final _FakeInAppPurchaseClient client = _FakeInAppPurchaseClient();
    final InAppPurchaseGateway gateway = InAppPurchaseGateway(client: client);
    final PurchaseDetails purchase = _purchase(PurchaseStatus.purchased)
      ..pendingCompletePurchase = true;

    final Future<PurchaseUpdate> next = gateway.updates.first;
    client.emit(<PurchaseDetails>[purchase]);
    final PurchaseUpdate update = await next;

    expect(update.needsCompletion, isTrue);
    await gateway.completePurchase(update);

    expect(client.completed, same(purchase));
  });

  test('restores purchases through the store client', () async {
    final _FakeInAppPurchaseClient client = _FakeInAppPurchaseClient();
    final InAppPurchaseGateway gateway = InAppPurchaseGateway(client: client);

    await gateway.restorePurchases();

    expect(client.restoreCalls, 1);
  });
}

ProductDetails _product({String price = '€3.99'}) {
  return ProductDetails(
    id: 'photo_cut_lifetime',
    title: 'Photo Cut Lifetime',
    description: 'One-time unlock',
    price: price,
    rawPrice: 3.99,
    currencyCode: 'EUR',
    currencySymbol: '€',
  );
}

PurchaseDetails _purchase(PurchaseStatus status) {
  return PurchaseDetails(
    purchaseID: 'synthetic-id',
    productID: 'photo_cut_lifetime',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'synthetic-local',
      serverVerificationData: 'synthetic-server',
      source: 'test',
    ),
    transactionDate: '1',
    status: status,
  );
}

final class _FakeInAppPurchaseClient implements InAppPurchaseClient {
  _FakeInAppPurchaseClient({
    this.available = true,
    ProductDetailsResponse? productResponse,
  }) : productResponse =
           productResponse ??
           ProductDetailsResponse(
             productDetails: <ProductDetails>[],
             notFoundIDs: <String>[],
           );

  final bool available;
  final ProductDetailsResponse productResponse;
  final StreamController<List<PurchaseDetails>> _updates =
      StreamController<List<PurchaseDetails>>.broadcast();

  Set<String>? queriedIds;
  int buyCalls = 0;
  int restoreCalls = 0;
  PurchaseParam? lastPurchaseParam;
  PurchaseDetails? completed;

  void emit(List<PurchaseDetails> purchases) => _updates.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queriedIds = identifiers;
    return productResponse;
  }

  @override
  Future<bool> buyNonConsumable({
    required PurchaseParam purchaseParam,
  }) async {
    buyCalls += 1;
    lastPurchaseParam = purchaseParam;
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed = purchase;
  }
}
