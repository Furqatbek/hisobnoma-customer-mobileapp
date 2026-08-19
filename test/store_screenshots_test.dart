// Generates Google Play screenshots (phone / 7" / 10") from the real screens
// with seeded data. Skipped in normal runs; regenerate with:
//   flutter test --dart-define=STORE_SHOTS=true test/store_screenshots_test.dart
// Outputs land in assets/store/screenshots/.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/data/models.dart';
import 'package:hisobnoma_shop/screens/cart.dart';
import 'package:hisobnoma_shop/screens/catalog.dart';
import 'package:hisobnoma_shop/screens/extras.dart';
import 'package:hisobnoma_shop/state/app_state.dart';
import 'package:hisobnoma_shop/widgets/components.dart';

import 'support/fake_adapter.dart';

const _pimg = 'test/support/store_fixtures';

// ── Product fixtures ─────────────────────────────────────────────────────────
Map<String, dynamic> _p(int id, String name, num price, String unit, String img,
        {num? sale, String? label, bool fractional = false, num step = 1, String cat = 'Шағал'}) =>
    {
      'id': id,
      'name': name,
      'shortDescription': '',
      'description':
          'Юқори сифатли, ГОСТ талабларига мос маҳсулот. Тошкент шаҳри ва вилояти бўйлаб yetkazib берамиз. Ҳажмли буюртмаларга чегирма.',
      'price': price,
      'salePrice': ?sale,
      'promotionLabel': ?label,
      'categoryId': cat == 'Шағал' ? 1 : (cat == 'Қум' ? 2 : 3),
      'categoryName': cat,
      'brandName': 'Temur MCHJ',
      'unitName': unit,
      'inStock': true,
      'fractional': fractional,
      'step': step,
      'imageUrl': '/uploads/pimg/$img',
    };

final _products = [
  _p(1, 'Шағал 5-20 мм', 180000, 'тонна', 'shagal520.jpg', fractional: true, step: 0.5),
  _p(2, 'Шағал 20-40 мм', 170000, 'тонна', 'shagal2040.jpg',
      sale: 153000, label: '-10%', fractional: true, step: 0.5),
  _p(3, 'Дарё қуми', 120000, 'тонна', 'qum.jpg', fractional: true, step: 0.5, cat: 'Қум'),
  _p(4, 'Цемент М-400, 50 кг', 42000, 'қоп', 'cement.jpg', cat: 'Цемент'),
  _p(5, 'Клинец 10-20 мм', 175000, 'тонна', 'klinets.jpg', fractional: true, step: 0.5),
  _p(6, 'Отсев (майда шағал)', 90000, 'тонна', 'otsev.jpg', fractional: true, step: 0.5),
];

