import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../db/app_database.dart';
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

  // Repository
  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepository(
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
