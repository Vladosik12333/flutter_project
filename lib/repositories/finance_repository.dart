import '../db/app_database.dart';
import '../models/finance_tip.dart';
import '../models/exchange_rate.dart';
import '../services/api_service.dart';

/// Repository that combines local database (Drift)
/// and remote API (Dio)
class FinanceRepository {
  final AppDatabase db;
  final ApiService apiService;

  FinanceRepository({required this.db, required this.apiService});

  // -------------------------
  // DATABASE
  // -------------------------

  Stream<List<Transaction>> watchTransactions() {
    return db.watchAllTransactions();
  }

  Stream<Transaction> watchTransactionById(int id) {
    return db.watchTransactionById(id);
  }

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

  Future<void> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required String type,
    required String category,
    required DateTime date,
  }) async {
    await db.updateTransaction(
      id: id,
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date,
    );
  }

  Future<void> deleteTransaction(int id) async {
    await db.deleteTransaction(id);
  }

  // -------------------------
  // API - Finance Tips (Quotable)
  // -------------------------
  Future<List<FinanceTip>> getFinanceTips() async {
    final raw = await apiService.fetchFinanceTips();
    // Already limited in ApiService (limit: 6), but keep safe:
    return raw.take(6).map((json) => FinanceTip.fromJson(json)).toList();
  }

  // -------------------------
  // API - Exchange Rates (Frankfurter)
  // -------------------------
  Future<ExchangeRates> getExchangeRates({String base = 'EUR'}) async {
    final json = await apiService.fetchExchangeRates(base: base);
    return ExchangeRates.fromJson(json);
  }
}
