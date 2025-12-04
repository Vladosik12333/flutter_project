import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../db/app_database.dart';
import '../../providers/transaction_provider.dart';
import '../../repositories/finance_repository.dart';
import '../../widgets/charts/expense_bar_chart.dart';
import '../../core/di.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final repo = getIt<FinanceRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Finance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tips_and_updates),
            onPressed: () {
              // later: show finance tips from API
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('transactionNew'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary cards (using provider)
            Row(
              children: [
                _summary('Income', txProvider.totalIncome, Colors.green),
                _summary('Expenses', txProvider.totalExpense, Colors.red),
                _summary('Balance', txProvider.balance, Colors.teal),
              ],
            ),
            const SizedBox(height: 16),

            // Chart widget
            ExpenseBarChart(transactions: txProvider.transactions),

            const SizedBox(height: 16),

            // List connected directly to Drift stream (StreamBuilder requirement)
            Expanded(
              child: StreamBuilder<List<Transaction>>(
                stream: repo.watchTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final txs = snapshot.data ?? [];
                  if (txs.isEmpty) {
                    return const Center(
                      child: Text('No transactions yet. Tap + to add one.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: txs.length,
                    itemBuilder: (context, index) {
                      final t = txs[index];
                      final isIncome = t.type == 'income';
                      return ListTile(
                        onTap: () => context.pushNamed(
                          'transactionDetail',
                          pathParameters: {'id': t.id.toString()},
                        ),
                        leading: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text(t.title),
                        subtitle: Text('${t.category} • ${t.date.toLocal()}'),
                        trailing: Text(
                          (isIncome ? '+ ' : '- ') +
                              t.amount.toStringAsFixed(2),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(String label, double value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(label),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
