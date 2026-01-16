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
  // Base Currency (constant currency for app)
  // -------------------------
  String baseCurrency = 'EUR';

  // Supported currencies in UI
  final List<String> supportedCurrencies = const ['EUR', 'USD', 'PLN'];

  // -------------------------
  // FX State (API)
  // -------------------------
  ExchangeRates? exchangeRates;
  bool ratesLoading = false;
  String? ratesError;

  // -------------------------
  // UI
  // -------------------------
  TxFilter filter = TxFilter.all;

  void setFilter(TxFilter f) {
    filter = f;
    notifyListeners();
  }

  // -------------------------
  // DB state
  // -------------------------
  TransactionViewState state = TransactionViewState.loading;
  String? errorMessage;
  List<Transaction> transactions = [];

  // -------------------------
  // Tips API state
  // -------------------------
  List<FinanceTip> financeTips = [];
  bool tipsLoading = false;
  String? tipsError;

  TransactionProvider(this._repo) {
    _init();
  }

  Future<void> _init() async {
    _listenToTransactions();
    await loadBaseCurrency(); // loads base currency from DB settings
    await loadExchangeRates(base: baseCurrency);
    loadFinanceTips();
  }

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
  // SETTINGS
  // -------------------------
  Future<void> loadBaseCurrency() async {
    try {
      baseCurrency = await _repo.getBaseCurrency();
      notifyListeners();
    } catch (_) {
      baseCurrency = 'EUR';
      notifyListeners();
    }
  }

  Future<void> setBaseCurrency(String code) async {
    baseCurrency = code;
    notifyListeners();

    await _repo.setBaseCurrency(code);
    await loadExchangeRates(base: code);
  }

  // -------------------------
  // FX
  // -------------------------
  Future<void> loadExchangeRates({required String base}) async {
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

  /// Convert an amount from [fromCurrency] into [baseCurrency].
  /// Frankfurter API returns rates like: 1 BASE = rate[X] X.
  /// So X -> BASE = amount / rate[X].
  double convertToBase(double amount, String fromCurrency) {
    if (fromCurrency == baseCurrency) return amount;
    final rates = exchangeRates?.rates ?? {};
    final rate = rates[fromCurrency];
    if (rate == null || rate == 0) return amount; // fallback if missing
    return amount / rate;
  }

  // -------------------------
  // FILTER
  // -------------------------
  List<Transaction> get filteredTransactions {
    final now = DateTime.now();
    DateTime start;

    switch (filter) {
      case TxFilter.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TxFilter.week:
        final weekday = now.weekday;
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

  // -------------------------
  // CRUD
  // -------------------------
  Future<void> addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    required String currency,
  }) async {
    await _repo.addTransaction(
      title: title,
      amount: amount,
      currency: currency,
      type: isIncome ? 'income' : 'expense',
      category: category,
    );
  }

  Future<void> editTransaction({
    required int id,
    required String title,
    required double amount,
    required bool isIncome,
    required String category,
    required String currency,
    DateTime? date,
  }) async {
    await _repo.updateTransaction(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      type: isIncome ? 'income' : 'expense',
      category: category,
      date: date ?? DateTime.now(),
    );
  }

  Future<void> deleteById(int id) async {
    await _repo.deleteTransaction(id);
  }

  DateTime _monthStart(DateTime now) => DateTime(now.year, now.month, 1);

  List<Transaction> get thisMonthTransactions {
    final now = DateTime.now();
    final start = _monthStart(now);
    return transactions.where((t) => !t.date.isBefore(start)).toList();
  }

  double get monthIncome => thisMonthTransactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + convertToBase(t.amount, t.currency));

  double get monthExpense => thisMonthTransactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + convertToBase(t.amount, t.currency));

  double get monthBalance => monthIncome - monthExpense;

  // -------------------------
  // KPI (in BASE currency)
  // -------------------------
  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + convertToBase(t.amount, t.currency));

  double get totalExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + convertToBase(t.amount, t.currency));

  double get balance => totalIncome - totalExpense;

  Stream<Transaction> watchTransactionById(int id) {
    return _repo.watchTransactionById(id);
  }

  // -------------------------
  // API tips
  // -------------------------
  Future<void> loadFinanceTips() async {
    tipsLoading = true;
    tipsError = null;
    financeTips = [];
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
