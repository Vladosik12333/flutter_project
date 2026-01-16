import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di.dart';
import 'core/router.dart';
import 'core/theme.dart';

import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDI();
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Because you registered providers with registerFactory in get_it,
        // getIt<ThemeProvider>() returns a fresh instance each time -> OK here.
        ChangeNotifierProvider(create: (_) => getIt<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<TransactionProvider>()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Personal Finance Tracker',
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
          );
        },
      ),
    );
  }
}
