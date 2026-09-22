# ADR-013 — Lifetime purchase through the official Flutter store API

- Status: Accepted
- Date: 2026-09-21

## Context

Photo Cut needs one permanent unlock after the single free final PDF. The product
must remain account-free and backend-free while supporting Android and iOS,
localized store pricing, cancellation and restoration.

## Decision

Use Flutter's official `in_app_purchase` package at exactly version `3.3.1`.

- Publisher: `flutter.dev`
- License: BSD-3-Clause
- Android support: SDK 24+
- iOS support: 13.0+; Photo Cut already targets iOS 15+
- Product ID: `photo_cut_lifetime`
- Product type: non-consumable / one-time purchase
- Package boundary: `lib/platform/purchase/`

All plugin types remain behind `PurchaseGateway`. Feature code receives only an
app-owned product model containing the localized display price and app-owned
purchase-state events. Purchase tokens, verification payloads and receipts are
never logged or persisted by Photo Cut.

The paywall:
- states explicitly that the unlock is a one-time purchase with no subscription;
- displays the localized price returned by the store rather than a hard-coded
  price;
- exposes Restore purchase;
- handles pending, purchased, restored, cancelled and failed states.

For a purchased or restored `photo_cut_lifetime`, Photo Cut first persists the
lifetime entitlement and only then calls `completePurchase` when the store marks
the transaction as requiring completion. This prevents a completed transaction
from racing ahead of entitlement delivery.

The platform store remains the authority for restoration. M4-H01 performs the
real sandbox purchase/restore tests on Android and iPhone.

## Purchase verification scope

The official plugin exposes local/server verification data and recommends server
verification for stronger fraud resistance. Photo Cut deliberately has no user
account or backend in the MVP. This task therefore trusts a successful store
purchase/restoration event for the exact configured product ID and keeps that
limitation explicit. Adding server-side receipt verification would require a
separate product/architecture decision.

## Consequences

- Store configuration is required before a real purchase can succeed.
- CI tests the gateway and paywall with fakes and proves Android/iOS compilation.
- A real store account/device remains a human validation gate.
- The purchase dependency and its lockfile are versioned with the app.
