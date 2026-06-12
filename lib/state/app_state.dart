import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/api/token_store.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/strings.dart';

/// A single entry on a tab's navigation stack.
class ScreenSpec {
  final String name;
  final int? productId;
  final String? orderNumber;
  final double? total;
  final String? payMethod;
  const ScreenSpec(this.name, {this.productId, this.orderNumber, this.total, this.payMethod});
}

enum NavMotion { push, pop, none }

const _cartKey = 'hisobnoma-shop-cart-v1';
const _langKey = 'hisobnoma-shop-lang';
const _payKey = 'hisobnoma-shop-pay-method';

/// Central app state: navigation, cart (client-side), the authenticated session,
/// the server-backed wishlist, and the repositories every screen talks to.
class AppState extends ChangeNotifier {
  AppState(this._prefs, this._tokens, this._api)
      : cart = _loadCart(_prefs),
        catalog = CatalogRepository(_api),
        delivery = DeliveryRepository(_api),
        cartApi = CartRepository(_api),
        orders = OrderRepository(_api),
        auth = AuthRepository(_api),
        loyalty = LoyaltyRepository(_api),
        wishlistApi = WishlistRepository(_api),
        referral = ReferralRepository(_api),
        notificationsApi = NotificationRepository(_api),
        couponsApi = CouponRepository(_api),
        deviceTokens = DeviceTokenRepository(_api) {
    final l = _prefs.getString(_langKey);
    if (l == 'uz' || l == 'ru') {
      lang = l!;
      gLang = l;
    }
    final pm = _prefs.getString(_payKey);
    if (paymentMethods.containsKey(pm)) payMethod = pm!;
    _api.onUnauthorized = _onUnauthorized;
  }

  final SharedPreferences _prefs;
  final TokenStore _tokens;
  final ApiClient _api;

  // repositories
  final CatalogRepository catalog;
  final DeliveryRepository delivery;
  final CartRepository cartApi;
  final OrderRepository orders;
  final AuthRepository auth;
  final LoyaltyRepository loyalty;
  final WishlistRepository wishlistApi;
  final ReferralRepository referral;
  final NotificationRepository notificationsApi;
  final CouponRepository couponsApi;
  final DeviceTokenRepository deviceTokens;

  // ── navigation ─────────────────────────────────────────────
  String tab = 'catalog';
  NavMotion motion = NavMotion.none;
  final Map<String, List<ScreenSpec>> stacks = {
    'catalog': [const ScreenSpec('catalog')],
    'cart': [const ScreenSpec('cart')],
    'wallet': [const ScreenSpec('wallet')],
    'wishlist': [const ScreenSpec('wishlist')],
    'profile': [const ScreenSpec('profile')],
  };
  List<ScreenSpec> get stack => stacks[tab]!;
  ScreenSpec get screen => stack.last;
  bool get showTabBar => stack.length == 1;

  // ── session ────────────────────────────────────────────────
  String lang = 'uz';
  ShopUser? user;
  bool get isLoggedIn => user != null;

  // ── cart (client-side) ─────────────────────────────────────
  final Map<int, int> cart; // catalogItemId -> qty
  final Map<int, Product> productCache = {};
  int get cartCount => cart.values.fold(0, (s, q) => s + q);

  /// Local 9-digit phone of the last placed order (prefills status lookup).
  String lastOrderPhone = '';

  /// Last chosen payment method (CASH | CARD) — the checkout default.
  String payMethod = 'CASH';

  // ── wishlist (server-backed) ───────────────────────────────
  List<WishlistItem> wishlistItems = [];
  Set<int> wishlistIds = {};
  int get wishAlertCount => wishlistItems.where((w) => w.priceDrop).length;
  bool isWished(int id) => wishlistIds.contains(id);

  // ── notifications ──────────────────────────────────────────
  int unreadCount = 0;

  Future<void> refreshUnread() async {
    if (!isLoggedIn) return;
    try {
      unreadCount = await notificationsApi.unreadCount();
      notifyListeners();
    } catch (_) {}
  }

