import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Handles the one-time "Pro" unlock (removes ads).
///
/// Store setup required before this works:
///   • App Store Connect & Google Play Console: create a **non-consumable**
///     in-app product with ID [proProductId].
/// Until that product exists, [isAvailable]/[price] stay null and the Settings
/// UI simply hides the buy button.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// Product ID — must match the ID configured in the stores.
  static const String proProductId = 'cleanpics_pro';

  /// Planned price, shown before the store product loads (or until it's
  /// configured). Set the real price when you create the product in the stores.
  static const String plannedProPrice = '\$1.99';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _proProduct;
  bool _available = false;

  bool get isAvailable => _available && _proProduct != null;

  /// Localized price string (e.g. "$3.99"), or null if not loaded.
  String? get price => _proProduct?.price;

  /// Localized store price when available, otherwise the planned price.
  String get displayPrice => price ?? plannedProPrice;

  /// [onPurchased] fires when Pro is unlocked via purchase or restore.
  Future<void> init({required void Function() onPurchased}) async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    final resp = await _iap.queryProductDetails({proProductId});
    if (resp.productDetails.isNotEmpty) {
      _proProduct = resp.productDetails.first;
    }

    _sub = _iap.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        if (p.productID == proProductId &&
            (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored)) {
          onPurchased();
        }
        if (p.pendingCompletePurchase) {
          _iap.completePurchase(p);
        }
      }
    });
  }

  /// Start the buy flow. No-op if the product isn't available.
  Future<void> buyPro() async {
    final product = _proProduct;
    if (product == null) return;
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Restore a previous purchase (e.g. on a new device).
  Future<void> restore() async => _iap.restorePurchases();

  void dispose() => _sub?.cancel();
}
