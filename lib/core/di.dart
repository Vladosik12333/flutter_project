import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../db/app_database.dart';
import '../db/transactions_dao.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../repositories/finance_repository.dart';
import '../services/api_service.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  // Dio
  getIt.registerLazySingleton<Dio>(() => Dio());

  // Services
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<Dio>()));

  // DB
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // ✅ DAO
  getIt.registerLazySingleton<TransactionsDao>(
    () => TransactionsDao(getIt<AppDatabase>()),
  );

  // ✅ Repository uses DAO + DB + API
  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepository(
      dao: getIt<TransactionsDao>(),
      db: getIt<AppDatabase>(),
      apiService: getIt<ApiService>(),
    ),
  );

  // Providers
  getIt.registerFactory<ThemeProvider>(() => ThemeProvider());
  getIt.registerFactory<TransactionProvider>(
    () => TransactionProvider(getIt<FinanceRepository>()),
  );
}
