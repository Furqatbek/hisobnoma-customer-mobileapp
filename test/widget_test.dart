import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hisobnoma_shop/data/api/api_client.dart';
import 'package:hisobnoma_shop/data/api/token_store.dart';
import 'package:hisobnoma_shop/state/app_state.dart';
import 'package:hisobnoma_shop/shell/shell.dart';

void main() {
  testWidgets('App boots into the catalog tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = TokenStore();
    final api = ApiClient(tokens);
    final app = AppState(prefs, tokens, api);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: Scaffold(body: ShopShell())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Каталог'), findsWidgets);
  });
}
