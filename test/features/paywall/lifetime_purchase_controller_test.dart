import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_cut/features/paywall/paywall.dart';
import 'package:photo_cut/platform/purchase/purchase.dart';

void main() {
  test('loads the configured lifetime product', () async {
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (_) async {},
    );

    await controller.initialize();

    expect(controller.state.phase, LifetimePurchasePhase.ready);
    expect(controller.state.product?.id, 'photo_cut_lifetime');
    expect(controller.state.product?.price, '3,99 €');
    expect(gateway.loadedProductId, 'photo_cut_lifetime');
    controller.dispose();
  });


  test('pending purchase keeps the paywall busy without unlocking', () async {
    int unlockCalls = 0;
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (_) async {
        unlockCalls += 1;
      },
    );
    await controller.initialize();

    gateway.emit(
      const PurchaseUpdate(
        productId: 'photo_cut_lifetime',
        status: PurchaseUpdateStatus.pending,
        needsCompletion: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.phase, LifetimePurchasePhase.purchasing);
    expect(controller.state.isBusy, isTrue);
    expect(unlockCalls, 0);
    controller.dispose();
  });

  test('purchase unlocks before completing the store transaction', () async {
    final List<String> order = <String>[];
    final _FakePurchaseGateway gateway = _FakePurchaseGateway(
      completionOrder: order,
    );
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (bool unlocked) async {
        expect(unlocked, isTrue);
        order.add('unlock');
      },
    );
    await controller.initialize();

    final Completer<void> unlocked = Completer<void>();
    controller.addListener(() {
      if (controller.state.phase == LifetimePurchasePhase.unlocked &&
          !unlocked.isCompleted) {
        unlocked.complete();
      }
    });

    await controller.buy();
    gateway.emit(
      const PurchaseUpdate(
        productId: 'photo_cut_lifetime',
        status: PurchaseUpdateStatus.purchased,
        needsCompletion: true,
        platformPayload: 'opaque',
      ),
    );
    await unlocked.future;

    expect(order, <String>['unlock', 'complete']);
    expect(gateway.buyCalls, 1);
    controller.dispose();
  });

  test('restored purchase grants lifetime access', () async {
    bool lifetimeUnlocked = false;
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (bool unlocked) async {
        lifetimeUnlocked = unlocked;
      },
    );
    await controller.initialize();

    final Completer<void> restored = Completer<void>();
    controller.addListener(() {
      if (controller.state.phase == LifetimePurchasePhase.unlocked &&
          !restored.isCompleted) {
        restored.complete();
      }
    });

    gateway.onRestore = () {
      gateway.emit(
        const PurchaseUpdate(
          productId: 'photo_cut_lifetime',
          status: PurchaseUpdateStatus.restored,
          needsCompletion: true,
          platformPayload: 'opaque',
        ),
      );
    };

    await controller.restore();
    await restored.future;

    expect(lifetimeUnlocked, isTrue);
    expect(gateway.restoreCalls, 1);
    expect(gateway.completeCalls, 1);
    controller.dispose();
  });

  test('cancelled purchase leaves entitlement unchanged', () async {
    int unlockCalls = 0;
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (_) async {
        unlockCalls += 1;
      },
    );
    await controller.initialize();

    gateway.emit(
      const PurchaseUpdate(
        productId: 'photo_cut_lifetime',
        status: PurchaseUpdateStatus.cancelled,
        needsCompletion: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.phase, LifetimePurchasePhase.cancelled);
    expect(unlockCalls, 0);
    controller.dispose();
  });

  test('failed purchase is recoverable and does not unlock', () async {
    int unlockCalls = 0;
    final _FakePurchaseGateway gateway = _FakePurchaseGateway();
    final LifetimePurchaseController controller = LifetimePurchaseController(
      gateway: gateway,
      entitlementWriter: (_) async {
        unlockCalls += 1;
      },
    );
    await controller.initialize();

    gateway.emit(
      const PurchaseUpdate(
        productId: 'photo_cut_lifetime',
        status: PurchaseUpdateStatus.failed,
        needsCompletion: false,
        errorMessage: 'billing_error',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.phase, LifetimePurchasePhase.error);
    expect(controller.state.errorCode, 'billing_error');
    expect(unlockCalls, 0);
    controller.dispose();
  });
}

final class _FakePurchaseGateway implements PurchaseGateway {
  _FakePurchaseGateway({this.completionOrder});

  final List<String>? completionOrder;
  final StreamController<PurchaseUpdate> _updates =
      StreamController<PurchaseUpdate>.broadcast();

  final PurchaseProduct product = PurchaseProduct(
    id: 'photo_cut_lifetime',
    title: 'Photo Cut Lifetime',
    description: 'One-time unlock',
    price: '3,99 €',
    platformPayload: Object(),
  );

  String? loadedProductId;
  int buyCalls = 0;
  int restoreCalls = 0;
  int completeCalls = 0;
  void Function()? onRestore;

  void emit(PurchaseUpdate update) => _updates.add(update);

  @override
  Stream<PurchaseUpdate> get updates => _updates.stream;

  @override
  Future<PurchaseProductResult> loadProduct(String productId) async {
    loadedProductId = productId;
    return PurchaseProductResult(
      storeAvailable: true,
      product: product,
    );
  }

  @override
  Future<void> buyNonConsumable(PurchaseProduct product) async {
    buyCalls += 1;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
    onRestore?.call();
  }

  @override
  Future<void> completePurchase(PurchaseUpdate update) async {
    completeCalls += 1;
    completionOrder?.add('complete');
  }
}
