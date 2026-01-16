import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();
  RealColumn get amount => real()();

  /// Currency code for this transaction (EUR, USD, PLN, ...)
  TextColumn get currency => text().withDefault(const Constant('EUR'))();

  /// income / expense
  TextColumn get type => text()();

  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
}

/// Simple key-value settings table (base currency, etc.)
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Transactions, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bumped because we added `currency` + `app_settings`
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureDefaults();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.currency);
        await m.createTable(appSettings);
      }
      await _ensureDefaults();
    },
  );

  Future<void> _ensureDefaults() async {
    // Default base currency = EUR
    await into(appSettings).insertOnConflictUpdate(
      const AppSettingsCompanion(
        key: Value('base_currency'),
        value: Value('EUR'),
      ),
    );
  }

  // -------------------------
  // SETTINGS
  // -------------------------
  Future<String> getBaseCurrency() async {
    final row = await (select(
      appSettings,
    )..where((s) => s.key.equals('base_currency'))).getSingleOrNull();
    return row?.value ?? 'EUR';
  }

  Future<void> setBaseCurrency(String code) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: const Value('base_currency'),
        value: Value(code),
      ),
    );
  }

  // -------------------------
  // CRUD
  // -------------------------
  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Stream<Transaction> watchTransactionById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id))).watchSingle();
  }

  Future<int> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required String currency,
    required String type,
    required String category,
    required DateTime date,
  }) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        title: Value(title),
        amount: Value(amount),
        currency: Value(currency),
        type: Value(type),
        category: Value(category),
        date: Value(date),
      ),
    );
  }

  Future<int> deleteTransaction(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'finance_tracker.sqlite'));
    return NativeDatabase(file);
  });
}
