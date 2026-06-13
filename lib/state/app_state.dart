import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/api/token_store.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/strings.dart';
import 'cart_controller.dart';
import 'nav_controller.dart';

// Re-export so the many `import '../state/app_state.dart'` consumers keep
// seeing ScreenSpec / NavMotion / NavController.
export 'nav_controller.dart';

const _langKey = 'hisobnoma-shop-lang';
const _otpUntilKey = 'hisobnoma-shop-otp-until';

/// App-wide facade over focused sub-controllers. It composes [NavController]
/// (navigation) and [CartController] (cart + order placement), re-broadcasts
/// their changes, and owns what's left: the authenticated session, the
/// server-backed wishlist, notifications, language and the toast. Screens keep
/// talking to a single `AppState`; the delegating members below forward to the
/// right controller so call sites don't need to know the split.
class AppState extends ChangeNotifier {
  AppState(this._prefs, this._tokens, this._api)
      : catalog = CatalogRepository(_api),
        delivery = DeliveryRepository(_api),
        cartApi = CartRepository(_api),
        orders = OrderRepository(_api),
        payments = PaymentRepository(_api),
        auth = AuthRepository(_api),
        loyalty = LoyaltyRepository(_api),
        wishlistApi = WishlistRepository(_api),
        referral = ReferralRepository(_api),
        notificationsApi = NotificationRepository(_api),
        couponsApi = CouponRepository(_api),
        deviceTokens = DeviceTokenRepository(_api) {
    _nav = NavController();
    _cart = CartController(_prefs, catalog, orders);
    _nav.addListener(notifyListeners);
    _cart.addListener(notifyListeners);

    final l = _prefs.getString(_langKey);
    if (l == 'uz' || l == 'ru') {
      lang = l!;
      gLang = l;
    }
    final until = _prefs.getInt(_otpUntilKey);
    if (until != null) otpCooldownUntil = DateTime.fromMillisecondsSinceEpoch(until);
    _api.onUnauthorized = _onUnauthorized;
  }

  final SharedPreferences _prefs;
  final TokenStore _tokens;
  final ApiClient _api;

  late final NavController _nav;
  late final CartController _cart;

  // repositories
  final CatalogRepository catalog;
  final DeliveryRepository delivery;
  final CartRepository cartApi;
  final OrderRepository orders;
  final PaymentRepository payments;
  final AuthRepository auth;
  final LoyaltyRepository loyalty;
  final WishlistRepository wishlistApi;
  final ReferralRepository referral;
  final NotificationRepository notificationsApi;
  final CouponRepository couponsApi;
  final DeviceTokenRepository deviceTokens;

  @override
  void dispose() {
    _nav.dispose();
    _cart.dispose();
    super.dispose();
  }

  // ── navigation (delegates to NavController) ────────────────
  String get tab => _nav.tab;
  NavMotion get motion => _nav.motion;
  Map<String, List<ScreenSpec>> get stacks => _nav.stacks;
  List<ScreenSpec> get stack => _nav.stack;
  ScreenSpec get screen => _nav.screen;
  bool get showTabBar => _nav.showTabBar;
  void setTab(String t) => _nav.setTab(t);
  void push(ScreenSpec s) => _nav.push(s);
  void pop() => _nav.pop();
  void replace(ScreenSpec s) => _nav.replace(s);
  void resetCartStack() => _nav.resetCartStack();

  // ── cart + orders (delegates to CartController) ────────────
  Map<int, int> get cart => _cart.cart;
  Map<int, Product> get productCache => _cart.productCache;
  int get cartCount => _cart.cartCount;
  int get bounceToken => _cart.bounceToken;
  List<LocalOrderRef> get recentOrders => _cart.recentOrders;
  String get lastOrderPhone => _cart.lastOrderPhone;
  set lastOrderPhone(String v) => _cart.lastOrderPhone = v;
  String get payMethod => _cart.payMethod;
  void cacheProduct(Product p) => _cart.cacheProduct(p);
  void addToCart(Product product) => _cart.addToCart(product);
  void setQty(int id, int qty) => _cart.setQty(id, qty);
  Future<void> refreshCartProducts() => _cart.refreshCartProducts();
  void markLocalOrderPaid(String orderNumber) => _cart.markLocalOrderPaid(orderNumber);
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
  }) =>
      _cart.placeOrder(
        name: name,
        local9: local9,
        regionId: regionId,
        villageId: villageId,
        address: address,
        note: note,
        couponCode: couponCode,
        pointsToSpend: pointsToSpend,
        paymentMethod: paymentMethod,
      );

  // ── session ────────────────────────────────────────────────
  String lang = 'uz';
  ShopUser? user;
  bool get isLoggedIn => user != null;

  /// When the OTP-resend throttle expires. Held here (and persisted) rather
  /// than in the login screen's state, so leaving and re-opening login can't
  /// reset the client-side cooldown.
  DateTime? otpCooldownUntil;
  int get otpCooldownRemaining {
    final u = otpCooldownUntil;
    if (u == null) return 0;
    final s = u.difference(DateTime.now()).inMilliseconds / 1000;
    return s <= 0 ? 0 : s.ceil();
  }

  void startOtpCooldown([int seconds = 60]) {
    otpCooldownUntil = DateTime.now().add(Duration(seconds: seconds));
    _prefs.setInt(_otpUntilKey, otpCooldownUntil!.millisecondsSinceEpoch);
    notifyListeners();
  }

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

  // ── toast ──────────────────────────────────────────────────
  String toastMsg = '';
  bool toastShow = false;
  int _toastToken = 0;

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

  /// Public trigger for listeners (e.g. after a screen refreshes shared state).
  void notify() => notifyListeners();

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

  // ── language ───────────────────────────────────────────────
  void setLang(String l) {
    lang = l;
    gLang = l;
    _prefs.setString(_langKey, l);
    notifyListeners();
  }

  // ── auth ───────────────────────────────────────────────────
  Future<void> requestOtp(String local9) async {
    await auth.requestOtp(phoneToE164(local9));
    startOtpCooldown(); // throttle survives screen re-entry / restart
  }

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
    _nav.resetMotion();
    notifyListeners();
  }

  void _onUnauthorized() {
    final wasLoggedIn = user != null;
    _tokens.clear();
    user = null;
    wishlistItems = [];
    wishlistIds = {};
    unreadCount = 0;
    // Explain the drop — but only if we thought we were logged in, so a stale
    // token at cold start doesn't toast on every launch.
    if (wasLoggedIn) {
      toast(tr2('Сессия тугади. Қайта киринг.', 'Сессия истекла. Войдите снова.'));
    }
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
}