ResponseBody _route(RequestOptions o) {
  final path = o.path;
  if (path.contains('/catalog/categories')) {
    return jsonBody({
      'success': true,
      'data': [
        {'id': 1, 'name': 'Шағал'},
        {'id': 2, 'name': 'Қум'},
        {'id': 3, 'name': 'Цемент'},
      ]
    }, 200);
  }
  final detail = RegExp(r'/catalog/products/(\d+)$').firstMatch(path);
  if (detail != null) {
    final id = int.parse(detail.group(1)!);
    return jsonBody({'success': true, 'data': _products.firstWhere((p) => p['id'] == id)}, 200);
  }
  if (path.contains('/catalog/products')) {
    return jsonBody({
      'success': true,
      'data': {
        'content': _products,
        'page': {'number': 0, 'size': 20, 'totalElements': 6, 'totalPages': 1}
      }
    }, 200);
  }
  if (path.contains('/cart/price')) {
    return jsonBody({
      'success': true,
      'data': {
        'subtotal': 558000,
        'discountTotal': 18000,
        'total': 540000,
        'appliedPromotions': ['SHAGAL10']
      }
    }, 200);
  }
  if (path.contains('/delivery/regions')) {
    return jsonBody({
      'success': true,
      'data': [
        {'id': 1, 'name': 'Зангиота тумани', 'deliveryFee': 30000},
        {'id': 2, 'name': 'Сергели тумани', 'deliveryFee': 25000},
        {'id': 3, 'name': 'Қибрай тумани', 'deliveryFee': 35000},
      ]
    }, 200);
  }
  if (path.contains('/delivery/villages')) {
    return jsonBody({
      'success': true,
      'data': [
        {'id': 11, 'name': 'Эшонгузар', 'regionId': 1},
        {'id': 12, 'name': 'Хонобод', 'regionId': 1},
      ]
    }, 200);
  }
  if (path.contains('/me/loyalty')) {
    return jsonBody({
      'success': true,
      'data': {
        'balance': 25000,
        'enabled': true,
        'minRedeem': 1000,
        'maxRedeemPercent': 50,
        'entries': [
          {'id': 1, 'type': 'EARN', 'amount': 3750, 'orderNumber': 'WO-000127', 'createdAt': '2026-08-17T10:00:00Z'},
          {'id': 2, 'type': 'EARN', 'amount': 2100, 'orderNumber': 'WO-000121', 'createdAt': '2026-08-12T10:00:00Z'},
          {'id': 3, 'type': 'SPEND', 'amount': -5000, 'note': 'Харидда ишлатилди', 'createdAt': '2026-08-10T10:00:00Z'},
        ]
      }
    }, 200);
  }
  return jsonBody({'success': true, 'data': {}}, 200);
}

// ── Mock HttpClient so Image.network serves our product photos ──────────────
final Map<String, Uint8List> _imageBytes = {};

class _ImgClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImgRequest(url);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImgRequest implements HttpClientRequest {
  final Uri uri0;
  _ImgRequest(this.uri0);
  @override
  Future<HttpClientResponse> close() async {
    final name = uri0.pathSegments.last;
    final bytes = _imageBytes[name] ?? Uint8List(0);
    return _ImgResponse(bytes, bytes.isEmpty ? 404 : 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImgResponse implements HttpClientResponse {
  final Uint8List bytes;
  @override
  final int statusCode;
  _ImgResponse(this.bytes, this.statusCode);
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.fromIterable(<List<int>>[bytes])
          .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ── Harness ──────────────────────────────────────────────────────────────────
Future<void> _loadFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  await inter.load();
  final mono = FontLoader('RobotoMono')
    ..addFont(rootBundle.load('assets/fonts/RobotoMono-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/RobotoMono-Medium.ttf'));
  await mono.load();
}

Future<AppState> _app({bool loggedIn = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final app = AppState(prefs, TokenStore(), ApiClient(TokenStore(), adapter: FakeAdapter(_route)));
  if (loggedIn) {
    app.debugUser = const ShopUser(
        phone: '901234567', name: 'Темур', customerCode: 'WC-00042', tenantSlug: 'temur');
  }
  return app;
}

Product _prod(int id) => Product.fromJson(_products.firstWhere((p) => p['id'] == id));

Widget _wrap(AppState app, Widget child) => ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.white, fontFamily: 'Inter', useMaterial3: true),
        home: Scaffold(
            backgroundColor: Colors.white,
            body: RepaintBoundary(key: const ValueKey('shot'), child: child)),
      ),
    );

Future<void> _precache(WidgetTester tester, List<String> names) async {
  final ctx = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    for (final n in names) {
      try {
        await precacheImage(NetworkImage('https://temurmchj.uz/uploads/pimg/$n'), ctx);
      } catch (_) {}
    }
  });
  await tester.pumpAndSettle();
}

const _allImgs = ['shagal520.jpg', 'shagal2040.jpg', 'qum.jpg', 'cement.jpg', 'klinets.jpg', 'otsev.jpg'];


