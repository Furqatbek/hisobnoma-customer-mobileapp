import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/api/api_client.dart';
import 'data/api/token_store.dart';
import 'state/app_state.dart';
import 'theme/tokens.dart';
import 'shell/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore();
  await tokens.load(); // make the JWT available to the request interceptor
  final api = ApiClient(tokens);
  final app = AppState(prefs, tokens, api);
  app.bootstrap(); // restore the session in the background

  runApp(
    ChangeNotifierProvider.value(
      value: app,
      child: const HisobnomaApp(),
    ),
  );
}

class HisobnomaApp extends StatelessWidget {
  const HisobnomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sheben N1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: kFontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: AppColors.bg,
        body: ShopShell(),
      ),
    );
  }
}
