import 'package:flutter/foundation.dart';
import '../db/app_database.dart';
import '../repositories/finance_repository.dart';
import '../models/finance_tip.dart';
import '../models/exchange_rate.dart';

enum TransactionViewState { loading, data, error }

enum TxFilter { all, today, week, month }

class TransactionProvider extends ChangeNotifier {
  final FinanceRepository _repo;

  // -------------------------
  // EXCHANGE RATES STATE (API)
  // -------------------------
  ExchangeRates? exchangeRates;
  bool ratesLoading = false;
  String? ratesError;
  String ratesBase = 'EUR';

  TxFilter filter = TxFilter.all;

  void setFilter(TxFilter f) {
    filter = f;
    notifyListeners();
  }

  List<Transaction> get filteredTransactions {
    final now = DateTime.now();
    DateTime start;

    switch (filter) {
      case TxFilter.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TxFilter.week:
        final weekday = now.weekday; // 1..7
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        break;
      case TxFilter.month:
        start = DateTime(now.year, now.month, 1);
        break;
      case TxFilter.all:
      default:
        return transactions;
    }

    return transactions.where((t) => t.date.isAfter(start)).toList();
  }

  Future<void> loadExchangeRates({String base = 'EUR'}) async {
    ratesBase = base;
    ratesLoading = true;
    ratesError = null;
    notifyListeners();

    try {
      exchangeRates = await _repo.getExchangeRates(base: base);
    } catch (e) {
      ratesError = e.toString();
    }

    ratesLoading = false;
    notifyListeners();
  }

  // -------------------------
  // UI STATE
  // -------------------------
  TransactionViewState state = TransactionViewState.loading;
  String? errorMessage;

  // -------------------------
  // DATABASE STATE
  // -------------------------
  List<Transaction> transactions = [];

  // -------------------------
  // API STATE
  // -------------------------
  List<FinanceTip> financeTips = [];
  bool tipsLoading = false;
  String? tipsError;

  TransactionProvider(this._repo) {
    _listenToTransactions();
    loadFinanceTips(); // ✅ AUTO LOAD API
  }

  // -------------------------
  // DATABASE LISTENER
  // -------------------------
  void _listenToTransactions() {
    state = TransactionViewState.loading;
    notifyListeners();

    _repo.watchTransactions().listen(
      (txs) {
        transactions = txs;
        state = TransactionViewState.data;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        state = TransactionViewState.error;
        notifyListeners();
      },
    );
  }

  // -------------------------
  // DATABASE ACTIONS
  // -------------------------
  Future<void> addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
  }) async {
    await _repo.addTransaction(
      title: title,
      amount: amount,
      type: isIncome ? 'income' : 'expense',
      category: category,
    );
  }

  Future<void> deleteById(int id) async {
    await _repo.deleteTransaction(id);
  }

  Future<void> editTransaction({
    required int id,
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    DateTime? date,
  }) async {
    await _repo.updateTransaction(
      id: id,
      title: title,
      amount: amount,
      type: isIncome ? 'income' : 'expense',
      category: category,
      date: date ?? DateTime.now(),
    );
  }

  // -------------------------
  // CALCULATIONS
  // -------------------------
  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  // -------------------------
  // API
  // -------------------------
  Future<void> loadFinanceTips() async {
    tipsLoading = true;
    tipsError = null;
    financeTips = []; // ✅ clear old tips so UI refreshes
    notifyListeners();

    try {
      financeTips = await _repo.getFinanceTips();
    } catch (e) {
      tipsError = e.toString();
    }

    tipsLoading = false;
    notifyListeners();
  }
}
