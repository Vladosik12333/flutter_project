import '../db/app_database.dart';
import '../db/transactions_dao.dart';
import '../models/finance_tip.dart';
import '../models/exchange_rate.dart';
import '../services/api_service.dart';

class FinanceRepository {
  final TransactionsDao dao; // ✅ DAO for CRUD
  final AppDatabase db; // ✅ DB for settings + migrations
  final ApiService apiService; // ✅ API

  FinanceRepository({
    required this.dao,
    required this.db,
    required this.apiService,
  });

  // -------------------------
  // SETTINGS
  // -------------------------
  Future<String> getBaseCurrency() => db.getBaseCurrency();
  Future<void> setBaseCurrency(String code) => db.setBaseCurrency(code);

  // -------------------------
  // DATABASE (via DAO)
  // -------------------------
  Stream<List<Transaction>> watchTransactions() => dao.watchAll();
  Stream<Transaction> watchTransactionById(int id) => dao.watchById(id);

  Future<void> addTransaction({
    required String title,
    required double amount,
    required String currency,
    required String type,
    required String category,
  }) async {
    await dao.insert(
      title: title,
      amount: amount,
      currency: currency,
      type: type,
      category: category,
    );
  }

  Future<void> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required String currency,
    required String type,
    required String category,
    required DateTime date,
  }) async {
    await dao.updateOne(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      type: type,
      category: category,
      date: date,
    );
  }

  Future<void> deleteTransaction(int id) async {
    await dao.deleteOne(id);
  }

  // -------------------------
  // API
  // -------------------------
  Future<List<FinanceTip>> getFinanceTips() async {
    final raw = await apiService.fetchFinanceTips();
    return raw.take(6).map((json) => FinanceTip.fromJson(json)).toList();
  }

  Future<ExchangeRates> getExchangeRates({String base = 'EUR'}) async {
    final json = await apiService.fetchExchangeRates(base: base);
    return ExchangeRates.fromJson(json);
  }
}
