import 'package:drift/drift.dart';

import 'app_database.dart';

class TransactionsDao {
  final AppDatabase db;
  TransactionsDao(this.db);

  // -------------------------
  // CREATE
  // -------------------------
  Future<int> insert({
    required String title,
    required double amount,
    required String currency,
    required String type,
    required String category,
    DateTime? date,
  }) {
    return db.insertTransaction(
      TransactionsCompanion(
        title: Value(title),
        amount: Value(amount),
        currency: Value(currency),
        type: Value(type),
        category: Value(category),
        date: Value(date ?? DateTime.now()),
      ),
    );
  }

  // -------------------------
  // READ
  // -------------------------
  Stream<List<Transaction>> watchAll() => db.watchAllTransactions();
  Stream<Transaction> watchById(int id) => db.watchTransactionById(id);

  // -------------------------
  // UPDATE
  // -------------------------
  Future<int> updateOne({
    required int id,
    required String title,
    required double amount,
    required String currency,
    required String type,
    required String category,
    required DateTime date,
  }) {
    return db.updateTransaction(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      type: type,
      category: category,
      date: date,
    );
  }

  // -------------------------
  // DELETE
  // -------------------------
  Future<int> deleteOne(int id) => db.deleteTransaction(id);
}
