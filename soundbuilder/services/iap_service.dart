import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  // Product IDs MUST match App Store Connect / Play Console
  static const monthlyId  = 'crinkle_premium_monthly';
  static const yearlyId   = 'crinkle_premium_yearly';
  static const lifetimeId = 'crinkle_premium_lifetime';
  static const _prefsKeyIsPremium = 'sb_is_premium';

  final InAppPurchase _iap = InAppPurchase.instance;

  // Expose premium everywhere via ValueNotifier
  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  // Store availability, products, and purchase UI state
  final ValueNotifier<bool> storeAvailable = ValueNotifier(false);
  final ValueNotifier<List<ProductDetails>> products = ValueNotifier([]);
  final ValueNotifier<bool> purchasePending = ValueNotifier(false);
  final ValueNotifier<String?> purchaseError = ValueNotifier(null);

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> init() async {
    // Load entitlement from disk first (instant UI)
    final prefs = await SharedPreferences.getInstance();
    isPremium.value = prefs.getBool(_prefsKeyIsPremium) ?? false;

    // Connect to store
    storeAvailable.value = await _iap.isAvailable();
    if (!storeAvailable.value) return;

    _sub = _iap.purchaseStream.listen(_onPurchaseUpdates, onError: (e) {
      purchaseError.value = e.toString();
      purchasePending.value = false;
    });

    await _queryProducts();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<void> _queryProducts() async {
    const ids = {monthlyId, yearlyId, lifetimeId};
    final resp = await _iap.queryProductDetails(ids);
    if (resp.error != null) {
      purchaseError.value = resp.error!.message;
    }
    products.value = resp.productDetails;
  }

  /// Return null if not found.
  ProductDetails? find(String id) {
    for (final p in products.value) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> buy(ProductDetails product) async {
    purchaseError.value = null;
    purchasePending.value = true;
    final param = PurchaseParam(productDetails: product);

    // Subscriptions & non-consumables both use buyNonConsumable here.
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    purchaseError.value = null;
    purchasePending.value = true;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          purchasePending.value = true;
          break;

        case PurchaseStatus.error:
          purchasePending.value = false;
          purchaseError.value = p.error?.message ?? 'Purchase failed';
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;

        case PurchaseStatus.canceled:
          purchasePending.value = false;
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _verifyWithServer(p);
          if (ok) {
            await _grantPremium();
          } else {
            purchaseError.value = 'Verification failed';
          }
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          purchasePending.value = false;
          break;
      }
    }
  }

  // MVP: trust the store (ok for dev); Production: verify server-side.
  Future<bool> _verifyWithServer(PurchaseDetails p) async {
    // Send p.verificationData.serverVerificationData to your backend and
    // verify with Apple/Google APIs. Return true/false accordingly.
    return true;
  }

  Future<void> _grantPremium() async {
    isPremium.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyIsPremium, true);
  }

  // Optional: call on sign-out to clear local state (server still the source)
  Future<void> clearLocalEntitlement() async {
    isPremium.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyIsPremium, false);
  }
}