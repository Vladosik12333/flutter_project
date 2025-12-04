import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../db/app_database.dart';
import '../repositories/finance_repository.dart';
import '../services/api_service.dart';

final getIt = GetIt.instance;

Future<void> setupDI() async {
  // Dio
  getIt.registerLazySingleton<Dio>(() => Dio(
        BaseOptions(
          baseUrl: 'https://jsonplaceholder.typicode.com', // or your API
          connectTimeout: const Duration(seconds: 5),
        ),
      ));

  // API service
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(getIt<Dio>()),
  );

  // Drift DB
  final db = AppDatabase();
  getIt.registerLazySingleton<AppDatabase>(() => db);

  // Repository
  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepository(
      db: getIt<AppDatabase>(),
      apiService: getIt<ApiService>(),
    ),
  );
}
