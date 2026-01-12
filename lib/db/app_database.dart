import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Drift table for transactions
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // income / expense
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
}

@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // -------------------------
  // CREATE
  // -------------------------
  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  // -------------------------
  // READ (ALL)
  // -------------------------
  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  // -------------------------
  // READ (SINGLE)
  // -------------------------
  Stream<Transaction> watchTransactionById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id))).watchSingle();
  }

  // -------------------------
  // UPDATE
  // -------------------------
  Future<int> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required String type,
    required String category,
    required DateTime date,
  }) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        title: Value(title),
        amount: Value(amount),
        type: Value(type),
        category: Value(category),
        date: Value(date),
      ),
    );
  }

  // -------------------------
  // DELETE
  // -------------------------
  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

// -------------------------
// DATABASE CONNECTION
// -------------------------
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'finance_tracker.sqlite'));
    return NativeDatabase(file);
  });
}
