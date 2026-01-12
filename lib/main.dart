import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di.dart';
import 'core/router.dart'; // ✅ appRouter burada
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
        ChangeNotifierProvider(create: (_) => getIt<ThemeProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<TransactionProvider>()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Personal Finance Tracker',
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter, // ✅ FIX: buildRouter yok, appRouter var
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
          );
        },
      ),
    );
  }
}
