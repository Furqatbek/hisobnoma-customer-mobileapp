import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/repositories.dart';

const _cartKey = 'hisobnoma-shop-cart-v1';
const _payKey = 'hisobnoma-shop-pay-method';
const _ordersKey = 'hisobnoma-shop-recent-orders';
const _lastPhoneKey = 'hisobnoma-shop-last-phone';

/// The client-side shopping cart plus the order-placement flow it feeds:
/// product cache, chosen payment method, the locally-remembered recent orders
/// (so guests can recover them), and persistence for all of it.
class CartController extends ChangeNotifier {
  CartController(this._prefs, this._catalog, this._orders) : cart = _loadCart(_prefs) {
    final pm = _prefs.getString(_payKey);
    if (paymentMethods.containsKey(pm)) payMethod = pm!;
    lastOrderPhone = _prefs.getString(_lastPhoneKey) ?? '';
    recentOrders = _loadRecentOrders(_prefs);
  }

  final SharedPreferences _prefs;
  final CatalogRepository _catalog;
  final OrderRepository _orders;

  final Map<int, num> cart; // catalogItemId -> qty (may be fractional)
  final Map<int, Product> productCache = {};

  /// Badge count: whole units summed, with each fractional (by-weight) line
  /// counted as one item so the badge stays a sensible integer.
  int get cartCount {
    num total = 0;
    cart.forEach((id, qty) {
      total += (productCache[id]?.fractional ?? false) ? 1 : qty;
    });
    return total.round();
  }

  /// Bumped on add-to-cart so the tab badge can bounce.
  int bounceToken = 0;

  /// Local 9-digit phone of the last placed order (prefills status lookup).
  /// Persisted so the prefill and guest pay-again survive an app restart.
  String lastOrderPhone = '';

  /// Locally-remembered placed orders (newest first), so guests can find and
  /// track them again after a restart. Capped at [_maxRecentOrders].
  List<LocalOrderRef> recentOrders = [];
  static const _maxRecentOrders = 10;

  /// Last chosen payment method (CASH | CARD) — the checkout default.
  String payMethod = 'CASH';

  // ── persistence ────────────────────────────────────────────
  static Map<int, num> _loadCart(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_cartKey);
      if (raw == null) return {};
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final clean = <int, num>{};
      obj.forEach((k, v) {
        final id = int.tryParse(k);
        final qty = v as num; // may be fractional (e.g. 0.5 kg)
        if (id != null && qty > 0) clean[id] = qty;
      });
      return clean;
    } catch (_) {
      return {};
    }
  }

  void _saveCart() =>
      _prefs.setString(_cartKey, jsonEncode(cart.map((k, v) => MapEntry('$k', v))));

  static List<LocalOrderRef> _loadRecentOrders(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_ordersKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => LocalOrderRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _saveRecentOrders() =>
      _prefs.setString(_ordersKey, jsonEncode(recentOrders.map((e) => e.toJson()).toList()));

  /// Flip a locally-remembered order to paid (after an online payment) so the
  /// recent-orders list reflects it without a server round-trip.
  void markLocalOrderPaid(String orderNumber) {
    final i = recentOrders.indexWhere((o) => o.orderNumber == orderNumber);
    if (i >= 0 && !recentOrders[i].paid) {
      recentOrders[i] = recentOrders[i].copyWith(paid: true);
      _saveRecentOrders();
      notifyListeners();
    }
  }

  // ── product cache ──────────────────────────────────────────
  void cacheProduct(Product p) => productCache[p.id] = p;

  /// Refresh every cart product from the server so the stock and prices shown
  /// in the cart are current — not whatever was cached when the item was added,
  /// which is how sold-out items used to slip through to checkout. A line is
  /// dropped only when its product 404s; transient errors keep the cached copy.
  Future<void> refreshCartProducts() async {
    for (final id in cart.keys.toList()) {
      try {
        productCache[id] = await _catalog.product(id);
      } on ApiException catch (e) {
        if (e.status == 404) productCache.remove(id);
      } catch (_) {/* keep any cached copy */}
    }
    cart.removeWhere((id, _) => !productCache.containsKey(id));
    _saveCart();
    notifyListeners();
  }

  /// Rounds to 0.001 so repeated fractional steps don't drift (0.1*3 == 0.3).
  static num _tidy(num n) => (n * 1000).round() / 1000;

  // ── cart mutations ─────────────────────────────────────────
  void addToCart(Product product) {
    cacheProduct(product);
    final next = (cart[product.id] ?? 0) + product.cartStep;
    cart[product.id] = product.fractional ? _tidy(next) : next;
    bounceToken++;
    _saveCart();
    notifyListeners();
  }

  void setQty(int id, num qty) {
    if (qty <= 0) {
      cart.remove(id);
    } else {
      cart[id] = qty;
    }
    _saveCart();
    notifyListeners();
  }

  // ── order placement ────────────────────────────────────────
  Future<Order> placeOrder({
    required String name,
    required String local9,
    int? regionId,
    int? villageId,
    String? address,
    String? note,
    String? couponCode,
    int? pointsToSpend,
    String paymentMethod = 'CASH',
  }) async {
    final order = await _orders.create(
      customerName: name,
      phoneE164: phoneToE164(local9),
      regionId: regionId,
      villageId: villageId,
      address: address,
      note: note,
      couponCode: couponCode,
      pointsToSpend: pointsToSpend,
      paymentMethod: paymentMethod,
      lines: Map<int, num>.from(cart),
    );
    lastOrderPhone = local9;
    _prefs.setString(_lastPhoneKey, local9);
    payMethod = paymentMethod; // remember as the next checkout's default
    _prefs.setString(_payKey, paymentMethod);
    // Remember the order locally so a guest can find it again after a restart.
    recentOrders.insert(
      0,
      LocalOrderRef(
        orderNumber: order.orderNumber,
        phone: local9,
        total: order.totalAmount,
        paymentMethod: order.paymentMethod.isNotEmpty ? order.paymentMethod : paymentMethod,
        paid: order.isPaid,
        createdAt: order.createdAt.isNotEmpty ? order.createdAt : DateTime.now().toIso8601String(),
      ),
    );
    if (recentOrders.length > _maxRecentOrders) {
      recentOrders = recentOrders.sublist(0, _maxRecentOrders);
    }
    _saveRecentOrders();
    cart.clear();
    _saveCart();
    notifyListeners();
    return order;
  }
}
