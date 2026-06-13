import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/api_config.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/data/models.dart';
import 'package:hisobnoma_shop/data/strings.dart';
import 'package:hisobnoma_shop/screens/account.dart';
import 'package:hisobnoma_shop/screens/cart.dart';
import 'package:hisobnoma_shop/screens/payment.dart';
import 'package:hisobnoma_shop/state/app_state.dart';

Future<AppState> _app() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return AppState(prefs, TokenStore(), ApiClient(TokenStore()));
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Order _order({String method = 'CARD', String pay = '', String status = 'NEW'}) => Order(
      orderNumber: 'WO-000001',
      status: status,
      deliveryFee: 0,
      discountTotal: 0,
      couponDiscount: 0,
      pointsSpent: 0,
      totalAmount: 33000,
      paymentMethod: method,
      paymentStatus: pay,
      createdAt: '2026-06-12T10:00:00Z',
      lines: const [
        OrderLine(productName: 'Маҳсулот', quantity: 1, unitPrice: 33000, lineTotal: 33000),
      ],
    );

void main() {
  group('Order payment model', () {
    test('parses payment fields defensively (case, absence)', () {
      final o = Order.fromJson({
        'orderNumber': 'WO-1',
        'paymentMethod': 'card',
        'paymentStatus': 'paid',
      });
      expect(o.paymentMethod, 'CARD');
      expect(o.isPaid, true);

      final legacy = Order.fromJson({'orderNumber': 'WO-2'});
      expect(legacy.paymentMethod, '');
      expect(legacy.paymentStatus, '');
      expect(legacy.awaitingPayment, false);
    });

    test('awaitingPayment only for active unpaid card orders', () {
      expect(_order(pay: 'PENDING').awaitingPayment, true);
      expect(_order(pay: 'NONE').awaitingPayment, true);
      expect(_order(pay: 'FAILED', status: 'CONFIRMED').awaitingPayment, true);
      expect(_order(pay: 'PAID').awaitingPayment, false);
      expect(_order(pay: 'REFUNDED').awaitingPayment, false);
      expect(_order(pay: '').awaitingPayment, false); // unknown → no pay button
      expect(_order(pay: 'PENDING', status: 'CANCELLED').awaitingPayment, false);
      expect(_order(pay: 'PENDING', status: 'COMPLETED').awaitingPayment, false);
      expect(_order(method: 'CASH', pay: 'PENDING').awaitingPayment, false);
    });

    test('OrderPayment parses url fallback and terminal states', () {
      final p = OrderPayment.fromJson({'status': 'pending', 'url': 'https://x/pay'});
      expect(p.paymentUrl, 'https://x/pay');
      expect(p.isPaid, false);
      expect(OrderPayment.fromJson({'status': 'PAID'}).isPaid, true);
      expect(OrderPayment.fromJson({'status': 'CANCELLED'}).isFailed, true);
    });

    test('payment labels all have ru translations', () {
      for (final m in paymentMethods.values) {
        expect(kRuDict[m.label], isNotNull, reason: m.label);
        expect(kRuDict[m.hint], isNotNull, reason: m.hint);
      }
      for (final m in paymentStatusMeta.values) {
        expect(kRuDict[m.label], isNotNull, reason: m.label);
      }
    });
  });

  group('Payment URL safety (#9)', () {
    test('only https provider URLs are allowed', () {
      expect(ApiConfig.isAllowedPaymentUrl('https://checkout.paycom.uz/abc'), true);
      expect(ApiConfig.isAllowedPaymentUrl('http://checkout.paycom.uz/abc'), false);
      expect(ApiConfig.isAllowedPaymentUrl('payme://pay?x=1'), false);
      expect(ApiConfig.isAllowedPaymentUrl('intent://scan#Intent;end'), false);
      expect(ApiConfig.isAllowedPaymentUrl('javascript:alert(1)'), false);
      expect(ApiConfig.isAllowedPaymentUrl('not a url'), false);
      expect(ApiConfig.isAllowedPaymentUrl(''), false);
    });

    test('default build (no host allowlist) requires only https + a host', () {
      expect(ApiConfig.paymentHostAllowlist, '');
      expect(ApiConfig.isAllowedPaymentUrl('https://any-provider.example/pay'), true);
      expect(ApiConfig.isAllowedPaymentUrl('https://'), false); // no host
    });
  });

  group('Local order recovery', () {
    test('LocalOrderRef round-trips through json and copyWith', () {
      const ref = LocalOrderRef(
        orderNumber: 'WO-1',
        phone: '901234567',
        total: 33000,
        paymentMethod: 'CARD',
        paid: false,
        createdAt: '2026-06-12T10:00:00Z',
      );
      final back = LocalOrderRef.fromJson(ref.toJson());
      expect(back.orderNumber, 'WO-1');
      expect(back.phone, '901234567');
      expect(back.total, 33000);
      expect(back.paymentMethod, 'CARD');
      expect(back.paid, false);
      expect(ref.copyWith(paid: true).paid, true);
    });

    test('recent orders + last phone persist across AppState instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a1 = AppState(prefs, TokenStore(), ApiClient(TokenStore()));
      a1.recentOrders.insert(
        0,
        const LocalOrderRef(
          orderNumber: 'WO-9',
          phone: '901112233',
          total: 50000,
          paymentMethod: 'CARD',
          paid: false,
          createdAt: '2026-06-12T10:00:00Z',
        ),
      );
      a1.markLocalOrderPaid('WO-9'); // persists
      await prefs.setString('hisobnoma-shop-last-phone', '901112233');

      // A fresh instance (app restart) reads them back.
      final a2 = AppState(prefs, TokenStore(), ApiClient(TokenStore()));
      expect(a2.lastOrderPhone, '901112233');
      expect(a2.recentOrders.single.orderNumber, 'WO-9');
      expect(a2.recentOrders.single.paid, true);
    });
  });

  group('Checkout payment section', () {
    testWidgets('offers cash and card; selection updates the summary', (tester) async {
      // Tall surface so the lazy ListView builds the summary card too.
      tester.view.physicalSize = const Size(390 * 3, 1500 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final app = await _app();
      await tester.pumpWidget(_wrap(CheckoutScreen(app: app)));
      await tester.pumpAndSettle();

      // Option title + summary row both show the selected method (cash default).
      expect(find.text('Нақд пул'), findsNWidgets(2));
      expect(find.text('Карта орқали'), findsOneWidget);

      await tester.tap(find.text('Карта орқали'));
      await tester.pumpAndSettle();
      expect(find.text('Карта орқали'), findsNWidgets(2));
      expect(find.text('Нақд пул'), findsOneWidget);
    });
  });

  group('Cashback redemption math', () {
    LoyaltyData ld({required double balance, double minRedeem = 0, int pct = 50, bool enabled = true}) =>
        LoyaltyData(balance: balance, enabled: enabled, minRedeem: minRedeem, maxRedeemPercent: pct, entries: const []);

    test('capped by percent of goods', () => expect(ld(balance: 100000).maxRedeemable(40000), 20000));
    test('capped by balance', () => expect(ld(balance: 5000).maxRedeemable(40000), 5000));
    test('below minRedeem yields zero',
        () => expect(ld(balance: 3000, minRedeem: 5000, pct: 100).maxRedeemable(40000), 0));
    test('disabled yields zero', () => expect(ld(balance: 100000, enabled: false).maxRedeemable(40000), 0));
    test('floored to a whole sum',
        () => expect(ld(balance: 1234.9, pct: 100).maxRedeemable(100000), 1234));
  });

  group('OTP cooldown (#13)', () {
    test('cooldown is held in state and survives a fresh AppState (restart)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a1 = AppState(prefs, TokenStore(), ApiClient(TokenStore()));
      expect(a1.otpCooldownRemaining, 0);
      a1.startOtpCooldown(60);
      expect(a1.otpCooldownRemaining, greaterThan(55));

      // New instance (screen re-entry / app restart) still sees the throttle.
      final a2 = AppState(prefs, TokenStore(), ApiClient(TokenStore()));
      expect(a2.otpCooldownRemaining, greaterThan(0));
    });

    test('remaining is zero once the deadline passes', () async {
      SharedPreferences.setMockInitialValues({
        'hisobnoma-shop-otp-until':
            DateTime.now().subtract(const Duration(seconds: 1)).millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();
      final app = AppState(prefs, TokenStore(), ApiClient(TokenStore()));
      expect(app.otpCooldownRemaining, 0);
    });
  });

  group('Checkout integrity', () {
    testWidgets('blocks submit and surfaces address + region-load errors', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final app = await _app();
      await tester.pumpWidget(_wrap(CheckoutScreen(app: app)));
      await tester.pumpAndSettle(); // regions fetch fails (no backend)

      // #14: the region load failure is surfaced with a retry, not swallowed.
      expect(find.text('Туманларни юклаб бўлмади'), findsOneWidget);

      await tester.tap(find.text('Буюртмани юбориш'));
      await tester.pumpAndSettle();
      expect(find.text('Манзилни киритинг'), findsOneWidget); // address required
      expect(app.screen.name, isNot('success')); // submit blocked
    });

    testWidgets('sold-out cart item blocks ordering', (tester) async {
      SharedPreferences.setMockInitialValues({'hisobnoma-shop-cart-v1': '{"1":1}'});
      final prefs = await SharedPreferences.getInstance();
      final app = AppState(prefs, TokenStore(), ApiClient(TokenStore()));
      app.setTab('cart');
      app.cacheProduct(const Product(
        id: 1,
        name: 'Музлатилган гўшт',
        shortDescription: '',
        description: '',
        basePrice: 50000,
        categoryId: 1,
        categoryName: '',
        unitName: 'кг',
        inStock: false,
      ));

      await tester.pumpWidget(_wrap(CartScreen(app: app)));
      await tester.pumpAndSettle(); // background refresh fails, keeps cached OOS copy
      expect(find.text('Тугаган маҳсулотни ўчиринг'), findsOneWidget);

      await tester.tap(find.text('Буюртма бериш'));
      expect(app.stack.length, 1); // disabled — did not push checkout
    });
  });

  group('Order card payment states', () {
    testWidgets('unpaid card order: pill + working pay button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
          OrderCard(order: _order(pay: 'PENDING'), onPay: () => tapped = true)));
      expect(find.text('Тўланмаган'), findsOneWidget);
      await tester.tap(find.text('Тўлаш'));
      expect(tapped, true);
    });

    testWidgets('paid order: paid pill, no pay button', (tester) async {
      await tester.pumpWidget(
          _wrap(OrderCard(order: _order(pay: 'PAID', status: 'CONFIRMED'), onPay: () {})));
      expect(find.text('Тўланган'), findsOneWidget);
      expect(find.text('Тўлаш'), findsNothing);
    });

    testWidgets('refunded cancelled order: refunded pill, no pay button', (tester) async {
      await tester.pumpWidget(
          _wrap(OrderCard(order: _order(pay: 'REFUNDED', status: 'CANCELLED'), onPay: () {})));
      expect(find.text('Қайтарилган'), findsOneWidget);
      expect(find.text('Тўлаш'), findsNothing);
    });

    testWidgets('legacy order without payment fields: no payment row', (tester) async {
      await tester.pumpWidget(_wrap(OrderCard(order: _order(method: '', pay: ''), onPay: () {})));
      expect(find.text('Тўлов'), findsNothing);
      expect(find.text('Тўлаш'), findsNothing);
    });
  });

  group('Payment screen navigation', () {
    testWidgets('pay later from the checkout flow lands on success', (tester) async {
      final app = await _app();
      app.setTab('cart');
      app.push(const ScreenSpec('checkout'));
      app.replace(const ScreenSpec('payment', orderNumber: 'WO-000001', total: 33000));

      await tester.pumpWidget(
          _wrap(PaymentScreen(app: app, orderNumber: 'WO-000001', total: 33000)));
      await tester.tap(find.text('Кейинроқ тўлайман'));
      expect(app.screen.name, 'success');
      expect(app.screen.paid, isNot(true));
    });

    testWidgets('pay later from pay-again (history) pops back', (tester) async {
      final app = await _app();
      app.setTab('profile');
      app.push(const ScreenSpec('payment', orderNumber: 'WO-000001', total: 33000));

      await tester.pumpWidget(
          _wrap(PaymentScreen(app: app, orderNumber: 'WO-000001', total: 33000)));
      await tester.tap(find.text('Кейинроқ тўлайман'));
      expect(app.screen.name, 'profile');
      expect(app.stack.length, 1);
    });
  });

  group('Success screen payment state', () {
    testWidgets('unpaid card order hides Тўлаш while online payment is disabled',
        (tester) async {
      // Default build: ONLINE_PAYMENT is off, so card means pay-on-delivery
      // and the success screen must not offer an online "Тўлаш" that can't work.
      expect(ApiConfig.onlinePaymentEnabled, false);
      final app = await _app();
      await tester.pumpWidget(_wrap(OrderSuccessScreen(
          app: app, orderNumber: 'WO-000001', total: 33000, payMethod: 'CARD')));
      await tester.pumpAndSettle();
      expect(find.text('Тўлаш'), findsNothing);
      expect(find.textContaining('Карта орқали'), findsOneWidget);
    });

    testWidgets('paid card order shows the badge and no pay button', (tester) async {
      final app = await _app();
      await tester.pumpWidget(_wrap(OrderSuccessScreen(
          app: app, orderNumber: 'WO-000001', total: 33000, payMethod: 'CARD', paid: true)));
      await tester.pumpAndSettle();
      expect(find.text('Тўланган'), findsOneWidget);
      expect(find.text('Тўлаш'), findsNothing);
    });

    testWidgets('cash order shows neither', (tester) async {
      final app = await _app();
      await tester.pumpWidget(_wrap(OrderSuccessScreen(
          app: app, orderNumber: 'WO-000001', total: 33000, payMethod: 'CASH')));
      await tester.pumpAndSettle();
      expect(find.text('Тўлаш'), findsNothing);
      expect(find.text('Тўланган'), findsNothing);
    });
  });
}
