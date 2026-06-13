import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/api/token_store.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/strings.dart';
import 'cart_controller.dart';
import 'nav_controller.dart';
import 'session_controller.dart';

// Re-export so the many `import '../state/app_state.dart'` consumers keep
// seeing ScreenSpec / NavMotion / NavController.
export 'nav_controller.dart';

const _langKey = 'hisobnoma-shop-lang';

/// App-wide facade over focused sub-controllers. It composes [NavController]
/// (navigation), [CartController] (cart + order placement) and
/// [SessionController] (session, wishlist, notifications), re-broadcasts their
/// changes, and owns only the cross-cutting bits left: language and the toast.
/// Screens keep talking to a single `AppState`; the delegating members below
/// forward to the right controller so call sites don't need to know the split.
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
    _session = SessionController(
      prefs: _prefs,
      tokens: _tokens,
      api: _api,
      auth: auth,
      wishlistApi: wishlistApi,
      notificationsApi: notificationsApi,
      deviceTokens: deviceTokens,
      toast: toast,
    );
    _nav.addListener(notifyListeners);
    _cart.addListener(notifyListeners);
    _session.addListener(notifyListeners);

    final l = _prefs.getString(_langKey);
    if (l == 'uz' || l == 'ru') {
      lang = l!;
      setUiLanguage(l);
    }
  }

  final SharedPreferences _prefs;
  final TokenStore _tokens;
  final ApiClient _api;

  late final NavController _nav;
  late final CartController _cart;
  late final SessionController _session;

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
    _session.dispose();
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

  // ── session / wishlist / notifications (delegates to SessionController) ──
  ShopUser? get user => _session.user;
  bool get isLoggedIn => _session.isLoggedIn;
  DateTime? get otpCooldownUntil => _session.otpCooldownUntil;
  int get otpCooldownRemaining => _session.otpCooldownRemaining;
  void startOtpCooldown([int seconds = 60]) => _session.startOtpCooldown(seconds);

  List<WishlistItem> get wishlistItems => _session.wishlistItems;
  set wishlistItems(List<WishlistItem> v) => _session.wishlistItems = v;
  Set<int> get wishlistIds => _session.wishlistIds;
  set wishlistIds(Set<int> v) => _session.wishlistIds = v;
  int get wishAlertCount => _session.wishAlertCount;
  bool isWished(int id) => _session.isWished(id);
  bool toggleWish(int id) => _session.toggleWish(id);
  Future<void> refreshWishlist() => _session.refreshWishlist();

  int get unreadCount => _session.unreadCount;
  Future<void> refreshUnread() => _session.refreshUnread();
  void noteRead() => _session.noteRead();
  Future<void> markAllNotificationsRead() => _session.markAllNotificationsRead();

  Future<void> bootstrap() => _session.bootstrap();
  Future<void> requestOtp(String local9) => _session.requestOtp(local9);
  Future<void> verifyOtp(String local9, String code, {String? name, String? referralCode}) =>
      _session.verifyOtp(local9, code, name: name, referralCode: referralCode);

  Future<void> logout() {
    _nav.resetMotion(); // drop any slide hint before the logged-out view shows
    return _session.logout();
  }

  // ── language ───────────────────────────────────────────────
  String lang = 'uz';

  void setLang(String l) {
    lang = l;
    setUiLanguage(l);
    _prefs.setString(_langKey, l);
    notifyListeners();
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
}
