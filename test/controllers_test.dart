import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/data/models.dart';
import 'package:hisobnoma_shop/data/repositories.dart';
import 'package:hisobnoma_shop/state/cart_controller.dart';
import 'package:hisobnoma_shop/state/nav_controller.dart';
import 'package:hisobnoma_shop/state/session_controller.dart';

import 'support/fake_adapter.dart';

Product _p(int id) => Product(
      id: id,
      name: 'P$id',
      shortDescription: '',
      description: '',
      basePrice: 1000,
      categoryId: 1,
      categoryName: '',
      unitName: '',
      inStock: true,
    );

Future<CartController> _cart() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(TokenStore());
  return CartController(prefs, CatalogRepository(api), OrderRepository(api));
}

void main() {
  // TokenStore uses flutter_secure_storage, which needs a bound test
  // environment and a stubbed platform channel.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => call.method == 'readAll' ? <String, String>{} : null,
    );
  });

  group('NavController', () {
    test('push/pop/replace/setTab track motion and stack', () {
      final n = NavController();
      expect(n.showTabBar, true);

      n.push(const ScreenSpec('product', productId: 1));
      expect(n.screen.name, 'product');
      expect(n.motion, NavMotion.push);
      expect(n.showTabBar, false);

      n.pop();
      expect(n.screen.name, 'catalog');
      expect(n.motion, NavMotion.pop);

      n.setTab('cart');
      expect(n.tab, 'cart');
      expect(n.motion, NavMotion.none);

      n.replace(const ScreenSpec('success', orderNumber: 'WO-1', total: 1));
      expect(n.stack.length, 2);
      expect(n.screen.name, 'success');
    });

    test('each tab keeps its own stack', () {
      final n = NavController();
      n.setTab('catalog');
      n.push(const ScreenSpec('product', productId: 9));
      n.setTab('profile');
      expect(n.screen.name, 'profile'); // profile root, untouched
      n.setTab('catalog');
      expect(n.screen.name, 'product'); // catalog remembered its push
    });
  });

  group('CartController', () {
    test('addToCart increments qty + bounce; setQty(0) removes', () async {
      final c = await _cart();
      c.addToCart(_p(1));
      c.addToCart(_p(1));
      expect(c.cart[1], 2);
      expect(c.cartCount, 2);
      expect(c.bounceToken, 2);
      expect(c.productCache.containsKey(1), true);
      c.setQty(1, 0);
      expect(c.cart.containsKey(1), false);
    });

    test('cart persists across controller instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final api = ApiClient(TokenStore());
      CartController make() => CartController(prefs, CatalogRepository(api), OrderRepository(api));

      make().addToCart(_p(7));
      expect(make().cart[7], 1); // a fresh instance reloads it
    });

    test('fractional product steps by its step and counts as one item', () async {
      final c = await _cart();
      const meat = Product(
        id: 5,
        name: 'Гўшт',
        shortDescription: '',
        description: '',
        basePrice: 80000,
        categoryId: 1,
        categoryName: '',
        unitName: 'кг',
        inStock: true,
        fractional: true,
        step: 0.5,
      );
      c.addToCart(meat);
      expect(c.cart[5], 0.5);
      c.addToCart(meat);
      expect(c.cart[5], 1.0);
      expect(c.cartCount, 1); // a by-weight line counts as one item
      c.setQty(5, 0);
      expect(c.cart.containsKey(5), false);
    });

    test('Product parses fractional + step (defaults to whole units)', () {
      final f = Product.fromJson({'id': 1, 'name': 'x', 'fractional': true, 'step': 0.25});
      expect(f.fractional, true);
      expect(f.cartStep, 0.25);
      final w = Product.fromJson({'id': 2, 'name': 'y'});
      expect(w.fractional, false);
      expect(w.cartStep, 1);
    });
  });

  group('SessionController', () {
    SessionController make(SharedPreferences prefs, {void Function(String)? toast}) {
      final api = ApiClient(TokenStore());
      return SessionController(
        prefs: prefs,
        tokens: TokenStore(),
        api: api,
        auth: AuthRepository(api),
        wishlistApi: WishlistRepository(api),
        notificationsApi: NotificationRepository(api),
        deviceTokens: DeviceTokenRepository(api),
        toast: toast ?? (_) {},
      );
    }

    test('toggleWish is a no-op (no toast) when logged out', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var toasts = 0;
      final s = make(prefs, toast: (_) => toasts++);
      expect(s.toggleWish(1), false);
      expect(s.isWished(1), false);
      expect(toasts, 0);
    });

    test('deleteAccount clears the session; a refusal keeps it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      SessionController withApi(ApiClient api) => SessionController(
            prefs: prefs,
            tokens: TokenStore(),
            api: api,
            auth: AuthRepository(api),
            wishlistApi: WishlistRepository(api),
            notificationsApi: NotificationRepository(api),
            deviceTokens: DeviceTokenRepository(api),
            toast: (_) {},
          );

      // Success → local session wiped.
      final ok = withApi(ApiClient(TokenStore(),
          adapter: FakeAdapter((_) => jsonBody({'success': true}, 200))));
      ok.user = const ShopUser(phone: '901234567', name: 'Ali');
      await ok.deleteAccount();
      expect(ok.user, isNull);
      expect(ok.isLoggedIn, false);

      // 409 → throws, session untouched so the user can finish the order.
      final blocked = withApi(ApiClient(TokenStore(),
          adapter: FakeAdapter((_) => jsonBody({
                'success': false,
                'error': {'code': 'ACCOUNT_HAS_ACTIVE_ORDERS', 'message': 'Фаол буюртма'}
              }, 409))));
      blocked.user = const ShopUser(phone: '901234567', name: 'Ali');
      await expectLater(blocked.deleteAccount(), throwsA(isA<ApiException>()));
      expect(blocked.isLoggedIn, true);
    });

    test('OTP cooldown persists across controller instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      make(prefs).startOtpCooldown(60);
      expect(make(prefs).otpCooldownRemaining, greaterThan(0));
    });
  });
}
