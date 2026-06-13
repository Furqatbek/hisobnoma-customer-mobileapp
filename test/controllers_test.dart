import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/data/models.dart';
import 'package:hisobnoma_shop/data/repositories.dart';
import 'package:hisobnoma_shop/state/cart_controller.dart';
import 'package:hisobnoma_shop/state/nav_controller.dart';

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
  });
}
