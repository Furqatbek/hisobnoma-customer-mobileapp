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