Future<void> _shoot(WidgetTester tester, String dir, String name, double dpr) async {
  final boundary =
      tester.element(find.byKey(const ValueKey('shot'))).findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: dpr);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/store/screenshots/$dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    for (final n in _allImgs) {
      _imageBytes[n] = File('$_pimg/$n').readAsBytesSync();
    }
  });
  final configs = <(String, double, double, double, bool)>[
    ('phone', 360, 640, 3.0, true), // 1080×1920, full set
    ('tablet7', 576, 1024, 2.0, false), // 1152×2048
    ('tablet10', 720, 1280, 2.0, false), // 1440×2560
  ];

  for (final (tag, w, h, dpr, fullSet) in configs) {
    testWidgets('store screenshots — $tag',
        skip: !const bool.fromEnvironment('STORE_SHOTS'), (tester) async {
      // Must be reset before the body returns (framework invariant), hence
      // the try/finally rather than setUp/tearDown.
      debugNetworkImageHttpClientProvider = () => _ImgClient();
      try {
      await _loadFonts();
      tester.view.physicalSize = Size(w * dpr, h * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);

      // 01 — catalog
      var app = await _app();
      await tester.pumpWidget(_wrap(app, CatalogScreen(app: app)));
      await tester.pumpAndSettle();
      await _precache(tester, _allImgs);
      await _shoot(tester, tag, '01_catalog', dpr);

      // 02 — product detail
      app = await _app();
      await tester.pumpWidget(_wrap(app, ProductDetailScreen(app: app, productId: 1)));
      await tester.pumpAndSettle();
      await _precache(tester, ['shagal520.jpg']);
      await _shoot(tester, tag, '02_product', dpr);

      // 03 — cart (fractional gravel + cement + sand)
      app = await _app();
      app.setTab('cart');
      app.cacheProduct(_prod(1));
      app.cacheProduct(_prod(4));
      app.cacheProduct(_prod(3));
      app.setQty(1, 1.5);
      app.setQty(4, 4);
      app.setQty(3, 1);
      await tester.pumpWidget(_wrap(app, CartScreen(app: app)));
      await tester.pumpAndSettle();
      await _precache(tester, ['shagal520.jpg', 'cement.jpg', 'qum.jpg']);
      await _shoot(tester, tag, '03_cart', dpr);

      // 04 — checkout, filled
      app = await _app(loggedIn: true);
      app.cacheProduct(_prod(1));
      app.cacheProduct(_prod(4));
      app.cacheProduct(_prod(3));
      app.setQty(1, 1.5);
      app.setQty(4, 4);
      app.setQty(3, 1);
      await tester.pumpWidget(_wrap(app, CheckoutScreen(app: app)));
      await tester.pumpAndSettle();
      // Short address (no field scroll), then name/phone; region last.
      await tester.enterText(
          find.descendant(of: find.byType(ShopTextField), matching: find.byType(TextField)).at(1),
          'Сергели, Янги ҳаёт 12');
      await tester.enterText(
          find.descendant(of: find.byType(ShopTextField), matching: find.byType(TextField)).at(0),
          'Темур Алиев');
      await tester.enterText(
          find.descendant(of: find.byType(PhoneField), matching: find.byType(TextField)).first,
          '901234567');
      // Pick the delivery region from the dropdown (scroll it into view first).
      await tester.ensureVisible(find.text('Туман'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Туман'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Зангиота тумани').last);
      await tester.pumpAndSettle();
      tester.binding.focusManager.primaryFocus?.unfocus(); // hide the caret
      await tester.pumpAndSettle();
      await _shoot(tester, tag, '04_checkout', dpr);

      if (!fullSet) return; // finally below still resets the provider

      // 05 — order success (phone only)
      app = await _app();
      await tester.pumpWidget(_wrap(
          app,
          OrderSuccessScreen(
              app: app, orderNumber: 'WO-000128', total: 570000, payMethod: 'CASH')));
      await tester.pumpAndSettle();
      await _shoot(tester, tag, '05_success', dpr);

      // 06 — wallet with QR + cashback ledger (phone only)
      app = await _app(loggedIn: true);
      await tester.pumpWidget(_wrap(app, WalletScreen(app: app)));
      await tester.pumpAndSettle();
      await _shoot(tester, tag, '06_wallet', dpr);
      } finally {
        debugNetworkImageHttpClientProvider = null;
      }
    });
  }
}
