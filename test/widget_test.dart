import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/screens/account.dart';
import 'package:hisobnoma_shop/screens/catalog.dart';
import 'package:hisobnoma_shop/state/app_state.dart';
import 'package:hisobnoma_shop/shell/shell.dart';

Future<AppState> _bootShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore();
  final app = AppState(prefs, tokens, ApiClient(tokens));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: const MaterialApp(home: Scaffold(body: ShopShell())),
    ),
  );
  return app;
}

void main() {
  testWidgets('App boots into the catalog tab', (tester) async {
    final app = await _bootShell(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Каталог'), findsWidgets);
    expect(app.tab, 'catalog');
  });

  testWidgets('tab root survives a push/pop (state preserved)', (tester) async {
    final app = await _bootShell(tester);
    await tester.pumpAndSettle();

    final before = tester.state(find.byType(CatalogScreen));

    app.push(const ScreenSpec('login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    // The catalog root stays mounted (offstage) behind the pushed screen.
    expect(find.byType(CatalogScreen, skipOffstage: false), findsOneWidget);

    app.pop();
    await tester.pumpAndSettle();
    final after = tester.state(find.byType(CatalogScreen));
    expect(identical(before, after), isTrue, reason: 'catalog State should not be recreated on pop');
  });
}
