import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/app_database.dart';
import '../../providers/transaction_provider.dart';

class ExpenseBarChart extends StatelessWidget {
  final List<Transaction> transactions;

  const ExpenseBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();

    // ✅ Only expenses
    final expenses = transactions.where((t) => t.type == 'expense').toList();

    // ✅ Group by category in BASE currency
    final Map<String, double> byCategory = {};
    for (final t in expenses) {
      final amountBase = p.convertToBase(t.amount, t.currency);
      byCategory[t.category] = (byCategory[t.category] ?? 0) + amountBase;
    }

    if (byCategory.isEmpty) {
      return const Center(child: Text('No expense data'));
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = entries.first.value == 0 ? 1.0 : entries.first.value;

    return Column(
      children: entries.map((e) {
        final ratio = (e.value / maxValue).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  e.key,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: ratio, minHeight: 10),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: Text(
                  '${e.value.toStringAsFixed(0)} ${p.baseCurrency}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
