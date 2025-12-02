import 'package:drift/drift.dart';
import '../db/app_database.dart';
import '../services/api_service.dart';

class FinanceRepository {
  final AppDatabase db;
  final ApiService apiService;

  FinanceRepository({required this.db, required this.apiService});

  // DB methods
  Stream<List<Transaction>> watchTransactions() => db.watchAllTransactions();

  Future<void> addTransaction({
    required String title,
    required double amount,
    required String type,
    required String category,
  }) async {
    await db.insertTransaction(
      TransactionsCompanion.insert(
        title: title,
        amount: amount,
        type: type,
        category: category,
        date: DateTime.now(),
      ),
    );
  }

  Future<void> deleteTransaction(int id) => db.deleteTransaction(id);

  // API methods
  Future<List<String>> fetchFinanceTips() async {
    try {
      final data = await apiService.fetchFinanceTips();
      // Map raw JSON -> list of strings
      return data.take(5).map((e) => (e['title'] ?? '').toString()).toList();
    } catch (e) {
      rethrow;
    }
  }
}