  /// Locally decrement the badge when one notification is opened.
  void noteRead() {
    if (unreadCount > 0) {
      unreadCount--;
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    unreadCount = 0;
    notifyListeners();
    try {
      await notificationsApi.markAllRead();
    } catch (_) {}
  }

  // ── toast / badge bounce ───────────────────────────────────
  String toastMsg = '';
  bool toastShow = false;
  int _toastToken = 0;
  int bounceToken = 0;

  // ── bootstrap (restore session on launch) ──────────────────
  Future<void> bootstrap() async {
    try {
      user = await auth.me();
      await refreshWishlist();
      await refreshUnread();
    } catch (_) {
      user = null; // no/expired token
    }
    notifyListeners();
  }

  // ── persistence ────────────────────────────────────────────
  static Map<int, int> _loadCart(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_cartKey);
      if (raw == null) return {};
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final clean = <int, int>{};
      obj.forEach((k, v) {
        final id = int.tryParse(k);
        final qty = (v as num).toInt();
        if (id != null && qty > 0) clean[id] = qty;
      });
      return clean;
    } catch (_) {
      return {};
    }
  }

  void _saveCart() =>
      _prefs.setString(_cartKey, jsonEncode(cart.map((k, v) => MapEntry('$k', v))));

  // ── product cache ──────────────────────────────────────────
  void cacheProduct(Product p) => productCache[p.id] = p;

  /// Fetch any cart products not yet cached (e.g. after a cold start).
  Future<void> ensureCartProducts() async {
    final missing = cart.keys.where((id) => !productCache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    for (final id in missing) {
      try {
        productCache[id] = await catalog.product(id);
      } catch (_) {/* dropped below if still missing */}
    }
    // Drop cart lines whose product no longer exists.
    cart.removeWhere((id, _) => !productCache.containsKey(id));
    _saveCart();
    notifyListeners();
  }

  /// Public trigger for listeners (e.g. after a screen refreshes shared state).
  void notify() => notifyListeners();

  // ── toast ──────────────────────────────────────────────────
  void toast(String msg) {
    toastMsg = msg;
    toastShow = true;
    final token = ++_toastToken;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (token == _toastToken) {
        toastShow = false;
        notifyListeners();
      }
    });
  }

  // ── navigation ─────────────────────────────────────────────
  void setTab(String t) {
    motion = NavMotion.none;
    tab = t;
    notifyListeners();
  }

  void push(ScreenSpec s) {
    motion = NavMotion.push;
    stack.add(s);
    notifyListeners();
  }

  void pop() {
    motion = NavMotion.pop;
    if (stack.length > 1) stack.removeLast();
    notifyListeners();
  }

  void replace(ScreenSpec s) {
    motion = NavMotion.push;
    stacks[tab] = [ScreenSpec(stack.first.name), s];
    notifyListeners();
  }

  void resetCartStack() {
    motion = NavMotion.none;
    stacks['cart'] = [const ScreenSpec('cart')];
    notifyListeners();
  }

  // ── cart ───────────────────────────────────────────────────
  void addToCart(Product product) {
    cacheProduct(product);
    cart[product.id] = (cart[product.id] ?? 0) + 1;
    bounceToken++;
    _saveCart();
    notifyListeners();
  }

  void setQty(int id, int qty) {
    if (qty <= 0) {
      cart.remove(id);
    } else {
      cart[id] = qty;
    }
    _saveCart();
    notifyListeners();
  }

  // ── language ───────────────────────────────────────────────
  void setLang(String l) {
    lang = l;
    gLang = l;
    _prefs.setString(_langKey, l);
    notifyListeners();
  }

  // ── auth ───────────────────────────────────────────────────
  Future<void> requestOtp(String local9) => auth.requestOtp(phoneToE164(local9));

  Future<void> verifyOtp(String local9, String code, {String? name, String? referralCode}) async {
    final session = await auth.verify(phoneToE164(local9), code, name: name, referralCode: referralCode);
    await _tokens.save(session.token);
    // Pull the full profile (customerCode etc.); fall back to the verify payload.
    try {
      user = await auth.me();
    } catch (_) {
      user = ShopUser(phone: phoneFromE164(session.phone), name: session.name);
    }
    await refreshWishlist();
    await refreshUnread();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await deviceTokens.removeAll();
    } catch (_) {}
    await _tokens.clear();
    user = null;
    wishlistItems = [];
    wishlistIds = {};
    unreadCount = 0;
    motion = NavMotion.none;
    notifyListeners();
  }

  void _onUnauthorized() {
    _tokens.clear();
    user = null;
    wishlistItems = [];
    wishlistIds = {};
    unreadCount = 0;
    notifyListeners();
  }

  // ── wishlist (server) ──────────────────────────────────────
  Future<void> refreshWishlist() async {
    if (!isLoggedIn) return;
    try {
      final page = await wishlistApi.list(size: 50);
      wishlistItems = page.content;
      wishlistIds = wishlistItems.map((w) => w.catalogItemId).toSet();
    } catch (_) {}
  }

  /// Toggle a like. Returns false (and does nothing) when not logged in, so the
  /// caller can route to login — per the API contract.
  bool toggleWish(int id) {
    if (!isLoggedIn) return false;
    final wasWished = wishlistIds.contains(id);
    if (wasWished) {
      wishlistIds.remove(id);
      wishlistItems.removeWhere((w) => w.catalogItemId == id);
      toast(tr('Севимлилардан олиб ташланди'));
    } else {
      wishlistIds.add(id);
      toast(tr('Севимлиларга қўшилди'));
    }
    notifyListeners();
    () async {
      try {
        wasWished ? await wishlistApi.unlike(id) : await wishlistApi.like(id);
        await refreshWishlist();
        notifyListeners();
      } catch (_) {
        // revert on failure
        if (wasWished) {
          wishlistIds.add(id);
        } else {
          wishlistIds.remove(id);
        }
        notifyListeners();
      }
    }();
    return true;
  }

  // ── orders ─────────────────────────────────────────────────
  Future<Order> placeOrder({
    required String name,
    required String local9,
    int? regionId,
    int? villageId,
    String? note,
    String paymentMethod = 'CASH',
  }) async {
    final order = await orders.create(
      customerName: name,
      phoneE164: phoneToE164(local9),
      regionId: regionId,
      villageId: villageId,
      note: note,
      paymentMethod: paymentMethod,
      lines: Map<int, int>.from(cart),
    );
    lastOrderPhone = local9;
    payMethod = paymentMethod; // remember as the next checkout's default
    _prefs.setString(_payKey, paymentMethod);
    cart.clear();
    _saveCart();
    notifyListeners();
    return order;
  }
}
