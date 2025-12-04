import 'package:flutter/foundation.dart';
import '../db/app_database.dart';
import '../repositories/finance_repository.dart';

enum TransactionViewState { loading, data, error }

class TransactionProvider extends ChangeNotifier {
  final FinanceRepository _repo;

  TransactionViewState state = TransactionViewState.loading;
  String? errorMessage;

  // List of transactions for non-StreamBuilder UI (filters, charts)
  List<Transaction> transactions = [];

  TransactionProvider(this._repo) {
    _listenToTransactions();
  }

  void _listenToTransactions() {
    state = TransactionViewState.loading;
    notifyListeners();

    _repo.watchTransactions().listen((txs) {
      transactions = txs;
      state = TransactionViewState.data;
      notifyListeners();
    }, onError: (e) {
      errorMessage = e.toString();
      state = TransactionViewState.error;
      notifyListeners();
    });
  }

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

  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpense;
}
